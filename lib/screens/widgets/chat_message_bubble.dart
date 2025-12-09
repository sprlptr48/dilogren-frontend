import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ChatMessageBubble extends StatelessWidget {
  final String role;
  final String content;
  final bool isStreaming;
  final String? loadingStatus;

  const ChatMessageBubble({
    super.key,
    required this.role,
    required this.content,
    this.isStreaming = false,
    this.loadingStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.userBubble : AppTheme.aiBubble,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isUser ? Radius.zero : null,
            topLeft: !isUser ? Radius.zero : null,
          ),
          boxShadow: [
            if (!isUser)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (content.isNotEmpty)
              Text(
                content,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            if (isStreaming)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    if ((content).isEmpty && loadingStatus != null)
                      Text(
                        loadingStatus!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
