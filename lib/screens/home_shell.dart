import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/generation_provider.dart';
import '../theme/app_theme.dart';
import 'generating_screen.dart';
import 'history_screen.dart';
import 'idea_intake_screen.dart';
import 'results_screen.dart';
import 'settings_hub_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final gen = context.watch<GenerationProvider>();
    final view = gen.view;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.ink,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: true,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
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
              tooltip: 'History',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
              icon: const Icon(Icons.history),
            ),
            IconButton(
              tooltip: 'Settings',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsHubScreen()),
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
          // Keep content clear of gesture/nav bars on phones.
          child: SafeArea(
            top: false,
            bottom: true,
            minimum: EdgeInsets.only(bottom: bottomInset > 0 ? 4 : 8),
            child: switch (view) {
              AppView.idea => IdeaIntakeScreen(
                  key: ValueKey('idea-${gen.ideaEditToken}'),
                ),
              AppView.generating => const GeneratingScreen(),
              AppView.results => const ResultsScreen(),
            },
          ),
        ),
      ),
    );
  }
}
