import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schemas.dart';
import '../services/api_service.dart';
import 'base_chat_screen.dart';
import 'widgets/check_errors_action.dart';

class ActiveSessionScreen extends BaseChatScreen {
  final Conversation initialConversation;

  const ActiveSessionScreen({
    super.key,
    required this.initialConversation,
  });

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends BaseChatScreenState<ActiveSessionScreen> {
  @override
  List<ChatMessage> getInitialMessages() {
    if (widget.initialConversation is ConversationDetail) {
      return (widget.initialConversation as ConversationDetail).messages;
    }
    return [];
  }

  @override
  bool shouldFetchHistory() {
    if (widget.initialConversation is ConversationDetail) {
      return false;
    }
    return true;
  }

  @override
  Future<void> fetchConversationHistory() async {
    if (!shouldFetchHistory()) return;
    await fetchBaseConversationHistory(widget.initialConversation.id);
  }

  @override
  void sendMessage() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final text = textController.text.trim();
    
    sendBaseMessage(
      message: text, 
      sendApiCall: (msg) => apiService.sendMessage(widget.initialConversation.id, msg)
    );
  }

  @override
  String getTitle() => widget.initialConversation.title ?? 'Chat';

  @override
  String? getSubtitle() => null;

  @override
  List<Widget> getAppBarActions() => [
    CheckErrorsAction(isLoading: isCheckingErrors, onPressed: checkAllMessagesCommon),
  ];

  @override
  Widget? buildHeaderWidget() => null;

  @override
  String getInputHint() => 'Type or speak your message...';
}
