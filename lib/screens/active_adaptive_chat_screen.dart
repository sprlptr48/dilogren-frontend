import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schemas.dart';
import '../services/api_service.dart';
import 'base_chat_screen.dart';
import 'widgets/chat_header_widget.dart';
import 'widgets/check_errors_action.dart';

class ActiveAdaptiveChatScreen extends BaseChatScreen {
  final String conversationId;
  final List<ChatMessage> initialMessages;

  const ActiveAdaptiveChatScreen({
    super.key,
    required this.conversationId,
    required this.initialMessages,
  });

  @override
  State<ActiveAdaptiveChatScreen> createState() => _ActiveAdaptiveChatScreenState();
}

class _ActiveAdaptiveChatScreenState extends BaseChatScreenState<ActiveAdaptiveChatScreen> {
  static const List<String> _availableActions = [
    "Practice Mistakes",
    "Daily Scenario", 
    "Continue Course",
    "Learn Words"
  ];

  @override
  List<ChatMessage> getInitialMessages() => widget.initialMessages;

  @override
  bool shouldFetchHistory() => true;

  @override
  Future<void> fetchConversationHistory() async {
    await fetchBaseConversationHistory(widget.conversationId);
  }

  @override
  void sendMessage() {
    final text = textController.text.trim();
    _sendText(text);
  }

  void _sendText(String text) {
    if (text.isEmpty || isStreaming) return;

    final apiService = Provider.of<ApiService>(context, listen: false);
    
    sendBaseMessage(
      message: text,
      sendApiCall: (msg) => apiService.sendMessage(widget.conversationId, msg),
      statusMessageBuilder: (status) => 'Analyzing Context...'
    );
  }

  void _handleActionTap(String action) {
    const actionMessages = {
      "Practice Mistakes": "I want to practice my recent mistakes.",
      "Daily Scenario": "Let's talk about today's daily scenario.",
      "Continue Course": "I want to continue with my active course.",
      "Learn Words": "Teach me some new words for today.",
    };
    
    final message = actionMessages[action];
    if (message != null) _sendText(message);
  }

  @override
  String getTitle() => 'Dil Öğretmen';

  @override
  String? getSubtitle() => 'Adaptive Learning Companion';

  @override
  List<Widget> getAppBarActions() => [
    CheckErrorsAction(isLoading: isCheckingErrors, onPressed: checkAllMessagesCommon),
  ];

  @override
  Widget? buildHeaderWidget() {
    return ChatHeaderWidget(
      title: 'Quick Actions',
      icon: Icons.auto_awesome,
      primaryColor: Colors.purple,
      items: _availableActions,
      onItemTap: _handleActionTap,
      itemBuilder: (context, action) {
        final (icon, color) = _getActionStyle(action);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5)),
            boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(action, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color.withOpacity(0.9))),
            ],
          ),
        );
      },
    );
  }

  (IconData, Color) _getActionStyle(String action) {
    return switch (action) {
      "Practice Mistakes" => (Icons.psychology, Colors.orange),
      "Daily Scenario" => (Icons.theater_comedy, Colors.teal),
      "Continue Course" => (Icons.school, Colors.blue),
      "Learn Words" => (Icons.translate, Colors.pink),
      _ => (Icons.star, Colors.grey),
    };
  }

  @override
  String getInputHint() => 'Ask me anything or choose an action...';
}
