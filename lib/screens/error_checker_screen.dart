import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schemas.dart';
import '../services/api_service.dart';

class ErrorCheckerScreen extends StatefulWidget {
  const ErrorCheckerScreen({super.key});

  @override
  State<ErrorCheckerScreen> createState() => _ErrorCheckerScreenState();
}

class _ErrorCheckerScreenState extends State<ErrorCheckerScreen> {
  final _textController = TextEditingController();
  bool _isLoading = false;
  ErrorCheckResponse? _response;
  String? _errorMessage;

  Future<void> _checkText() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _response = null;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final request = ErrorCheckRequest(text: _textController.text.trim());
      final response = await apiService.checkErrors(request);
      setState(() {
        _response = response;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Checker'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Enter text to check for errors...',
                border: OutlineInputBorder(),
              ),
              maxLines: 8,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkText,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Check Text'),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Center(
                child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)),
              ),
            if (_response != null)
              _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_response!.errors.isEmpty) {
      return const Center(
        child: Text('No errors found! Great job!', style: TextStyle(fontSize: 16, color: Colors.green)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_response!.levelAssessment != null) ...[
          _buildAssessmentCard(_response!.levelAssessment!),
          const SizedBox(height: 16),
        ],
        Text(
          '${_response!.errorCount} Errors Found:',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ..._response!.errors.map((error) => _buildErrorCard(error)),
      ],
    );
  }
  
  Widget _buildAssessmentCard(LevelAssessment assessment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Level Assessment', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Estimated Level: ${assessment.level} (${assessment.confidence})'),
            const SizedBox(height: 4),
            Text('Reasoning: ${assessment.reasoning}'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorCard(ErrorDetail error) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Original:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700),
            ),
            Text(
              error.original,
              style: const TextStyle(decoration: TextDecoration.lineThrough),
            ),
            const SizedBox(height: 8),
            Text(
              'Correction:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700),
            ),
            Text(error.corrected),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Explanation:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(error.explanation),
            const SizedBox(height: 8),
            Chip(label: Text(error.errorType)),
          ],
        ),
      ),
    );
  }
}
