import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schemas.dart';
import '../services/api_service.dart';
import 'base_chat_screen.dart';
import 'widgets/chat_header_widget.dart';

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
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final conversationDetail = await apiService.getConversation(widget.conversationId);
      setState(() {
        messages = conversationDetail.messages;
        isLoadingHistory = false;
      });
      scrollToBottom();
    } catch (e) {
      print('🔴 Failed to fetch error practice history: $e');
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

  @override
  void sendMessage() {
    final text = textController.text.trim();
    if (text.isEmpty || isStreaming) return;

    final apiService = Provider.of<ApiService>(context, listen: false);
    textController.clear();

    setState(() {
      messages.add(ChatMessage(role: 'user', content: text));
      isStreaming = true;
      currentStreamBuffer = '';
      loadingStatus = 'Connecting...';
    });

    scrollToBottom();

    apiService.sendMessage(widget.conversationId, text).listen(
      (event) {
        if (!mounted) return;
        setState(() {
          if (event['type'] == 'status') {
            loadingStatus = event['content'] == 'queued'
                ? 'Waiting in Queue...'
                : 'Processing...';
          }
          else if (event['type'] == 'chunk') {
            loadingStatus = 'Typing...';
            currentStreamBuffer += event['content'];
          }
        });
        scrollToBottom();
      },
      onError: (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() => isStreaming = false);
      },
      onDone: () {
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

  @override
  String getTitle() => 'Error Practice';

  @override
  String? getSubtitle() => widget.focusAreas.isEmpty
      ? '${widget.errorCount} error${widget.errorCount != 1 ? 's' : ''}'
      : '${widget.errorCount} error${widget.errorCount != 1 ? 's' : ''} • ${widget.focusAreas.join(", ")}';

  @override
  List<Widget> getAppBarActions() => [];

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
            border: Border.all(
              color: Colors.orange.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconForErrorType(area),
                size: 14,
                color: Colors.orange[700],
              ),
              const SizedBox(width: 6),
              Text(
                area.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconForErrorType(String type) {
    switch (type.toLowerCase()) {
      case 'grammar':
        return Icons.text_fields_rounded;
      case 'spelling':
        return Icons.spellcheck_rounded;
      case 'vocabulary':
        return Icons.book_rounded;
      case 'punctuation':
        return Icons.format_quote_rounded;
      case 'syntax':
        return Icons.code_rounded;
      default:
        return Icons.error_outline_rounded;
    }
  }

  @override
  String getInputHint() => 'Practice your skills...';
}
