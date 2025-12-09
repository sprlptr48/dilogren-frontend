import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isListening;
  final bool isStreaming;
  final bool sttAvailable;
  final bool isSttSupported;
  final Animation<double> micAnimation;
  final VoidCallback onMicPressed;
  final VoidCallback onSendPressed;
  final String hintText;

  const ChatInputArea({
    super.key,
    required this.controller,
    required this.isListening,
    this.isStreaming = false,
    this.sttAvailable = false,
    this.isSttSupported = true,
    required this.micAnimation,
    required this.onMicPressed,
    required this.onSendPressed,
    this.hintText = 'Type a message...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ScaleTransition(
            scale: micAnimation,
            child: IconButton(
              icon: Icon(isListening ? Icons.mic_off : Icons.mic),
              color: isListening ? AppTheme.error : AppTheme.primary,
              onPressed: (sttAvailable && isSttSupported) ? onMicPressed : null,
              tooltip: isSttSupported 
                  ? 'Use voice input' 
                  : 'Voice input not available on this platform',
            ),
          ),
          Expanded(
            child: Tooltip(
              message: isListening ? 'Voice input is active' : '',
              child: TextField(
                controller: controller,
                enabled: !isListening,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: isListening ? 'Listening...' : hintText,
                  filled: true,
                  fillColor: isListening 
                      ? Colors.grey.shade200 
                      : AppTheme.inputBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, 
                    vertical: 10
                  ),
                ),
                onSubmitted: (_) => onSendPressed(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: (isStreaming || isListening) ? null : onSendPressed,
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
