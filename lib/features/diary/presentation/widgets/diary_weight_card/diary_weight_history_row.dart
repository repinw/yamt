import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/application/diary_activity_weight_service.dart';
import 'package:yamt/features/diary/presentation/diary_theme.dart';

/// Weight history row for the expanded diary weight details card.
class DiaryWeightHistoryRow extends StatelessWidget {
  /// Creates a weight history row.
  const DiaryWeightHistoryRow({
    required this.day,
    required this.dayLabel,
    required this.weightLabel,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  /// Weight day data.
  final DiaryWeightDayData day;

  /// Localized day label.
  final String dayLabel;

  /// Localized weight label.
  final String weightLabel;

  /// Called when the row is edited.
  final VoidCallback onEdit;

  /// Called when the row can be deleted.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accentColors = DiaryAccentColors.of(context);
    final hasWeight = day.weightKg != null;

    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.36),
      borderRadius: BorderRadius.circular(14),
      child: AppInkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                weightLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: hasWeight ? colors.onSurface : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                icon: Icon(
                  hasWeight ? Icons.edit_rounded : Icons.add_rounded,
                  color: accentColors.weight,
                  size: 16,
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.error,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
