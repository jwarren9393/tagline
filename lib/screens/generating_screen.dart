import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/generation_result.dart';
import '../providers/generation_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/pass_progress.dart';

class GeneratingScreen extends StatelessWidget {
  const GeneratingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gen = context.watch<GenerationProvider>();
    final doneCount =
        gen.passes.where((p) => p.status == PassStatus.done).length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Multi-pass generation',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Scene → arc → draft → structure → anti-cliché → Suno polish → style. '
                'This is slower than one-shot on purpose.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '$doneCount / ${gen.passes.length} passes',
                style: const TextStyle(color: AppColors.amber),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: PassProgressList(passes: gen.passes),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
