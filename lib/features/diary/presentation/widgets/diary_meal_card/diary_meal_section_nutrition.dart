import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Macro totals summary row for a meal section header.
class DiaryMealSectionNutrition extends StatelessWidget {
  /// Creates the meal section nutrition text.
  const DiaryMealSectionNutrition({required this.section, super.key});

  /// The meal section whose macros are displayed.
  final DiaryMealSection section;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = MetricAccentColors.of(context);
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    )..maximumFractionDigits = 1;
    final unit = l10n.caloriesUnitGram;
    final pLetter = l10n.caloriesProteinShortLetter;
    final cLetter = l10n.caloriesCarbsShortLetter;
    final fLetter = l10n.caloriesFatShortLetter;

    final separatorStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.outlineVariant,
      fontWeight: FontWeight.w700,
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$pLetter ${format.format(section.totalProtein)}$unit',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.protein,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: ' · ', style: separatorStyle),
            TextSpan(
              text: '$cLetter ${format.format(section.totalCarbs)}$unit',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.carbs,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: ' · ', style: separatorStyle),
            TextSpan(
              text: '$fLetter ${format.format(section.totalFat)}$unit',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.fat,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        maxLines: 1,
      ),
    );
  }
}
