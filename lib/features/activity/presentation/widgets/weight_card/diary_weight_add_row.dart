import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Add row for the expanded diary weight details card.
class DiaryWeightAddRow extends StatelessWidget {
  /// Creates a weight add row.
  const DiaryWeightAddRow({required this.onPressed, super.key});

  /// Called when the row is pressed.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final accentColors = MetricAccentColors.of(context);

    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.24),
      borderRadius: BorderRadius.circular(14),
      child: AppInkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accentColors.weight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: accentColors.weight,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.diaryWeightAddAction,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
