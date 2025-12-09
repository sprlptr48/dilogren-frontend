import 'package:flutter/material.dart';
import '../../models/schemas.dart';

/// A beautiful celebration overlay for when a phase is completed
class PhaseCompletionOverlay extends StatefulWidget {
  final String phase;
  final VoidCallback onDismiss;

  const PhaseCompletionOverlay({
    super.key,
    required this.phase,
    required this.onDismiss,
  });

  @override
  State<PhaseCompletionOverlay> createState() => _PhaseCompletionOverlayState();
}

class _PhaseCompletionOverlayState extends State<PhaseCompletionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _phaseName => phaseLabels[widget.phase] ?? widget.phase;

  IconData get _phaseIcon => switch (widget.phase) {
        'grammar' => Icons.menu_book,
        'practice' => Icons.edit_note,
        'speaking' => Icons.record_voice_over,
        _ => Icons.check_circle,
      };

  Color get _phaseColor => switch (widget.phase) {
        'grammar' => const Color(0xFF6366F1), // Indigo
        'practice' => const Color(0xFF10B981), // Emerald
        'speaking' => const Color(0xFFF59E0B), // Amber
        _ => const Color(0xFF6366F1),
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: _buildCard(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _phaseColor.withValues(alpha: 0.9),
            _phaseColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _phaseColor.withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Celebration emoji
          const Text(
            '🎉',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),

          // Phase icon in a circle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _phaseIcon,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            '$_phaseName Mastered!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle
          Text(
            _getSubtitle(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Tap to continue hint
          Text(
            'Tap anywhere to continue',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getSubtitle() {
    return switch (widget.phase) {
      'grammar' => 'You\'ve mastered the grammar foundations!\nNow let\'s practice what you learned.',
      'practice' => 'Great practice session!\nTime to level up to speaking.',
      'speaking' => 'Amazing! You\'re becoming fluent!\nKeep practicing to maintain your skills.',
      _ => 'Congratulations on your progress!',
    };
  }
}

/// Shows a phase completion toast (less intrusive than overlay)
void showPhaseCompletedToast(BuildContext context, String phase) {
  final phaseName = phaseLabels[phase] ?? phase;
  final color = switch (phase) {
    'grammar' => const Color(0xFF6366F1),
    'practice' => const Color(0xFF10B981),
    'speaking' => const Color(0xFFF59E0B),
    _ => const Color(0xFF6366F1),
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$phaseName Mastered!',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Moving to the next phase...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
    ),
  );
}
