import 'package:flutter/material.dart';

import '../models/generation_result.dart';
import '../theme/app_theme.dart';

class PassProgressList extends StatelessWidget {
  const PassProgressList({super.key, required this.passes});

  final List<PipelinePass> passes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final pass in passes) ...[
          _PassRow(pass: pass),
          if (pass != passes.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _PassRow extends StatelessWidget {
  const _PassRow({required this.pass});
  final PipelinePass pass;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (pass.status) {
      PassStatus.pending => (Icons.circle_outlined, AppColors.textMuted),
      PassStatus.running => (Icons.autorenew_rounded, AppColors.amber),
      PassStatus.done => (Icons.check_circle_rounded, AppColors.mint),
      PassStatus.failed => (Icons.error_rounded, AppColors.danger),
      PassStatus.skipped => (Icons.remove_circle_outline, AppColors.textMuted),
    };

    final showStream = pass.output.trim().isNotEmpty &&
        (pass.status == PassStatus.running || pass.status == PassStatus.done);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.inkElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: pass.status == PassStatus.running
              ? AppColors.amber.withValues(alpha: 0.5)
              : AppColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pass.status == PassStatus.running)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pass.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      pass.error ?? pass.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: pass.error != null
                            ? AppColors.danger
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showStream) ...[
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 140),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.inkSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.line),
              ),
              child: SingleChildScrollView(
                reverse: pass.status == PassStatus.running,
                child: SelectableText(
                  _tail(pass.output, 1200),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    height: 1.35,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _tail(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    return '…${text.substring(text.length - maxChars)}';
  }
}
