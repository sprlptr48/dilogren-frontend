import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../models/schemas.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

abstract class BaseChatScreen extends StatefulWidget {
  const BaseChatScreen({super.key});
}

abstract class BaseChatScreenState<T extends BaseChatScreen> extends State<T> with SingleTickerProviderStateMixin {
  final textController = TextEditingController();
  final scrollController = ScrollController();
  final SpeechToText speechToText = SpeechToText();

  late List<ChatMessage> messages;
  bool isLoadingHistory = true;
  bool isStreaming = false;
  String currentStreamBuffer = '';
  String loadingStatus = '';
  bool isCheckingErrors = false;
  bool sttAvailable = false;
  bool isListening = false;
  bool isSttSupported = true;
  String? currentLocaleId;
  
  // Track analyzed messages to avoid re-analyzing
  int _lastAnalyzedMessageCount = 0;
  bool _enableAutoErrorCheckOnExit = false;
  String initialTextBeforeStt = '';

  // Performance: Throttle UI updates during streaming
  Timer? _updateThrottleTimer;
  bool _hasPendingUpdate = false;
  static const _updateThrottleDuration = Duration(milliseconds: 50);

  late AnimationController micAnimationController;
  late Animation<double> micAnimation;

  @override
  void initState() {
    super.initState();
    messages = getInitialMessages();
    if (shouldFetchHistory()) {
      fetchConversationHistory();
    } else {
      isLoadingHistory = false;
    }
    initSpeech();

    micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    micAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: micAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    // Fire-and-forget error check on exit if enabled and enough new messages
    if (_enableAutoErrorCheckOnExit) {
      final userMessageCount = messages.where((m) => m.role == 'user').length;
      final newMessagesCount = userMessageCount - _lastAnalyzedMessageCount;
      if (newMessagesCount >= 10) {
        _triggerExitErrorCheck();
      }
    }
    
    _updateThrottleTimer?.cancel();
    _scrollDebounceTimer?.cancel();
    textController.dispose();
    scrollController.dispose();
    speechToText.cancel();
    micAnimationController.dispose();
    super.dispose();
  }

  void initSpeech() async {
    if (Platform.isWindows) {
      if (mounted) setState(() => isSttSupported = false);
      return;
    }
    sttAvailable = await speechToText.initialize(
      onStatus: (status) {
        if (status == 'notListening') {
          setState(() {
            isListening = false;
            micAnimationController.stop();
            micAnimationController.reset();
          });
        }
      },
      onError: (error) {
        print('STT Error: $error');
        setState(() {
          isListening = false;
          micAnimationController.stop();
          micAnimationController.reset();
        });
      },
    );
    if (sttAvailable) {
      var locales = await speechToText.locales();
      currentLocaleId = locales.firstWhere(
        (locale) => locale.localeId.startsWith('en'),
        orElse: () => locales.first,
      ).localeId;
    }
    if (mounted) setState(() {});
  }

