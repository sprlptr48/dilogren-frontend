import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schemas.dart';
import '../services/api_service.dart';
import 'active_session_screen.dart';
import 'active_word_session_screen.dart';
import 'active_error_practice_screen.dart';

class SessionListScreen extends StatefulWidget {
  const SessionListScreen({super.key});

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  String? _selectedFilter;
  List<ConversationListItem> _conversations = [];
  bool _isLoading = true;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.getConversations(
        conversationType: _selectedFilter,
        limit: 50,
      );

      setState(() {
        _conversations = response.conversations;
        _total = response.total;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load sessions: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text('Are you sure you want to delete this session? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        await apiService.deleteSession(sessionId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session deleted successfully')),
          );
          _loadConversations();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete session: ${e.toString()}')),
          );
        }
      }
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'course':
        return 'Course';
      case 'word_learning':
        return 'Word Learning';
      case 'error_practice':
        return 'Error Practice';
      default:
        return type;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'course':
        return Icons.chat_bubble_outline_rounded;
      case 'word_learning':
        return Icons.school_rounded;
      case 'error_practice':
        return Icons.psychology_rounded;
      default:
        return Icons.chat;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'course':
        return Theme.of(context).primaryColor;
      case 'word_learning':
        return Colors.purple;
      case 'error_practice':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedFilter == null,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = null);
                      _loadConversations();
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Courses'),
                    selected: _selectedFilter == 'course',
                    onSelected: (selected) {
                      setState(() => _selectedFilter = selected ? 'course' : null);
                      _loadConversations();
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Word Learning'),
                    selected: _selectedFilter == 'word_learning',
                    onSelected: (selected) {
                      setState(() => _selectedFilter = selected ? 'word_learning' : null);
                      _loadConversations();
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Error Practice'),
                    selected: _selectedFilter == 'error_practice',
                    onSelected: (selected) {
                      setState(() => _selectedFilter = selected ? 'error_practice' : null);
                      _loadConversations();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Session Count
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '$_total session${_total != 1 ? 's' : ''} found',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),

          const SizedBox(height: 8),

          // Sessions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _conversations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No sessions found',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadConversations,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _conversations.length,
                          itemBuilder: (itemContext, index) {
                            final conversation = _conversations[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getTypeColor(conversation.conversationType).withValues(alpha: 0.2),
                                  child: Icon(
                                    _getTypeIcon(conversation.conversationType),
                                    color: _getTypeColor(conversation.conversationType),
                                  ),
                                ),
                                title: Text(
                                  conversation.title ?? 'Untitled Session',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(_getTypeLabel(conversation.conversationType)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${conversation.messageCount} messages • ${_formatDate(conversation.updatedAt)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _deleteSession(conversation.id),
                                ),
                                onTap: () async {
                                  // Navigate to session
                                  try {
                                    final apiService = Provider.of<ApiService>(context, listen: false);
                                    
                                    // Show loading indicator briefly if needed or just navigate (fetch happens in next screen often)
                                    // But here we need details to decide arguments for some screens
                                    final conversationDetail = await apiService.getConversation(conversation.id);

                                    if (!itemContext.mounted) return;

                                    if (conversation.conversationType == 'course') {
                                      // Fix for empty sessions (e.g. reused sessions without greetings):
                                      if (conversationDetail.messages.isEmpty) {
                                          final courseName = conversationDetail.settings['course_name'] ?? 'Course';
                                          conversationDetail.messages.add(
                                            ChatMessage(
                                              role: 'assistant',
                                              content: "Hello! Welcome to your **$courseName** lesson. I'm your English teacher and I'll help you master this topic. Ready to begin?",
                                            ),
                                          );
                                      }

                                      Navigator.push(
                                        itemContext,
                                        MaterialPageRoute(
                                          builder: (context) => ActiveSessionScreen(
                                            initialConversation: conversationDetail,
                                            courseId: conversationDetail.settings['course_id'] as String?,
                                          ),
                                        ),
                                      );
                                    } else if (conversation.conversationType == 'word_learning') {
                                      // Construct WordLearningSession from detail
                                      final wordSession = WordLearningSession(
                                        sessionId: conversationDetail.id,
                                        settings: WordLearningSettings.fromJson(conversationDetail.settings),
                                        history: conversationDetail.messages,
                                      );

                                      // Fix for empty sessions
                                      if (wordSession.history.isEmpty) {
                                          final words = wordSession.settings.words;
                                          final wordPreview = words.length > 5 
                                              ? "${words.take(5).join(', ')}... (+${words.length - 5} more)"
                                              : words.join(', ');
                                              
                                          wordSession.history.add(
                                            ChatMessage(
                                              role: 'assistant',
                                              content: "Hello! Let's learn some new words today: **$wordPreview**. I'll help you understand and practice these. Ready?",
                                            ),
                                          );
                                      }
                                      
                                      Navigator.push(
                                        itemContext,
                                        MaterialPageRoute(
                                          builder: (context) => ActiveWordSessionScreen(session: wordSession),
                                        ),
                                      );
                                    } else if (conversation.conversationType == 'error_practice') {
                                      final settings = conversationDetail.settings;
                                      final errorCount = settings['error_count'] as int? ?? 0;
                                      final focusAreas = (settings['focus_areas'] as List?)?.cast<String>() ?? [];
                                      
                                      Navigator.push(
                                        itemContext,
                                        MaterialPageRoute(
                                          builder: (context) => ActiveErrorPracticeScreen(
                                            conversationId: conversationDetail.id,
                                            errorCount: errorCount,
                                            focusAreas: focusAreas,
                                          ),
                                        ),
                                      );
                                    } else {
                                      // Fallback for old chats or other types
                                      Navigator.push(
                                        itemContext,
                                        MaterialPageRoute(
                                          builder: (context) => ActiveSessionScreen(
                                            initialConversation: Conversation(
                                              id: conversationDetail.id,
                                              title: conversationDetail.title,
                                              conversationType: conversationDetail.conversationType,
                                              settings: conversationDetail.settings,
                                              createdAt: conversationDetail.createdAt,
                                              updatedAt: conversationDetail.updatedAt,
                                              messageCount: conversationDetail.messageCount,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to open session: $e')),
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
