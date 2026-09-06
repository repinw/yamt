import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_entry_nutrition.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_card/diary_meal_portion_formatter.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_media.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Expanded view of entries inside a meal card.
class DiaryExpandedMealBody extends StatelessWidget {
  /// Creates the expanded meal body.
  const DiaryExpandedMealBody({
    required this.section,
    required this.onTapEntry,
    this.macroTargets,
    super.key,
  });

  /// Targets for displaying portion daily contributions.
  final DiaryMacroTargets? macroTargets;

  /// The meal section displayed.
  final DiaryMealSection section;

  /// Callback when an entry is tapped.
  final ValueChanged<DiaryMealEntry> onTapEntry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Column(
            children: [
              if (section.entries.isEmpty)
                DiaryExpandedEmptyMeal(mealType: section.mealType)
              else
                for (final entry in section.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: DiaryExpandedMealEntry(
                      macroTargets: macroTargets,
                      entry: entry,
                      onTap: () => onTapEntry(entry),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder text when an expanded meal has no logged entries.
class DiaryExpandedEmptyMeal extends StatelessWidget {
  /// Creates the empty meal message.
  const DiaryExpandedEmptyMeal({required this.mealType, super.key});

  /// The meal type.
  final MealType mealType;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        AppLocalizations.of(context)!.diaryMealsEmpty,
        key: DiaryMealsSectionKeys.expandedEmpty(mealType),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Full detail entry card rendered in expanded meal body.
class DiaryExpandedMealEntry extends StatelessWidget {
  /// Creates the expanded meal entry view.
  const DiaryExpandedMealEntry({
    required this.entry,
    required this.onTap,
    this.macroTargets,
    super.key,
  });

  /// Day macro targets for contribution percentage breakdown.
  final DiaryMacroTargets? macroTargets;

  /// Entry to display.
  final DiaryMealEntry entry;

  /// Callback when entry is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final l10n = AppLocalizations.of(context)!;
    final accentColors = MetricAccentColors.of(context);
    final portionText = formatDiaryMealPortionLabel(context, entry);

    return Material(
      color: Colors.transparent,
      child: AppInkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: AppEditorialSurfaces.section(colors),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppEditorialSurfaces.solidCardBorder(colors),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                MealThumb(entry: entry),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              entry.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${numberFormat.format(
                                  entry.totalKcal.round(),
                                )} ${l10n.caloriesUnitKcal}',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: accentColors.meal,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              if (portionText != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  portionText,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      DiaryEntryNutrition(entry: entry, targets: macroTargets),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
