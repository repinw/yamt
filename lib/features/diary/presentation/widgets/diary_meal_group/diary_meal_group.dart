import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_macro_summary.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_meal_entry_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_meal_icon.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Logged meal: heading with macro and kcal totals, then its entries.
class DiaryMealGroup extends StatelessWidget {
  /// Creates a diary meal group.
  const DiaryMealGroup({
    required this.section,
    required this.onTapEntry,
    super.key,
  });

  /// Meal section with at least one entry.
  final DiaryMealSection section;

  /// Called when an entry row is tapped.
  final ValueChanged<DiaryMealEntry> onTapEntry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return Column(
      key: DiaryMealsSectionKeys.mealGroup(section.mealType),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            DiaryMealIcon(mealType: section.mealType),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                section.mealType.localizedName(l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            DiaryMacroSummary(
              protein: section.totalProtein,
              carbs: section.totalCarbs,
              fat: section.totalFat,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                '${numberFormat.format(section.totalKcal.round())} '
                '${l10n.caloriesUnitKcal}',
                textAlign: TextAlign.end,
                maxLines: 1,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        for (final entry in section.entries)
          DiaryMealEntryTile(entry: entry, onTap: () => onTapEntry(entry)),
      ],
    );
  }
}
