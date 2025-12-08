import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schemas.dart';
import '../services/api_service.dart';
import 'base_chat_screen.dart';
import 'widgets/chat_header_widget.dart';
import 'widgets/check_errors_action.dart';

class ActiveWordSessionScreen extends BaseChatScreen {
  final WordLearningSession session;

  const ActiveWordSessionScreen({
    super.key,
    required this.session,
  });

  @override
  State<ActiveWordSessionScreen> createState() => _ActiveWordSessionScreenState();
}

class _ActiveWordSessionScreenState extends BaseChatScreenState<ActiveWordSessionScreen> {
  @override
  List<ChatMessage> getInitialMessages() => List.from(widget.session.history);

  @override
  bool shouldFetchHistory() => false;

  @override
  Future<void> fetchConversationHistory() async {}

  @override
  void sendMessage() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final text = textController.text.trim();

    sendBaseMessage(
      message: text,
      sendApiCall: (msg) => apiService.sendWordMessage(widget.session.sessionId, msg),
      statusMessageBuilder: (status) {
        if (status == 'queued') {
          return 'Waiting in Queue (Serverless GPU warming up)...';
        }
        return 'Processing...';
      }
    );
  }

  @override
  String getTitle() => 'Word Learning Session';

  @override
  String? getSubtitle() => '${widget.session.settings.words.length} words • ${widget.session.settings.level.name}';

  @override
  List<Widget> getAppBarActions() => [
    CheckErrorsAction(isLoading: isCheckingErrors, onPressed: checkAllMessagesCommon),
  ];

  @override
  Widget? buildHeaderWidget() {
    return ChatHeaderWidget(
      title: 'Your Words',
      icon: Icons.school_rounded,
      primaryColor: Theme.of(context).primaryColor,
      items: widget.session.settings.words,
      itemBuilder: (context, word) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
          ),
          child: Text(
            word,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
        );
      },
    );
  }

  @override
  String getInputHint() => 'Practice using these words...';
}
