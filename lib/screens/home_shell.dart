import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/generation_provider.dart';
import '../theme/app_theme.dart';
import 'generating_screen.dart';
import 'idea_intake_screen.dart';
import 'results_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final view = context.watch<GenerationProvider>().view;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.amber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Tagline'),
            if (view != AppView.idea) ...[
              const SizedBox(width: 12),
              Text(
                view == AppView.generating ? 'Generating' : 'Output',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.ink,
              Color(0xFF151A22),
              Color(0xFF1A1714),
            ],
          ),
        ),
        child: switch (view) {
          AppView.idea => const IdeaIntakeScreen(),
          AppView.generating => const GeneratingScreen(),
          AppView.results => const ResultsScreen(),
        },
      ),
    );
  }
}
