import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schemas.dart';
import '../services/api_service.dart';
import 'base_chat_screen.dart';
import 'widgets/chat_header_widget.dart';
import 'widgets/check_errors_action.dart';

class ActiveErrorPracticeScreen extends BaseChatScreen {
  final String conversationId;
  final int errorCount;
  final List<String> focusAreas;

  const ActiveErrorPracticeScreen({
    super.key,
    required this.conversationId,
    required this.errorCount,
    required this.focusAreas,
  });

  @override
  State<ActiveErrorPracticeScreen> createState() => _ActiveErrorPracticeScreenState();
}

class _ActiveErrorPracticeScreenState extends BaseChatScreenState<ActiveErrorPracticeScreen> {
  @override
  List<ChatMessage> getInitialMessages() => [];

  @override
  bool shouldFetchHistory() => true;

  @override
  Future<void> fetchConversationHistory() async {
    await fetchBaseConversationHistory(widget.conversationId);
  }

  @override
  void sendMessage() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final text = textController.text.trim();

    sendBaseMessage(
      message: text,
      sendApiCall: (msg) => apiService.sendMessage(widget.conversationId, msg)
    );
  }

  @override
  String getTitle() => 'Error Practice';

  @override
  String? getSubtitle() {
    final errorLabel = '${widget.errorCount} error${widget.errorCount != 1 ? 's' : ''}';
    if (widget.focusAreas.isEmpty) return errorLabel;
    return '$errorLabel • ${widget.focusAreas.join(", ")}';
  }

  @override
  List<Widget> getAppBarActions() => [
    CheckErrorsAction(isLoading: isCheckingErrors, onPressed: checkAllMessagesCommon),
  ];

  @override
  Widget? buildHeaderWidget() {
    if (widget.focusAreas.isEmpty) return null;
    
    return ChatHeaderWidget(
      title: 'Practice Focus',
      icon: Icons.psychology_rounded,
      primaryColor: Colors.orange,
      items: widget.focusAreas,
      itemBuilder: (context, area) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getIconForErrorType(area), size: 14, color: Colors.orange[700]),
              const SizedBox(width: 6),
              Text(
                area.toUpperCase(),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange[700]),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconForErrorType(String type) {
    return switch (type.toLowerCase()) {
      'grammar' => Icons.text_fields_rounded,
      'spelling' => Icons.spellcheck_rounded,
      'vocabulary' => Icons.book_rounded,
      'punctuation' => Icons.format_quote_rounded,
      'syntax' => Icons.code_rounded,
      _ => Icons.error_outline_rounded,
    };
  }

  @override
  String getInputHint() => 'Practice your skills...';
}
