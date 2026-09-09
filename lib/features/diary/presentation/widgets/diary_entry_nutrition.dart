import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/domain/diary_macro_profile.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_profile_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Labeled portion values and, when expanded, their daily contributions.
class DiaryEntryNutrition extends StatelessWidget {
  /// Creates a portion nutrition summary.
  const DiaryEntryNutrition({required this.entry, this.targets, super.key});

  /// Recorded portion, never per-100 values.
  final DiaryMealEntry entry;

  /// Set in expanded entries using the dashboard's resolved day goals.
  final DiaryMacroTargets? targets;

  @override
  Widget build(BuildContext context) {
    final targets = this.targets;
    if (targets == null) {
      return _CollapsedEntryNutrition(entry: entry);
    }
    return _ExpandedEntryNutrition(entry: entry, targets: targets);
  }
}

class _CollapsedEntryNutrition extends StatelessWidget {
  const _CollapsedEntryNutrition({required this.entry});

  final DiaryMealEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = MetricAccentColors.of(context);
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    )..maximumFractionDigits = 1;
    final unit = l10n.caloriesUnitGram;
    final separatorStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.outlineVariant,
      fontWeight: FontWeight.w700,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MacroColumn(
          text: '${l10n.caloriesProteinShortLetter} '
              '${format.format(entry.totalProtein)}$unit',
          color: colors.protein,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text('·', style: separatorStyle),
        const SizedBox(width: AppSpacing.xxs),
        _MacroColumn(
          text: '${l10n.caloriesCarbsShortLetter} '
              '${format.format(entry.totalCarbs)}$unit',
          color: colors.carbs,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text('·', style: separatorStyle),
        const SizedBox(width: AppSpacing.xxs),
        _MacroColumn(
          text: '${l10n.caloriesFatShortLetter} '
              '${format.format(entry.totalFat)}$unit',
          color: colors.fat,
        ),
      ],
    );
  }
}

class _ExpandedEntryNutrition extends StatelessWidget {
  const _ExpandedEntryNutrition({
    required this.entry,
    required this.targets,
  });

  final DiaryMealEntry entry;
  final DiaryMacroTargets targets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = MetricAccentColors.of(context);
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    )..maximumFractionDigits = 1;
    final unit = l10n.caloriesUnitGram;

    final profile = DiaryMacroProfile.calculate(
      protein: entry.totalProtein,
      carbs: entry.totalCarbs,
      fat: entry.totalFat,
    );
    final values = [
      (
        l10n.caloriesProteinShortLetter,
        entry.totalProtein,
        targets.protein,
        colors.protein,
      ),
      (
        l10n.caloriesCarbsShortLetter,
        entry.totalCarbs,
        targets.carbs,
        colors.carbs,
      ),
      (
        l10n.caloriesFatShortLetter,
        entry.totalFat,
        targets.fat,
        colors.fat,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final (label, value, target, color) in values)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$label ${format.format(value)}$unit',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (target.isFinite && target > 0)
                    Text(
                      l10n.diaryMacroDailyContribution(
                        format.format(value / target * 100),
                      ),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
          ],
        ),
        if (profile != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: ActionChip(
              visualDensity: VisualDensity.compact,
              label: Text(diaryMacroEmphasisLabel(l10n, profile.emphasis)),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => DiaryMacroProfileDialog(
                  profile: profile,
                  numberFormat: format,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MacroColumn extends StatelessWidget {
  const _MacroColumn({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );
    return SizedBox(
      width: 48,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: RichText(
          text: TextSpan(
            text: text,
            style: labelStyle?.copyWith(color: color),
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}
