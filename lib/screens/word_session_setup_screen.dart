import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schemas.dart';
import '../services/api_service.dart';
import 'active_word_session_screen.dart';

class WordSessionSetupScreen extends StatefulWidget {
  const WordSessionSetupScreen({super.key});

  @override
  State<WordSessionSetupScreen> createState() => _WordSessionSetupScreenState();
}

class _WordSessionSetupScreenState extends State<WordSessionSetupScreen> {
  CefrLevel _selectedLevel = CefrLevel.B1;
  String _selectedMode = 'daily'; // 'daily' or 'random'
  int _wordCount = 3;
  bool _isLoading = false;
  List<String>? _previewWords;

  @override
  void initState() {
    super.initState();
    // Delaying the call to use context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreviewWords();
    });
  }

  Future<void> _loadPreviewWords() async {
    // Use ApiService from Provider
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final response = await apiService.getDailyWords(_selectedLevel, count: _wordCount);
      if (mounted) {
        setState(() {
          _previewWords = response.words;
        });
      }
    } catch (e) {
      print('🔴 Preview words error: $e');
    }
  }

  Future<void> _startWordSession() async {
    setState(() => _isLoading = true);
    // Use ApiService from Provider
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final request = WordSessionStartRequest(
        mode: _selectedMode,
        level: _selectedLevel,
        count: _wordCount,
      );

      final session = await apiService.startWordSession(request);

      // Fix for empty sessions (e.g. reused sessions without greetings):
      if (session.history.isEmpty) {
        final words = session.settings.words;
        final wordPreview = words.length > 5 
            ? "${words.take(5).join(', ')}... (+${words.length - 5} more)"
            : words.join(', ');
            
        session.history.add(
          ChatMessage(
            role: 'assistant',
            content: "Hello! Let's learn some new words today: **$wordPreview**. I'll help you understand and practice these. Ready?",
          ),
        );
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveWordSessionScreen(
              session: session,
            ),
          ),
        );
      }
    } catch (e) {
      print('🔴 Word session start error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start word session: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word Learning')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Selection (Daily vs Random)
            _buildSectionHeader('Learning Mode'),
            _buildModeSelector(),
            const SizedBox(height: 24),

            // Level Selection
            _buildSectionHeader('Target Level'),
            _buildDropdown<CefrLevel>(
              value: _selectedLevel,
              items: CefrLevel.values,
              labelBuilder: (e) => e.label,
              onChanged: (v) {
                setState(() => _selectedLevel = v!);
                _loadPreviewWords();
              },
            ),
            const SizedBox(height: 24),

            // Word Count Selection
            _buildSectionHeader('Number of Words'),
            _buildWordCountSelector(),
            const SizedBox(height: 24),

            // Preview Card (only for daily mode)
            if (_selectedMode == 'daily' && _previewWords != null)
              _buildPreviewCard(),

            const SizedBox(height: 32),

            // Start Button
            ElevatedButton(
              onPressed: _isLoading ? null : _startWordSession,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Start Learning Words',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeOption(
              'Daily',
              'Same words for everyone today',
              Icons.calendar_today_rounded,
              'daily',
            ),
          ),
          Container(width: 1, height: 60, color: Colors.grey.shade200),
          Expanded(
            child: _buildModeOption(
              'Random',
              'Unique selection for you',
              Icons.shuffle_rounded,
              'random',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(String title, String subtitle, IconData icon, String mode) {
    final isSelected = _selectedMode == mode;
    
    return InkWell(
      onTap: () {
        setState(() => _selectedMode = mode);
        if (mode == 'daily') _loadPreviewWords();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordCountSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Words per session:',
            style: TextStyle(fontSize: 16),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _wordCount > 1
                    ? () {
                        setState(() => _wordCount--);
                        if (_selectedMode == 'daily') _loadPreviewWords();
                      }
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_wordCount',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: _wordCount < 10
                    ? () {
                        setState(() => _wordCount++);
                        if (_selectedMode == 'daily') _loadPreviewWords();
                      }
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview_rounded,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "Today's Words",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _previewWords!.map((word) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  word,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(labelBuilder(item)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
