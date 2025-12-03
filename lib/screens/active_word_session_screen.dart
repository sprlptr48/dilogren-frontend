import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schemas.dart';
import '../services/api_service.dart';
import 'base_chat_screen.dart';
import 'widgets/chat_header_widget.dart';

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
  Future<void> fetchConversationHistory() async {
    // Not needed for word sessions since history is already in the session
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

    apiService.sendWordMessage(widget.session.sessionId, text).listen(
      (event) {
        if (!mounted) return;
        setState(() {
          if (event['type'] == 'status') {
            if (event['content'] == 'queued') {
              loadingStatus = 'Waiting in Queue (Serverless GPU warming up)...';
            } else {
              loadingStatus = 'Processing...';
            }
          }
          else if (event['type'] == 'chunk') {
            loadingStatus = 'Typing...';
            currentStreamBuffer += event['content'];
          }
        });
        scrollToBottom();
      },
      onError: (e) {
        print('🔴 Word chat error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
  String getTitle() => 'Word Learning Session';

  @override
  String? getSubtitle() => '${widget.session.settings.words.length} words • ${widget.session.settings.level.name}';

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
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
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
