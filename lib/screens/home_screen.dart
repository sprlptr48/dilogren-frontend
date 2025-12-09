import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_helpers.dart';
import 'session_setup_screen.dart';
import 'word_session_setup_screen.dart';
import 'error_checker_screen.dart';
import 'error_history_screen.dart';
import 'active_error_practice_screen.dart';
import 'session_list_screen.dart';
import 'error_stats_screen.dart';
import 'user_profile_screen.dart';
import 'active_adaptive_chat_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;
    final displayName = user?.fullName ?? user?.username ?? 'Learner';

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $displayName!'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen()));
              } else if (value == 'sessions') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionListScreen()));
              } else if (value == 'stats') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ErrorStatsScreen()));
              } else if (value == 'settings') {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              } else if (value == 'logout') {
                await authService.logout();
              }
            },
            itemBuilder: (_) => const <PopupMenuEntry<String>>[
              PopupMenuItem(value: 'profile', child: Row(children: [Icon(Icons.person_outline), SizedBox(width: 8), Text('Profile')])),
              PopupMenuItem(value: 'sessions', child: Row(children: [Icon(Icons.history), SizedBox(width: 8), Text('My Sessions')])),
              PopupMenuItem(value: 'stats', child: Row(children: [Icon(Icons.analytics_outlined), SizedBox(width: 8), Text('Error Stats')])),
              PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings), SizedBox(width: 8), Text('Settings')])),
               PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 8), Text('Logout')])),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Title
              const Text(
                'dilöğren',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondary,
                  letterSpacing: -1,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                'Your AI-Powered Language Practice Partner',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
              ),
              
              const SizedBox(height: 32),
                            
              // Adaptive Chat Button (Primary)
              _buildAdaptiveChatButton(context),

              const SizedBox(height: 24),
              
              // Divider for other options
              _buildSectionDivider('SPECIFIC MODES'),

              const SizedBox(height: 24),

              // Browse Courses Button
              _buildActionButton(
                context: context,
                label: 'Browse Courses',
                icon: Icons.chat_bubble_outline_rounded,
                color: AppTheme.primary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionSetupScreen())),
              ),
              
              const SizedBox(height: 12),

              // Learn Words Button
              _buildActionButton(
                context: context,
                label: 'Learn Words',
                icon: Icons.school_rounded,
                color: AppTheme.accent,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WordSessionSetupScreen())),
              ),
              
              const SizedBox(height: 12),

              // Practice Your Mistakes Button
              _buildActionButton(
                context: context,
                label: 'Practice Your Mistakes',
                icon: Icons.psychology_rounded,
                color: Colors.deepOrange,
                onTap: () => _startErrorPractice(context),
              ),

              const SizedBox(height: 12),

              // Error Tools Row
              Row(
                children: [
                  Expanded(
                    child: _buildCompactButton(
                      context: context,
                      label: 'Check Text',
                      icon: Icons.check_circle_outline,
                      color: Colors.orange,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ErrorCheckerScreen())),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactButton(
                      context: context,
                      label: 'History',
                      icon: Icons.history,
                      color: Colors.blueGrey,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ErrorHistoryScreen())),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdaptiveChatButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.primary,
        boxShadow: [
          BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _startAdaptiveChat(context),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(Icons.auto_awesome, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Start',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Practice everything in one place.\nContext-aware AI companion.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionDivider(String label) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCompactButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  void _startAdaptiveChat(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    runWithLoadingDialog(
      context: context,
      task: () => apiService.startAdaptiveSession(),
      screenBuilder: (session) => ActiveAdaptiveChatScreen(
        conversationId: session.id,
        initialMessages: session.messages,
        activeCourseId: session.activeCourseId,
      ),
      errorPrefix: 'Failed to start chat',
    );
  }

  void _startErrorPractice(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    runWithLoadingDialog(
      context: context,
      task: () => apiService.startErrorPractice(),
      screenBuilder: (response) => ActiveErrorPracticeScreen(
        conversationId: response.sessionId,
        errorCount: response.errorCount,
        focusAreas: response.focusAreas,
      ),
      errorPrefix: 'Failed to start practice',
    );
  }
}
