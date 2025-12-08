import 'package:flutter/material.dart';

/// A reusable AppBar action for the "check errors" button with loading state.
class CheckErrorsAction extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const CheckErrorsAction({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.only(right: 16.0),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.plagiarism_outlined),
      tooltip: 'Analyze My Messages',
      onPressed: onPressed,
    );
  }
}