  void startListening() async {
    if (!sttAvailable || !isSttSupported) return;
    initialTextBeforeStt = textController.text;
    setState(() => isListening = true);
    micAnimationController.repeat(reverse: true);
    await speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        setState(() {
          textController.text = '$initialTextBeforeStt ${result.recognizedWords}'.trim();
        });
      },
      localeId: currentLocaleId,
      cancelOnError: true,
    );
  }

  void stopListening() async {
    if (!sttAvailable) return;
    await speechToText.stop();
    setState(() {
      isListening = false;
      micAnimationController.stop();
      micAnimationController.reset();
    });
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Handle level change suggestion from error check
  Future<void> handleLevelChangeSuggestion(ErrorCheckResponse response) async {
    if (response.levelChanged == true &&
        response.currentLevel != null &&
        response.suggestedLevel != null) {

      final shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green),
              SizedBox(width: 8),
              Text('Level Up!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Based on your writing, we think you\'re now ${response.suggestedLevel}!',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Would you like to update your level from ${response.currentLevel} to ${response.suggestedLevel}?',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Future sessions will use ${response.suggestedLevel} difficulty',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Keep ${response.currentLevel}'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text('Update to ${response.suggestedLevel}'),
            ),
          ],
        ),
      );

      if (shouldUpdate == true && mounted) {
        try {
          final apiService = Provider.of<ApiService>(context, listen: false);
          final authService = Provider.of<AuthService>(context, listen: false);

          final updatedProfile = await apiService.updateLevel(response.suggestedLevel!);
          authService.updateUser(updatedProfile);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Level updated to ${response.suggestedLevel}!'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'Great!',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update level: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  // --- Shared Logic ---

  Future<void> fetchBaseConversationHistory(String conversationId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final conversationDetail = await apiService.getConversation(conversationId);
      if (mounted) {
        setState(() {
          messages = conversationDetail.messages;
          isLoadingHistory = false;
        });
        scrollToBottom();
      }
    } catch (e) {
      print('🔴 Failed to fetch history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: ${e.toString()}')),
        );
        setState(() {
          isLoadingHistory = false;
        });
      }
    }
  }

  void sendBaseMessage({
  required String message,
  required Stream<Map<String, dynamic>> Function(String msg) sendApiCall, 
  String Function(String status)? statusMessageBuilder,
  void Function(List<dynamic> toolCalls)? onToolCalls,
  bool enableAutoErrorCheckOnExit = false,
}) {
  // Enable auto error check on exit if requested
  if (enableAutoErrorCheckOnExit) {
    _enableAutoErrorCheckOnExit = true;
  }
  if (message.isEmpty || isStreaming) return;

  textController.clear();

  setState(() {
    messages.add(ChatMessage(role: 'user', content: message));
    isStreaming = true;
    currentStreamBuffer = '';
    loadingStatus = 'Connecting...';
  });

  scrollToBottom();

  sendApiCall(message).listen(
    (event) {
      if (!mounted) return;
      
      // Update state without triggering rebuild immediately
      if (event['type'] == 'status') {
         final statusContent = event['content'];
         if (statusMessageBuilder != null) {
           loadingStatus = statusMessageBuilder(statusContent);
         } else {
           loadingStatus = statusContent == 'queued'
              ? 'Waiting in Queue...'
              : 'Processing...';
         }
         // Status changes are important - update immediately
         setState(() {});
      }
      else if (event['type'] == 'chunk') {
        loadingStatus = 'Typing...';
        currentStreamBuffer += event['content'];
        
        // Throttle chunk updates: mark that we need an update
        _hasPendingUpdate = true;
        _updateThrottleTimer ??= Timer.periodic(_updateThrottleDuration, (_) {
          if (_hasPendingUpdate && mounted) {
            _hasPendingUpdate = false;
            setState(() {});
            _scheduleScrollToBottom();
          }
        });
      }
      else if (event['type'] == 'tool_calls') {
        // Handle navigation tool calls from adaptive chat
        if (onToolCalls != null) {
          onToolCalls(event['content'] as List<dynamic>);
        }
      }

    },
    onError: (e) {
      _cancelThrottleTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() => isStreaming = false);
    },
    onDone: () {
      _cancelThrottleTimer();
      if (!mounted) return;
      setState(() {
        if (currentStreamBuffer.isNotEmpty) {
          messages.add(ChatMessage(
              role: 'assistant', content: currentStreamBuffer));
        }
        currentStreamBuffer = '';
        loadingStatus = '';
        isStreaming = false;
      });
      scrollToBottom();
    },
  );
}

  void _cancelThrottleTimer() {
    _updateThrottleTimer?.cancel();
    _updateThrottleTimer = null;
    _hasPendingUpdate = false;
  }

  // Debounced scroll to avoid excessive scrolling during streaming
  Timer? _scrollDebounceTimer;
  void _scheduleScrollToBottom() {
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      scrollToBottom();
    });
  }

  /// Fire-and-forget error check on exit - only analyzes NEW messages
  /// This runs when user leaves the chat, doesn't block, and we don't care about response
  void _triggerExitErrorCheck() {
    // Get only the messages that haven't been analyzed yet
    final userMessages = messages.where((m) => m.role == 'user').toList();
    
    if (userMessages.length <= _lastAnalyzedMessageCount) return;
    
    // Get only new messages (skip already analyzed ones)
    final newMessages = userMessages.skip(_lastAnalyzedMessageCount).map((m) => m.content).join('\n\n');
    
    if (newMessages.isEmpty) return;
    
    // Fire and forget - we don't await or care about response
    // The backend will save errors to DB which is all we need
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final request = ErrorCheckRequest(text: newMessages);
      
      // Fire and forget - don't await
      apiService.checkErrors(request).then((_) {
        print('✅ Exit error check completed');
      }).catchError((e) {
        print('🔴 Exit error check failed (non-blocking): $e');
      });
      
      // Update the count so we don't re-analyze if they come back
      _lastAnalyzedMessageCount = userMessages.length;
    } catch (e) {
      // Silent failure - user is leaving anyway
      print('🔴 Exit error check setup failed: $e');
    }
  }

  Future<void> checkAllMessagesCommon() async {
    setState(() => isCheckingErrors = true);

    final apiService = Provider.of<ApiService>(context, listen: false);
    final userMessages = messages.where((m) => m.role == 'user').map((m) => m.content).join('\n\n');

    if (userMessages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No messages to check yet!')),
      );
      setState(() => isCheckingErrors = false);
      return;
    }

    try {
      final request = ErrorCheckRequest(text: userMessages);
      final response = await apiService.checkErrors(request);

      if (mounted) {
        if (response.errorCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No errors found. Great job!'),
              backgroundColor: Colors.blue,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${response.errorCount} errors found and saved to your history.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Update the analyzed count so we don't re-analyze on exit
        _lastAnalyzedMessageCount = messages.where((m) => m.role == 'user').length;

        await handleLevelChangeSuggestion(response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking messages: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isCheckingErrors = false);
      }
    }
  }

  // Abstract methods to be implemented by subclasses
  List<ChatMessage> getInitialMessages();
  bool shouldFetchHistory();
  Future<void> fetchConversationHistory();
  void sendMessage();
  String getTitle();
  String? getSubtitle();
  List<Widget> getAppBarActions();
  Widget? buildHeaderWidget();
  String getInputHint();

  @override
  Widget build(BuildContext context) {
    // Cache header widget to avoid calling twice
    final headerWidget = buildHeaderWidget();
    
    return Scaffold(
      appBar: AppBar(
        title: getSubtitle() != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(getTitle(), style: const TextStyle(fontSize: 16)),
                  Text(
                    getSubtitle()!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              )
            : Text(getTitle()),
        actions: getAppBarActions(),
      ),
      body: Column(
        children: [
          if (headerWidget != null) headerWidget,
          Expanded(
            child: isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (isStreaming ? 1 : 0),
                    // Performance optimizations
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    itemBuilder: (context, index) {
                      if (isStreaming && index == messages.length) {
                        return buildMessageBubble(
                          role: 'assistant',
                          content: currentStreamBuffer,
                          isStreaming: true,
                        );
                      }
                      final msg = messages[index];
                      return buildMessageBubble(role: msg.role, content: msg.content);
                    },
                  ),
          ),
          buildInputArea(),
        ],
      ),
    );
  }

  Widget buildMessageBubble({required String role, required String content, bool isStreaming = false}) {
    final isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isUser ? Radius.zero : null,
            topLeft: !isUser ? Radius.zero : null,
          ),
          boxShadow: [
            if (!isUser)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (content.isNotEmpty)
              Text(
                content,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            if (isStreaming)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator(strokeWidth: 2)
                    ),
                    const SizedBox(width: 8),
                    if (content.isEmpty)
                      Text(
                        loadingStatus,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic
                        ),
                      ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ScaleTransition(
            scale: micAnimation,
            child: IconButton(
              icon: Icon(isListening ? Icons.mic_off : Icons.mic),
              color: isListening ? Colors.red : Theme.of(context).primaryColor,
              onPressed: (sttAvailable && isSttSupported) ? (isListening ? stopListening : startListening) : null,
              tooltip: isSttSupported ? 'Use voice input' : 'Voice input not available on this platform',
            ),
          ),
          Expanded(
            child: Tooltip(
              message: isListening ? 'Voice input is active' : '',
              child: TextField(
                controller: textController,
                enabled: !isListening,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: isListening ? 'Listening...' : getInputHint(),
                  filled: true,
                  fillColor: isListening ? Colors.grey.shade200 : const Color(0xFFF8F9FE),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onSubmitted: (_) => sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: (isStreaming || isListening) ? null : sendMessage,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
