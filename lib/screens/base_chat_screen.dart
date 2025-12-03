import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../models/schemas.dart';

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
  String initialTextBeforeStt = '';

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
    textController.dispose();
    scrollController.dispose();
    speechToText.cancel();
    micAnimationController.dispose();
    super.dispose();
  }

  void initSpeech() async {
    if (Platform.isWindows) {
      setState(() => isSttSupported = false);
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
    setState(() {});
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
          if (buildHeaderWidget() != null) buildHeaderWidget()!,
          Expanded(
            child: isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (isStreaming ? 1 : 0),
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
