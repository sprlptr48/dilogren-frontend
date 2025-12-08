import 'package:flutter/material.dart';

/// Shows a loading dialog, runs an async task, then navigates on success or shows error.
/// Returns the result of the task, or null if it failed.
Future<T?> runWithLoadingDialog<T>({
  required BuildContext context,
  required Future<T> Function() task,
  required Widget Function(T result) screenBuilder,
  String? errorPrefix,
}) async {
  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final result = await task();

    if (context.mounted) {
      Navigator.pop(context); // Dismiss loading dialog
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screenBuilder(result)),
      );
    }
    return result;
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${errorPrefix ?? 'Error'}: ${e.toString()}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return null;
  }
}
