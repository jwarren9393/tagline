import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_paths.dart';
import '../theme/app_theme.dart';
import 'api_settings_screen.dart';

/// Top-level Settings: submenus for API and future sections.
class SettingsHubScreen extends StatelessWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Configure Tagline',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w400,
                  ),
            ),
            const SizedBox(height: 16),
            _SettingsTile(
              icon: Icons.key_outlined,
              title: 'API & models',
              subtitle:
                  'NanoGPT key, subscription toggle, catalog, credits, favorites',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ApiSettingsScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            const _SettingsTile(
              icon: Icons.music_note_outlined,
              title: 'Inspiration DNA',
              subtitle:
                  'Lives on New Idea — MB + Genius + Deezer BPM → abstract formula, never a copy',
              enabled: false,
            ),
            if (AppPaths.isInitialized) ...[
              const SizedBox(height: 10),
              _DataFolderTile(path: AppPaths.instance.root.path),
            ],
          ],
        ),
      ),
    );
  }
}

class _DataFolderTile extends StatelessWidget {
  const _DataFolderTile({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inkElevated,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        key: const Key('settings_data_folder'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.folder_outlined, color: AppColors.amber),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Data folder',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    path,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Copy path',
              icon: const Icon(Icons.copy_outlined, color: AppColors.textMuted),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: path));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data folder path copied')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inkElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: enabled ? AppColors.amber : AppColors.textMuted,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: enabled ? AppColors.text : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                const Icon(Icons.chevron_right, color: AppColors.textMuted)
              else
                const Text(
                  'On intake',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
