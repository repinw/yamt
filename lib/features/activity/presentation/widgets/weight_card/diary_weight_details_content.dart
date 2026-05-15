import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_add_row.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_history_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Content of the expanded diary weight details card.
class DiaryWeightDetailsContent extends StatelessWidget {
  /// Creates weight details content.
  const DiaryWeightDetailsContent({
    required this.days,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  /// Weight days to render, newest first.
  final List<DiaryWeightDayData> days;

  /// Called to add weight for the selected day.
  final VoidCallback onAdd;

  /// Called when a weight row is edited.
  final ValueChanged<DiaryWeightDayData> onEdit;

  /// Called when a weight row is deleted.
  final ValueChanged<DiaryWeightDayData> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.MMMEd(locale);
    final accentColors = MetricAccentColors.of(context);
    final weightFormat = NumberFormat('0.#', locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_down_rounded,
              color: accentColors.weight,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.diaryWeightTitle.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        DiaryWeightAddRow(onPressed: onAdd),
        const SizedBox(height: AppSpacing.sm),
        Divider(color: colors.outlineVariant, height: 1),
        const SizedBox(height: AppSpacing.sm),
        if (days.isEmpty)
          Text(
            l10n.diaryWeightEmpty,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          )
        else
          for (final day in days) ...[
            DiaryWeightHistoryRow(
              day: day,
              dayLabel: dateFormat.format(day.day),
              weightLabel: day.weightKg == null
                  ? '—'
                  : '${weightFormat.format(day.weightKg)} '
                        '${l10n.caloriesUnitKg}',
              onEdit: () => onEdit(day),
              onDelete: day.canDeleteWeight ? () => onDelete(day) : null,
            ),
            if (day != days.last) ...[
              const SizedBox(height: AppSpacing.sm),
              Divider(color: colors.outlineVariant, height: 1),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
      ],
    );
  }
}
