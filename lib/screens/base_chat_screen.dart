import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schemas.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../controllers/chat_controller.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/chat_input_area.dart';

abstract class BaseChatScreen extends StatefulWidget {
  const BaseChatScreen({super.key});
}

abstract class BaseChatScreenState<T extends BaseChatScreen> extends State<T> with SingleTickerProviderStateMixin {
  late ChatController controller;
  
  // UI Animation State
  late AnimationController micAnimationController;
  late Animation<double> micAnimation;

  // Proxies for subclasses to maintain backward compatibility
  TextEditingController get textController => controller.textController;
  ScrollController get scrollController => controller.scrollController;
  
  List<ChatMessage> get messages => controller.messages;
  set messages(List<ChatMessage> value) => controller.messages = value;

  bool get isLoadingHistory => controller.isLoadingHistory;
  set isLoadingHistory(bool value) => controller.isLoadingHistory = value;

  bool get isStreaming => controller.isStreaming;
  bool get isCheckingErrors => controller.isCheckingErrors;
  bool get isListening => controller.isListening;
  
  @override
  void initState() {
    super.initState();
    controller = ChatController();
    controller.addListener(_onControllerChanged);

    // Give subclasses a chance to provide initial messages
    controller.setMessages(getInitialMessages());

    if (shouldFetchHistory()) {
      fetchConversationHistory();
    } else {
      controller.isLoadingHistory = false;
    }

    controller.initSpeech();

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

  void _onControllerChanged() {
    if (mounted) {
      if (controller.isListening && !micAnimationController.isAnimating) {
        micAnimationController.repeat(reverse: true);
      } else if (!controller.isListening && micAnimationController.isAnimating) {
        micAnimationController.stop();
        micAnimationController.reset();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    // Fire and forget error check
    controller.triggerExitErrorCheck((text) => apiService.checkErrors(ErrorCheckRequest(text: text)));
    
    micAnimationController.dispose();
    controller.removeListener(_onControllerChanged);
    controller.dispose();
    super.dispose();
  }

  // --- Methods typically called by subclasses ---

  Future<void> fetchBaseConversationHistory(String conversationId) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      await controller.fetchHistory(apiService, conversationId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to load history: ${e.toString()}')),
        );
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
    controller.sendMessage(
      message: message,
      sendApiCall: sendApiCall,
      statusMessageBuilder: statusMessageBuilder,
      onToolCalls: onToolCalls,
      enableAutoErrorCheckOnExit: enableAutoErrorCheckOnExit,
    );
  }

  // Common UI Logic for Error Checking
  Future<void> checkAllMessagesCommon() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    try {
      final response = await controller.checkErrors(apiService);

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
        
        // Handle level feedback (either validation or change suggestion)
        if (response.levelChanged == true) {
          // AI suggests a level change
          await handleLevelChangeSuggestion(response);
        } else if (response.levelValidated == true) {
          // AI confirmed level is correct - show subtle feedback
          _showLevelValidatedFeedback(response);
        }
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
    }
  }

  // Show subtle feedback when AI confirms level is correct
  void _showLevelValidatedFeedback(ErrorCheckResponse response) {
    final currentLevel = response.currentLevel ?? 'your level';
    final reasoning = response.validationReasoning;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                reasoning != null 
                    ? '✓ $currentLevel confirmed: $reasoning'
                    : '✓ Your writing matches $currentLevel level!',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueGrey,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Handle level change suggestion from error check (UI Logic)
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
                  color: Colors.blue.withValues(alpha: 0.1),
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
            child: controller.isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: controller.scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.messages.length + (controller.isStreaming ? 1 : 0),
                    // Performance optimizations
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    itemBuilder: (context, index) {
                      if (controller.isStreaming && index == controller.messages.length) {
                        return buildMessageBubble(
                          role: 'assistant',
                          content: controller.currentStreamBuffer,
                          isStreaming: true,
                        );
                      }
                      final msg = controller.messages[index];
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
    return ChatMessageBubble(
      role: role, 
      content: content, 
      isStreaming: isStreaming,
      loadingStatus: controller.loadingStatus,
    );
  }

  Widget buildInputArea() {
    return ChatInputArea(
      controller: controller.textController,
      isListening: controller.isListening,
      isStreaming: controller.isStreaming,
      sttAvailable: controller.sttAvailable,
      isSttSupported: controller.isSttSupported,
      micAnimation: micAnimation,
      hintText: getInputHint(),
      onMicPressed: controller.isListening ? controller.stopListening : controller.startListening,
      onSendPressed: sendMessage,
    );
  }
}
