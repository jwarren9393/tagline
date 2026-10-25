import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/secure_settings.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _keyController;
  late final TextEditingController _modelController;
  bool _obscure = true;

  static const _suggestedModels = [
    'openai/gpt-4o',
    'openai/gpt-4.1',
    'anthropic/claude-sonnet-4-5',
    'anthropic/claude-opus-4',
    'google/gemini-2.5-pro',
    'deepseek/deepseek-chat',
  ];

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _keyController = TextEditingController();
    _modelController = TextEditingController(text: settings.model);
  }

  @override
  void dispose() {
    _keyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'NanoGPT',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tagline uses your NanoGPT subscription/API for all LLM calls. '
            'The key is stored with flutter_secure_storage and never logged.',
            style: TextStyle(color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _keyController,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: settings.hasApiKey
                  ? 'Replace API key'
                  : 'NanoGPT API key',
              hintText: 'sk-nano-…',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                onPressed: () async {
                  await settings.saveApiKey(_keyController.text);
                  _keyController.clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('API key saved')),
                    );
                  }
                },
                child: const Text('Save key'),
              ),
              const SizedBox(width: 12),
              if (settings.hasApiKey)
                OutlinedButton(
                  onPressed: () async {
                    await settings.clearApiKey();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('API key cleared')),
                      );
                    }
                  },
                  child: const Text('Clear'),
                ),
              const Spacer(),
              Icon(
                settings.hasApiKey
                    ? Icons.verified_user_outlined
                    : Icons.warning_amber_rounded,
                color: settings.hasApiKey ? AppColors.mint : AppColors.amber,
              ),
              const SizedBox(width: 8),
              Text(
                settings.hasApiKey ? 'Key on file' : 'No key',
                style: TextStyle(
                  color:
                      settings.hasApiKey ? AppColors.mint : AppColors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Use subscription endpoint'),
            subtitle: Text(
              settings.useSubscription
                  ? SecureSettings.subscriptionBaseUrl
                  : SecureSettings.defaultBaseUrl,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            value: settings.useSubscription,
            activeThumbColor: AppColors.amber,
            onChanged: (v) => settings.saveUseSubscription(v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: 'Model ID',
              hintText: 'openai/gpt-4o',
              helperText: 'Any NanoGPT text model ID from their catalog',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedModels.map((m) {
              final selected = settings.model == m;
              return FilterChip(
                label: Text(m.split('/').last),
                selected: selected,
                onSelected: (_) {
                  _modelController.text = m;
                  settings.saveModel(m);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonal(
              onPressed: () async {
                await settings.saveModel(_modelController.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Model saved')),
                  );
                }
              },
              child: const Text('Save model'),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tagline is a native pre-production tool for Suno AI. '
            'It turns rough song ideas into Suno-ready lyrics and style prompts '
            'using a multi-pass anti-cliché workflow.',
            style: TextStyle(color: AppColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
