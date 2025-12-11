import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:designdynamos/providers/tts_provider.dart';
import 'package:designdynamos/core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ),
            ),
            const SizedBox(height: 40),
            _SettingsSection(
              title: 'Accessibility',
              children: [
                _TtsToggleTile(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.taskCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _TtsToggleTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ttsProvider = context.watch<TtsProvider>();
    
    return MouseRegion(
      onEnter: (_) {
        // Announce toggle state when hovered
        final label = ttsProvider.isEnabled 
          ? 'Text to speech testing mode enabled, switch to disable' 
          : 'Text to speech testing mode disabled, switch to enable';
        ttsProvider.speak(label);
      },
      child: Semantics(
        label: ttsProvider.isEnabled 
          ? 'Text to speech testing mode enabled, switch to disable' 
          : 'Text to speech testing mode disabled, switch to enable',
        toggled: ttsProvider.isEnabled,
        child: SwitchListTile(
          title: const Text(
            'Text-to-Speech Test Mode',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Enable to hear screen reader announcements when hovering over elements',
            style: TextStyle(fontSize: 13),
          ),
          value: ttsProvider.isEnabled,
          onChanged: (_) => ttsProvider.toggleTts(),
          activeThumbColor: AppColors.accent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        ),
      ),
    );
  }
}
