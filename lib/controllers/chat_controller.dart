import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../models/schemas.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';

class ChatController extends ChangeNotifier {
  // State
  List<ChatMessage> messages = [];
  bool isStreaming = false;
  String currentStreamBuffer = '';
  String loadingStatus = '';
  bool isLoadingHistory = true;
  bool isCheckingErrors = false;
  
  // STT State
  final SpeechToText _speechToText = SpeechToText();
  bool sttAvailable = false;
  bool isListening = false;
  bool isSttSupported = true;
  String? currentLocaleId;
  String initialTextBeforeStt = '';

  // TTS State
  // TTS State
  TtsService? _ttsService;
  bool get isSpeaking => _ttsService?.isSpeaking ?? false;

  // Controllers
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // Throttle & Debounce
  Timer? _updateThrottleTimer;
  bool _hasPendingUpdate = false;
  static const _updateThrottleDuration = Duration(milliseconds: 50);
  Timer? _scrollDebounceTimer;

  // Analysis State
  int _lastAnalyzedMessageCount = 0;
  bool _enableAutoErrorCheckOnExit = false;

  @override
  void dispose() {
    _updateThrottleTimer?.cancel();
    _scrollDebounceTimer?.cancel();
    textController.dispose();
    scrollController.dispose();
    _speechToText.cancel();
    _speechToText.cancel();
    _ttsService?.stop();
    super.dispose();
  }

  // --- STT Methods ---

