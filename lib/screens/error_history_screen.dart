import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schemas.dart';
import '../services/api_service.dart';

class ErrorHistoryScreen extends StatefulWidget {
  const ErrorHistoryScreen({super.key});

  @override
  State<ErrorHistoryScreen> createState() => _ErrorHistoryScreenState();
}

class _ErrorHistoryScreenState extends State<ErrorHistoryScreen> {
  late Future<ErrorHistoryResponse> _historyFuture;

  @override
  void initState() {
    super.initState();
    final apiService = Provider.of<ApiService>(context, listen: false);
    _historyFuture = apiService.getErrorHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error History'),
      ),
      body: FutureBuilder<ErrorHistoryResponse>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.errors.isEmpty) {
            return const Center(child: Text('No history found.'));
          }

          final history = snapshot.data!;
          return ListView.builder(
            itemCount: history.errors.length,
            itemBuilder: (context, index) {
              final error = history.errors[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        error.originalText,
                        style: const TextStyle(
                          color: Colors.red,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        error.correctedText,
                        style: const TextStyle(color: Colors.green),
                      ),
                      const Divider(height: 20),
                      Text(
                        error.explanation ?? 'No explanation provided.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(label: Text(error.errorType)),
                          Text(
                            '${error.createdAt.toLocal()}'.split(' ')[0],
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
