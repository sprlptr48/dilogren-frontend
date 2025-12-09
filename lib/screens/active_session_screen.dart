import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schemas.dart';
import '../services/api_service.dart';
import 'base_chat_screen.dart';
import 'widgets/check_errors_action.dart';
import 'widgets/phase_completion_overlay.dart';

class ActiveSessionScreen extends BaseChatScreen {
  final Conversation initialConversation;
  final String? courseId; // Optional: for fetching progress

  const ActiveSessionScreen({
    super.key,
    required this.initialConversation,
    this.courseId,
  });

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends BaseChatScreenState<ActiveSessionScreen> {
  CourseProgress? _courseProgress;

  @override
  void initState() {
    super.initState();
    // Fetch initial progress if we have a course ID
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    if (widget.courseId == null) return;
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final progress = await apiService.getCourseProgress(widget.courseId!);
      if (mounted) {
        setState(() {
          _courseProgress = progress;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch course progress: $e');
    }
  }

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
      sendApiCall: (msg) => apiService.sendMessage(widget.initialConversation.id, msg),
      onToolCalls: _handleToolCalls,
    );
  }

  /// Handle tool calls from the backend (including phase completion)
  void _handleToolCalls(List<dynamic> toolCalls) {
    for (final toolCall in toolCalls) {
      final name = toolCall['name'] as String?;
      
      if (name == 'complete_phase') {
        final arguments = toolCall['arguments'] as Map<String, dynamic>?;
        final phase = arguments?['phase'] as String?;
        
        if (phase != null) {
          _showPhaseCompleted(phase);
        }
      }
    }
  }

  /// Show phase completion celebration
  void _showPhaseCompleted(String phase) {
    // Show a toast notification
    if (mounted) {
      showPhaseCompletedToast(context, phase);
    }
    
    // Optionally refresh progress
    _fetchProgress();
  }

  @override
  String getTitle() => widget.initialConversation.title ?? 'Chat';

  @override
  String? getSubtitle() {
    // Show current phase if we have progress
    if (_courseProgress != null) {
      final currentPhase = _courseProgress!.currentPhase;
      final phaseName = phaseLabels[currentPhase] ?? currentPhase;
      return 'Phase: $phaseName';
    }
    return null;
  }

  @override
  List<Widget> getAppBarActions() => [
    CheckErrorsAction(isLoading: isCheckingErrors, onPressed: checkAllMessagesCommon),
  ];

  @override
  Widget? buildHeaderWidget() {
    // Only show progress header if we have a course ID and progress
    if (_courseProgress == null) return null;
    
    return _PhaseProgressHeader(progress: _courseProgress!);
  }

  @override
  String getInputHint() => 'Type or speak your message...';
}

/// A compact progress header showing phase completion status
class _PhaseProgressHeader extends StatelessWidget {
  final CourseProgress progress;

  const _PhaseProgressHeader({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase indicators
          Row(
            children: phaseOrder.map((phase) {
              final isCompleted = progress.isPhaseCompleted(phase);
              final isCurrent = progress.currentPhase == phase;
              
              return Expanded(
                child: Row(
                  children: [
                    _PhaseIndicator(
                      phase: phase,
                      isCompleted: isCompleted,
                      isCurrent: isCurrent,
                    ),
                    if (phase != phaseOrder.last)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted
                              ? _getPhaseColor(phase)
                              : Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.progressPercentage / 100,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getPhaseColor(progress.currentPhase),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          
          // Percentage text
          Text(
            '${progress.progressPercentage.toStringAsFixed(0)}% Complete',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPhaseColor(String phase) {
    return switch (phase) {
      'grammar' => const Color(0xFF6366F1),
      'practice' => const Color(0xFF10B981),
      'speaking' => const Color(0xFFF59E0B),
      _ => const Color(0xFF6366F1),
    };
  }
}

class _PhaseIndicator extends StatelessWidget {
  final String phase;
  final bool isCompleted;
  final bool isCurrent;

  const _PhaseIndicator({
    required this.phase,
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getPhaseColor();
    final phaseName = phaseLabels[phase] ?? phase;
    
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCompleted ? color : (isCurrent ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2)),
            shape: BoxShape.circle,
            border: isCurrent && !isCompleted
                ? Border.all(color: color, width: 2)
                : null,
          ),
          child: Icon(
            isCompleted ? Icons.check : _getPhaseIcon(),
            size: 16,
            color: isCompleted ? Colors.white : (isCurrent ? color : Colors.grey),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          phaseName,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? color : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getPhaseColor() {
    return switch (phase) {
      'grammar' => const Color(0xFF6366F1),
      'practice' => const Color(0xFF10B981),
      'speaking' => const Color(0xFFF59E0B),
      _ => const Color(0xFF6366F1),
    };
  }

  IconData _getPhaseIcon() {
    return switch (phase) {
      'grammar' => Icons.menu_book,
      'practice' => Icons.edit_note,
      'speaking' => Icons.record_voice_over,
      _ => Icons.circle,
    };
  }
}
