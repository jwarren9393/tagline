import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ModelChipWrap extends StatelessWidget {
  const ModelChipWrap({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final label in labels)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.inkSoft,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.line),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: AppColors.text),
            ),
          ),
      ],
    );
  }
}
