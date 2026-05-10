import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Icon and label pair used in the calorie entry overview.
class CalorieEntryMetaItem extends StatelessWidget {
  /// Creates a compact metadata item.
  const CalorieEntryMetaItem({
    required this.icon,
    required this.label,
    this.valueKey,
    super.key,
  });

  /// Leading icon.
  final IconData icon;

  /// Metadata label.
  final String label;

  /// Optional key for tests.
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: colors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            key: valueKey,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
