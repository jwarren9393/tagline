import 'package:flutter/material.dart';

import '../models/generation_result.dart';
import '../theme/app_theme.dart';

class FeedbackPanel extends StatelessWidget {
  const FeedbackPanel({super.key, required this.feedback});

  final LyricFeedback feedback;

  @override
  Widget build(BuildContext context) {
    if (!feedback.hasIssues && feedback.sectionSummaries.isEmpty) {
      return const SizedBox.shrink();
    }

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
          Text(
            'Quality feedback',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Local heuristics — use as a guide, not a hard rule.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          if (feedback.clicheHits.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Possible clichés',
              style: TextStyle(
                color: AppColors.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            ...feedback.clicheHits.take(8).map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'L${h.lineIndex}: “${h.term}” (${h.familyLabel}) — ${h.line}',
                      style: const TextStyle(fontSize: 12.5, height: 1.35),
                    ),
                  ),
                ),
          ],
          if (feedback.syllableNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Syllable notes',
              style: TextStyle(
                color: AppColors.mint,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            ...feedback.syllableNotes.map(
              (n) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(n, style: const TextStyle(fontSize: 12.5)),
              ),
            ),
          ],
          if (feedback.sectionSummaries.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Section syllable ranges',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: feedback.sectionSummaries.map((s) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.inkSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: s.isInconsistent
                          ? AppColors.amber.withValues(alpha: 0.6)
                          : AppColors.line,
                    ),
                  ),
                  child: Text(
                    '${s.tag}  ${s.min}–${s.max}',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
