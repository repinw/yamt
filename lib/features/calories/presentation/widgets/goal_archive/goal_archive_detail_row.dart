import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// A label/value row used by a goal archive card.
class GoalArchiveDetailRow extends StatelessWidget {
  /// Creates a detail row.
  const GoalArchiveDetailRow({
    required this.label,
    required this.value,
    super.key,
  });

  /// Localized detail label.
  final String label;

  /// Formatted detail value.
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