  Future<void> initSpeech() async {
    if (kIsWeb || Platform.isWindows) {
      isSttSupported = false;
      notifyListeners();
      return;
    }
    
    sttAvailable = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'notListening') {
          isListening = false;
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint('STT Error: $error');
        isListening = false;
        notifyListeners();
      },
    );

    if (sttAvailable) {
      var locales = await _speechToText.locales();
      currentLocaleId = locales.firstWhere(
        (locale) => locale.localeId.startsWith('en'),
        orElse: () => locales.first,
      ).localeId;
    }

    // TTS Init handled by TtsService

    notifyListeners();
  }

  Future<void> startListening() async {
    if (!sttAvailable || !isSttSupported) return;
    
    initialTextBeforeStt = textController.text;
    isListening = true;
    notifyListeners();

    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        textController.text = '$initialTextBeforeStt ${result.recognizedWords}'.trim();
        // We notify listeners here if we want the UI (like a specialized input) to react,
        // but textController handles the text field update automatically.
        // However, if we have other UI dependent on text length, we might need to notify.
      },
      localeId: currentLocaleId,
      listenOptions: SpeechListenOptions(cancelOnError: true),
    );
  }

  Future<void> stopListening() async {
    if (!sttAvailable) return;
    await _speechToText.stop();
    isListening = false;
    notifyListeners();
  }

  // --- TTS Methods ---

  void setTtsService(TtsService service) {
    _ttsService = service;
    _ttsService!.addListener(notifyListeners);
  }

  @override
  void removeListener(VoidCallback listener) {
    _ttsService?.removeListener(notifyListeners); // Clean up
    super.removeListener(listener);
  }

  Future<void> speak(String text) async {
    await _ttsService?.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _ttsService?.stop();
  }

  // --- Chat Methods ---

  void setMessages(List<ChatMessage> newMessages) {
    messages = newMessages;
    notifyListeners();
    _scheduleScrollToBottom();
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  void _scheduleScrollToBottom() {
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      scrollToBottom();
    });
  }

  void sendMessage({
    required String message,
    required Stream<Map<String, dynamic>> Function(String msg) sendApiCall, 
    String Function(String status)? statusMessageBuilder,
    void Function(List<dynamic> toolCalls)? onToolCalls,
    bool enableAutoErrorCheckOnExit = false,
  }) {
    if (enableAutoErrorCheckOnExit) {
      _enableAutoErrorCheckOnExit = true;
    }
    if (message.isEmpty || isStreaming) return;

    textController.clear();
    messages.add(ChatMessage(role: 'user', content: message));
    isStreaming = true;
    currentStreamBuffer = '';
    loadingStatus = 'Connecting...';
    notifyListeners();
    
    _scheduleScrollToBottom();

    sendApiCall(message).listen(
      (event) {
        if (event['type'] == 'status') {
           final statusContent = event['content'];
           if (statusMessageBuilder != null) {
             loadingStatus = statusMessageBuilder(statusContent);
           } else {
             loadingStatus = statusContent == 'queued'
                ? 'Waiting in Queue...'
                : 'Processing...';
           }
           notifyListeners();
        }
        else if (event['type'] == 'chunk') {
          loadingStatus = 'Typing...';
          final chunk = event['content'];
          currentStreamBuffer += chunk;
          
          if (_ttsService != null) {
            _ttsService!.processStreamChunk(chunk);
          }
          
          _hasPendingUpdate = true;
          _updateThrottleTimer ??= Timer.periodic(_updateThrottleDuration, (_) {
            if (_hasPendingUpdate) {
              _hasPendingUpdate = false;
              notifyListeners();
              _scheduleScrollToBottom();
            }
          });
        }
        else if (event['type'] == 'tool_calls') {
          if (onToolCalls != null) {
            onToolCalls(event['content'] as List<dynamic>);
          }
        }
      },
      onError: (e) {
        _cancelThrottleTimer();
        isStreaming = false;
        loadingStatus = 'Error: $e'; // Optionally show in UI state
        notifyListeners();
      },
      onDone: () {
        _cancelThrottleTimer();
        if (currentStreamBuffer.isNotEmpty) {
          messages.add(ChatMessage(
              role: 'assistant', content: currentStreamBuffer));
              
           // Flush remaining TTS
           _ttsService?.flushStream();
        }
        currentStreamBuffer = '';
        loadingStatus = '';
        isStreaming = false;
        notifyListeners();
        _scheduleScrollToBottom();
      },
    );
  }

  void _cancelThrottleTimer() {
    _updateThrottleTimer?.cancel();
    _updateThrottleTimer = null;
    _hasPendingUpdate = false;
  }

  /// Fire-and-forget error check on exit
  /// This requires the ApiService to be passed, or a callback to check errors
  void triggerExitErrorCheck(Future<dynamic> Function(String text) checkErrorsApiCall) {
    if (!_enableAutoErrorCheckOnExit) return;

    final userMessages = messages.where((m) => m.role == 'user').toList();
    
    // Check if we have enough new messages (e.g. 10) or just ANY new messages?
    // Original code checked for 10 new messages.
    final newMessagesCount = userMessages.length - _lastAnalyzedMessageCount;
    if (newMessagesCount < 10) return;
    
    final newMessagesText = userMessages.skip(_lastAnalyzedMessageCount).map((m) => m.content).join('\n\n');
    
    if (newMessagesText.isEmpty) return;
    
    try {
      // Fire and forget
      checkErrorsApiCall(newMessagesText).then((_) {
        debugPrint('✅ Exit error check completed');
      }).catchError((e) {
        debugPrint('🔴 Exit error check failed (non-blocking): $e');
      });
      
      _lastAnalyzedMessageCount = userMessages.length;
    } catch (e) {
      debugPrint('🔴 Exit error check setup failed: $e');
    }
  }

  void updateLastAnalyzedCount() {
    _lastAnalyzedMessageCount = messages.where((m) => m.role == 'user').length;
  }

  Future<void> fetchHistory(ApiService apiService, String conversationId) async {
    try {
      isLoadingHistory = true;
      notifyListeners();
      
      final conversationDetail = await apiService.getConversation(conversationId);
      messages = conversationDetail.messages;
      isLoadingHistory = false;
      notifyListeners();
      
      _scheduleScrollToBottom();
    } catch (e) {
      debugPrint('🔴 Failed to fetch history: $e');
      isLoadingHistory = false;
      loadingStatus = 'Failed to load history'; 
      notifyListeners();
      rethrow; 
    }
  }

  Future<ErrorCheckResponse> checkErrors(ApiService apiService) async {
    isCheckingErrors = true;
    notifyListeners();
    
    final userMessages = messages.where((m) => m.role == 'user').map((m) => m.content).join('\n\n');
    
    if (userMessages.isEmpty) {
      isCheckingErrors = false;
      notifyListeners();
      throw Exception("No messages to check");
    }

    try {
      final request = ErrorCheckRequest(text: userMessages);
      final response = await apiService.checkErrors(request);
      updateLastAnalyzedCount();
      return response;
    } finally {
      isCheckingErrors = false;
      notifyListeners();
    }
  }
}
