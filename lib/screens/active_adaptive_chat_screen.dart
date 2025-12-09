import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schemas.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_helpers.dart';
import 'base_chat_screen.dart';
import 'widgets/chat_header_widget.dart';
import 'widgets/check_errors_action.dart';
import 'active_error_practice_screen.dart';
import 'active_word_session_screen.dart';
import 'active_session_screen.dart';

class ActiveAdaptiveChatScreen extends BaseChatScreen {
  final String conversationId;
  final List<ChatMessage> initialMessages;
  final String? activeCourseId;  // The user's active course for navigation

  const ActiveAdaptiveChatScreen({
    super.key,
    required this.conversationId,
    required this.initialMessages,
    this.activeCourseId,
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
      statusMessageBuilder: (status) => 'Analyzing Context...',
      onToolCalls: _handleToolCalls,
      enableAutoErrorCheckOnExit: true,
    );
  }

  /// Handle tool calls from the AI to navigate to other screens
  void _handleToolCalls(List<dynamic> toolCalls) {
    for (final toolCall in toolCalls) {
      final name = toolCall['name'] as String?;
      
      switch (name) {
        case 'navigate_to_mistakes':
          _navigateToMistakePractice();
          break;
        case 'navigate_to_words':
          _navigateToWordLearning();
          break;
        case 'navigate_to_course':
          _navigateToCourse();
          break;
        case 'trigger_error_check':
          checkAllMessagesCommon();
          break;
      }
    }
  }

  /// Navigate to error practice screen
  void _navigateToMistakePractice() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    runWithLoadingDialog(
      context: context,
      task: () => apiService.startErrorPractice(),
      screenBuilder: (session) => ActiveErrorPracticeScreen(
        conversationId: session.sessionId,
        errorCount: session.errorCount,
        focusAreas: session.focusAreas,
      ),
      errorPrefix: 'Failed to start mistake practice',
    );
  }

  /// Navigate to word learning screen (defaults to daily mode)
  void _navigateToWordLearning() {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final level = authService.user?.cefrLevel ?? CefrLevel.B1;
    
    final request = WordSessionStartRequest(
      level: level,
      count: 5,
      mode: 'daily',
    );
    
    runWithLoadingDialog(
      context: context,
      task: () => apiService.startWordSession(request),
      screenBuilder: (session) => ActiveWordSessionScreen(session: session),
      errorPrefix: 'Failed to start word learning',
    );
  }

  /// Navigate to course session using the active course ID
  void _navigateToCourse() {
    final courseId = widget.activeCourseId;
    
    if (courseId == null) {
      // No active course - show message to select one
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active course found. Please start a course from the home screen.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    // Start the course session
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final level = authService.user?.cefrLevel ?? CefrLevel.B1;
    
    final request = CourseSessionStartRequest(courseId: courseId, level: level);
    
    runWithLoadingDialog(
      context: context,
      task: () => apiService.startCourseSession(request),
      screenBuilder: (session) => ActiveSessionScreen(
        initialConversation: session,
        courseId: courseId,
      ),
      errorPrefix: 'Failed to start course',
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
  String getTitle() => 'Adaptive Chat';

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
      primaryColor: AppTheme.primary,
      items: _availableActions,
      onItemTap: _handleActionTap,
      itemBuilder: (context, action) {
        final (icon, color) = _getActionStyle(action);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(action, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.9))),
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
