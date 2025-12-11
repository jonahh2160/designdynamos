import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:designdynamos/providers/tts_provider.dart';
import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:designdynamos/data/services/supabase_service.dart';
import 'package:designdynamos/features/auth/pages/login_page.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _announced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_announced) return;
    final tts = context.read<TtsProvider>();
    if (!tts.isEnabled) return;
    _announced = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) tts.speak('Settings screen');
    });
  }

  @override
  Widget build(BuildContext context) {
    final sections = [
      _SettingsSection(title: 'Account', children: [_DisplayNameTile()]),
      _SettingsSection(title: 'Accessibility', children: [_TtsToggleTile()]),
    ];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Semantics(
              header: true,
              label: 'Settings screen',
              child: Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
            ),
            const SizedBox(height: 40),
            ...sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: section,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

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

class _DisplayNameTile extends StatefulWidget {
  @override
  State<_DisplayNameTile> createState() => _DisplayNameTileState();
}

class _DisplayNameTileState extends State<_DisplayNameTile> {
  final _display_nameController = TextEditingController();
  final supabase = SupabaseService.client;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  Future<void> _getProfile() async {
    setState(() => _loading = true);
    try {
      final userId = supabase.auth.currentSession!.user.id;
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      _display_nameController.text = data['display_name'] ?? '';
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _updateProfile() async {
    setState(() => _loading = true);
    final updates = {
      'id': supabase.auth.currentUser!.id,
      'display_name': _display_nameController.text.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    try {
      await supabase.from('profiles').upsert(updates);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _display_nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextFormField(
            controller: _display_nameController,
            decoration: const InputDecoration(labelText: 'Display Name'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loading ? null : _updateProfile,
            child: Text(_loading ? 'Saving...' : 'Update Profile'),
          ),
        ],
      ),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
        ),
      ),
    );
  }
}
