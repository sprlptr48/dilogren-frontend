import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schemas.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'active_session_screen.dart';
import 'widgets/async_data_view.dart';

class SessionSetupScreen extends StatefulWidget {
  const SessionSetupScreen({super.key});

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  late Future<List<Course>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    final apiService = Provider.of<ApiService>(context, listen: false);
    _coursesFuture = apiService.getCourses();
  }

  Future<void> _startSession(Course course) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      final request = CourseSessionStartRequest(
        courseId: course.id,
        level: authService.user?.cefrLevel ?? CefrLevel.B1,
      );
      final conversation = await apiService.startCourseSession(request);

      // Fix for empty sessions
      if (conversation.messages.isEmpty) {
        final courseName = course.name;
        conversation.messages.add(
          ChatMessage(
            role: 'assistant',
            content: "Hello! Welcome to your **$courseName** lesson. I'm your English teacher and I'll help you master this topic. Ready to begin?",
          ),
        );
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveSessionScreen(initialConversation: conversation),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting session: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Courses')),
      body: AsyncDataView<List<Course>>(
        future: _coursesFuture,
        isEmpty: (data) => data.isEmpty,
        emptyMessage: 'No courses available.',
        emptyIcon: Icons.school_outlined,
        builder: (courses) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(course.name),
                subtitle: Text(course.description ?? ''),
                leading: CircleAvatar(child: Text(course.recommendedLevel.name)),
                onTap: () => _startSession(course),
              ),
            );
          },
        ),
      ),
    );
  }
}