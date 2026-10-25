import 'package:flutter/material.dart';

import '../models/generation_session.dart';
import '../theme/app_theme.dart';

class EvalPanel extends StatelessWidget {
  const EvalPanel({
    super.key,
    required this.summary,
    this.onReevaluate,
  });

  final EvalSummary summary;
  final VoidCallback? onReevaluate;

  @override
  Widget build(BuildContext context) {
    final color = summary.ratio >= 0.85
        ? AppColors.mint
        : summary.ratio >= 0.65
            ? AppColors.amber
            : AppColors.danger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inkElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Prompt eval · ${summary.label}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (onReevaluate != null)
                TextButton(
                  onPressed: onReevaluate,
                  child: const Text('Re-run'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Local harness vs Suno formatting + anti-cliché rules. '
            'Use before pasting into Suno.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: summary.ratio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.inkSoft,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${summary.score} / ${summary.maxScore}',
            style: TextStyle(color: color, fontSize: 12),
          ),
          const SizedBox(height: 10),
          ...summary.checks.map((c) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    c.passed ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: c.passed ? AppColors.mint : AppColors.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: c.label,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (c.detail.isNotEmpty)
                            TextSpan(
                              text: ' — ${c.detail}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    '+${c.weight}',
                    style: TextStyle(
                      fontSize: 11,
                      color: c.passed
                          ? AppColors.mint
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
