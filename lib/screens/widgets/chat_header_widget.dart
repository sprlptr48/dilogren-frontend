import 'package:flutter/material.dart';

class ChatHeaderWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color primaryColor;
  final List<String> items;
  final Widget Function(BuildContext, String) itemBuilder;

  const ChatHeaderWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.primaryColor,
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.15),
            primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) => itemBuilder(context, item)).toList(),
          ),
        ],
      ),
    );
  }
}
