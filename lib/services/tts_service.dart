import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TtsService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  
  // Constants
  static const double _defaultRate = 0.6;
  static const double _defaultPitch = 1.0;
  static const Map<String, String> _voiceA = {"name": "en-gb-x-gba-network", "locale": "en-GB"};
  static const Map<String, String> _voiceB = {"name": "en-gb-x-gbb-network", "locale": "en-GB"};

  static final RegExp _cleanRegex = RegExp(
    r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])' // Emoji
    r'|(\*\*|__)' // Bold
    r'|(\*|_)'    // Italic
    r'|(`+)'      // Code (Backticks)
    r'|(/)'       // Slash
    r'|(\+)'      // Group 6: Plus
    r'|(###|##|#)' // Group 7: Header/Hash - Removed
    r'|((?:\s-\s)|(?:-{2,}))' // Group 8: Dash (Space-Hyphen-Space OR 2+ dashes)
    r'|([()\[\]<>{}（）])', // Group 9: All Brackets/Parens (Normal & Fullwidth)
  );

  // Settings
  bool autoPlay = false;
  bool useVoiceB = false; // False = Voice A (Female), True = Voice B (Male)

  // Initialization State
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;



  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _flutterTts.stop();
    super.dispose();
  }

  // Stream Buffer state
  // Stream Buffer state
  String _streamBuffer = '';
  // Match: ... OR [:!?。] OR . followed by whitespace/newline/* OR ### OR <> OR " - " OR "--"
  static final RegExp _sentenceEndRegex = RegExp(r'(?:\.\.\.|[:!?。]|\.(?=[\s\*\n])|###|#|##|<>| - |--)');


  TtsService() {
    _init();
  }

  Future<void> _init() async {
    if (kIsWeb) return; // Web support limited for now

    try {
      if (Platform.isIOS) {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [
              IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
              IosTextToSpeechAudioCategoryOptions.duckOthers
            ],
            IosTextToSpeechAudioMode.defaultMode);
      }
      
      // Load saved settings
      await _loadSettings();

      // Fix for "I'll" -> "İüll" issues: 
      // Explicitly set language to en-GB to prevent device locale (Turkish) text normalization quirks
      await _flutterTts.setLanguage("en-GB");
      
      // Ensure we do NOT wait for completion, allowing rapid queueing
      await _flutterTts.awaitSpeakCompletion(false);
      
      // Enable native queueing (Add to queue instead of flushing)
      try {
        await _flutterTts.setQueueMode(1);
      } catch (e) {
        debugPrint("Queue Mode Error: $e");
      }

      await _applySettings();

      // Handlers
      _flutterTts.setStartHandler(() {
        if (_disposed) return;
        _isSpeaking = true;
        notifyListeners();
      });

      _flutterTts.setCompletionHandler(() {
        if (_disposed) return;
        _isSpeaking = false;
        notifyListeners();
      });

      _flutterTts.setCancelHandler(() {
        if (_disposed) return;
        _isSpeaking = false;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((msg) {
        if (_disposed) return;
        debugPrint("TTS Error: $msg");
        _isSpeaking = false;
        notifyListeners();
      });

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint("TTS Init Error: $e");
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    autoPlay = prefs.getBool('tts_auto_play') ?? false;
    useVoiceB = prefs.getBool('tts_use_voice_b') ?? false;
  }

  Future<void> updateSettings({
    bool? newAutoPlay,
    bool? newUseVoiceB,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (newAutoPlay != null) {
      autoPlay = newAutoPlay;
      await prefs.setBool('tts_auto_play', autoPlay);
    }
    
    if (newUseVoiceB != null) {
      useVoiceB = newUseVoiceB;
      await prefs.setBool('tts_use_voice_b', useVoiceB);
    }
    
    await _applySettings();
    notifyListeners();
  }

  Future<void> _applySettings() async {
    await _flutterTts.setLanguage("en-GB"); // Ensure language is enforced
    await _flutterTts.setSpeechRate(_defaultRate);
    await _flutterTts.setPitch(_defaultPitch);
    await _flutterTts.setVolume(1.0);
    
    final voice = useVoiceB ? _voiceB : _voiceA;
    try {
      await _flutterTts.setVoice(voice);
    } catch (e) {
      debugPrint("Error setting voice: $e");
    }
  }

  String _cleanText(String text) {
    if (text.isEmpty) return text;
    // Single pass replacement/removal for performance
    // Single pass replacement/removal for performance
    return text.replaceAllMapped(_cleanRegex, (match) {
      if (match.group(5) != null) return ' or ';   // Slash (Group 5)
      if (match.group(6) != null) return ' plus '; // Plus (Group 6)
      if (match.group(8) != null) return ', ';     // Dash -> Comma pause (Group 8)
      // Remove Groups: 
      // 1 (Emoji), 2 (Bold), 3 (Italic), 4 (Backticks), 
      // 7 (Hashes), 9 (Brackets)
      return ''; 
    });
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    final clean = _cleanText(text);
    if (clean.trim().isEmpty) return;

    // Use native queueing (setQueueMode(1))
    try {
      await _flutterTts.speak(clean); 
    } catch (e) {
      debugPrint("Speak Error: $e");
    }
  }

  Future<void> stop() async {
    try {
      _chunkQueue.clear();
      await _flutterTts.stop();
      _streamBuffer = '';
    } catch (e) {
      debugPrint("Stop Error: $e");
    }
  }

  // Queue for incoming stream chunks
  final List<String> _chunkQueue = [];
  bool _isProcessingChunks = false;

  // Streaming Support
  void resetStream() {
    stop(); 
  }

  Future<void> processStreamChunk(String chunk) async {
    if (!autoPlay) return;
    _chunkQueue.add(chunk);
    if (!_isProcessingChunks) {
      _processChunkQueue();
    }
  }

  Future<void> _processChunkQueue() async {
    if (_isProcessingChunks) return;
    _isProcessingChunks = true;

    try {
      while (true) {
        // 1. Drain current queue to buffer
        while (_chunkQueue.isNotEmpty) {
          _streamBuffer += _chunkQueue.removeAt(0);
        }

        // 2. Check for sentence endings
        // We look for punctuation followed by space or end of string.
        final matches = _sentenceEndRegex.allMatches(_streamBuffer);
        
        if (matches.isNotEmpty) {
          final lastMatch = matches.last;
          final lastPunctuationIndex = lastMatch.end;
          
          // Speak the completed sentence part
          String toSpeak = _streamBuffer.substring(0, lastPunctuationIndex);
          
          // CRITICAL: Update buffer BEFORE yielding to prevent race conditions
          _streamBuffer = _streamBuffer.substring(lastPunctuationIndex);
          
          await speak(toSpeak);
          
          // After speaking/yielding, loop back to check for new chunks or more matches
          continue;
        }
        
        // 3. If no matches found and queue handled, we are done
        break; 
      }
    } catch (e) {
      debugPrint("Stream Processing Error: $e");
    } finally {
      _isProcessingChunks = false;
    }
  }
  
  Future<void> flushStream() async {
    if (!autoPlay) return;
    // Ensure any remaining queue items are processed into buffer
    while (_chunkQueue.isNotEmpty) {
      _streamBuffer += _chunkQueue.removeAt(0);
    }

    if (_streamBuffer.trim().isNotEmpty) {
      await speak(_streamBuffer);
      _streamBuffer = '';
    }
  }
}
