import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schemas.dart';
import '../services/api_service.dart';
import 'base_chat_screen.dart';

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
  List<ChatMessage> getInitialMessages() => [];

  @override
  bool shouldFetchHistory() => true;

  @override
  Future<void> fetchConversationHistory() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final conversationDetail = await apiService.getConversation(widget.initialConversation.id);
      setState(() {
        messages = conversationDetail.messages;
        isLoadingHistory = false;
      });
      scrollToBottom();
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

    apiService.sendMessage(widget.initialConversation.id, text).listen(
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

  Future<void> _checkAllMessages() async {
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

  @override
  String getTitle() => widget.initialConversation.title ?? 'Chat';

  @override
  String? getSubtitle() => null;

  @override
  List<Widget> getAppBarActions() {
    return [
      isCheckingErrors
          ? const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : IconButton(
              icon: const Icon(Icons.plagiarism_outlined),
              tooltip: 'Analyze My Messages',
              onPressed: _checkAllMessages,
            ),
    ];
  }

  @override
  Widget? buildHeaderWidget() => null;

  @override
  String getInputHint() => 'Type or speak your message...';
}
