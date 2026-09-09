import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/domain/diary_macro_profile.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_profile_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Footer for an expanded meal section displaying total macros, daily target
/// contribution percentages, and a macro emphasis evaluation chip.
class DiaryMealSectionFooter extends StatelessWidget {
  /// Creates the meal section footer.
  const DiaryMealSectionFooter({
    required this.section,
    this.macroTargets,
    super.key,
  });

  /// The meal section whose macro details are displayed.
  final DiaryMealSection section;

  /// Day macro targets used to calculate contribution percentages.
  final DiaryMacroTargets? macroTargets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = MetricAccentColors.of(context);
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    )..maximumFractionDigits = 1;
    final unit = l10n.caloriesUnitGram;
    final targets = macroTargets;

    final profile = DiaryMacroProfile.calculate(
      protein: section.totalProtein,
      carbs: section.totalCarbs,
      fat: section.totalFat,
    );

    final values = [
      (
        l10n.caloriesProteinShortLetter,
        section.totalProtein,
        targets?.protein,
        colors.protein,
      ),
      (
        l10n.caloriesCarbsShortLetter,
        section.totalCarbs,
        targets?.carbs,
        colors.carbs,
      ),
      (
        l10n.caloriesFatShortLetter,
        section.totalFat,
        targets?.fat,
        colors.fat,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.md,
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
                  if (target != null && target.isFinite && target > 0)
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
            padding: const EdgeInsets.only(top: AppSpacing.xs),
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
