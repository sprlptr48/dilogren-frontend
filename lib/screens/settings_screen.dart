import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tts_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<TtsService>(
        builder: (context, tts, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Voice Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
               SwitchListTile(
                    title: const Text('Enable Auto Play'),
                    subtitle: const Text('Automatically speak new messages in chat'),
                    value: tts.autoPlay,
                    onChanged: (val) => tts.updateSettings(newAutoPlay: val),
                  ),
              const Divider(),
              const Text(
                'Voice Selection',
                style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              RadioListTile<bool>(
                title: const Text('Voice A (Female)'),
                subtitle: const Text('British Accent'),
                value: false,
                groupValue: tts.useVoiceB,
                onChanged: (val) {
                  if (val != null) tts.updateSettings(newUseVoiceB: val);
                },
              ),
              RadioListTile<bool>(
                title: const Text('Voice B (Male)'),
                subtitle: const Text('British Accent'),
                value: true,
                groupValue: tts.useVoiceB,
                onChanged: (val) {
                  if (val != null) tts.updateSettings(newUseVoiceB: val);
                },
              ),
              const SizedBox(height: 20),
              // Helper to test voice
               Center(
                 child: OutlinedButton.icon(
                  onPressed: () => tts.speak("Hello! I am your AI language companion. How can I help you today?"),
                  icon: const Icon(Icons.volume_up),
                  label: const Text("Test Current Voice"),
                           ),
               ),
            ],
          );
        },
      ),
    );
  }
}
