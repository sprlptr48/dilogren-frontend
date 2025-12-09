import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schemas.dart';
import '../services/api_service.dart';

class ErrorStatsScreen extends StatefulWidget {
  const ErrorStatsScreen({super.key});

  @override
  State<ErrorStatsScreen> createState() => _ErrorStatsScreenState();
}

class _ErrorStatsScreenState extends State<ErrorStatsScreen> {
  ErrorStatsResponse? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final stats = await apiService.getErrorStats();

      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load stats: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getIconForErrorType(String type) {
    switch (type.toLowerCase()) {
      case 'grammar':
        return Icons.text_fields_rounded;
      case 'spelling':
        return Icons.spellcheck_rounded;
      case 'vocabulary':
        return Icons.book_rounded;
      case 'punctuation':
        return Icons.format_quote_rounded;
      case 'syntax':
        return Icons.code_rounded;
      default:
        return Icons.error_outline_rounded;
    }
  }

  Color _getColorForErrorType(String type) {
    switch (type.toLowerCase()) {
      case 'grammar':
        return Colors.blue;
      case 'spelling':
        return Colors.red;
      case 'vocabulary':
        return Colors.green;
      case 'punctuation':
        return Colors.purple;
      case 'syntax':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? const Center(child: Text('Failed to load statistics'))
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Total Errors Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  size: 48,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '${_stats!.totalErrors}',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Total Errors Tracked',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Errors by Type
                        if (_stats!.errorsByType.isNotEmpty) ...[
                          const Text(
                            'Errors by Type',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._stats!.errorsByType.map((errorType) {
                            final percentage = _stats!.totalErrors > 0
                                ? (errorType.count / _stats!.totalErrors * 100).toStringAsFixed(1)
                                : '0.0';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: _getColorForErrorType(errorType.errorType).withValues(alpha: 0.2),
                                      child: Icon(
                                        _getIconForErrorType(errorType.errorType),
                                        color: _getColorForErrorType(errorType.errorType),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            errorType.errorType.toUpperCase(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          LinearProgressIndicator(
                                            value: _stats!.totalErrors > 0
                                                ? errorType.count / _stats!.totalErrors
                                                : 0.0,
                                            backgroundColor: Colors.grey[200],
                                            valueColor: AlwaysStoppedAnimation(
                                              _getColorForErrorType(errorType.errorType),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${errorType.count}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '$percentage%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],

                        const SizedBox(height: 24),

                        // Most Recent Level Assessment
                        if (_stats!.mostRecentLevel != null) ...[
                          const Text(
                            'Most Recent Assessment',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _stats!.mostRecentLevel!.level,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Chip(
                                        label: Text('${_stats!.mostRecentLevel!.confidence} Confidence'),
                                        backgroundColor: Colors.green.withValues(alpha: 0.2),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Assessment Reasoning',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _stats!.mostRecentLevel!.reasoning,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        if (_stats!.totalErrors == 0)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No errors tracked yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Start checking your text to see statistics',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
