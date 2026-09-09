import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_entry_nutrition.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_card/diary_meal_portion_formatter.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_card/diary_meal_section_footer.dart';
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
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (section.entries.isEmpty)
                DiaryExpandedEmptyMeal(mealType: section.mealType)
              else ...[
                for (final entry in section.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: DiaryExpandedMealEntry(
                      entry: entry,
                      onTap: () => onTapEntry(entry),
                    ),
                  ),
                Divider(
                  color: colors.outlineVariant.withValues(alpha: 0.3),
                  height: 1,
                ),
                const SizedBox(height: AppSpacing.sm),
                DiaryMealSectionFooter(
                  section: section,
                  macroTargets: macroTargets,
                ),
              ],
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

  /// Optional day macro targets retained for backwards compatibility.
  final DiaryMacroTargets? macroTargets;

  /// Entry to display.
  final DiaryMealEntry entry;

  /// Callback when entry is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: colors.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            child: Row(
              children: [
                MealThumb(entry: entry, compact: true),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
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
                          const SizedBox(width: AppSpacing.xs),
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
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: DiaryEntryNutrition(entry: entry),
                            ),
                          ),
                          if (portionText != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 120),
                              child: Text(
                                portionText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colors.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
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
