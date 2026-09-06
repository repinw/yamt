import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_entry_nutrition.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_card/diary_meal_portion_formatter.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_media.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Collapsed view of entries inside a meal card.
class DiaryCollapsedMealBody extends StatelessWidget {
  /// Creates the collapsed meal body.
  const DiaryCollapsedMealBody({
    required this.section,
    required this.onTapEntry,
    super.key,
  });

  /// The meal section displayed.
  final DiaryMealSection section;

  /// Callback when an entry is tapped.
  final ValueChanged<DiaryMealEntry> onTapEntry;

  @override
  Widget build(BuildContext context) {
    if (section.entries.isEmpty) {
      return SizedBox.shrink(
        key: DiaryMealsSectionKeys.collapsedEmpty(section.mealType),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        right: AppSpacing.xs,
      ),
      child: Column(
        children: [
          for (final entry in section.entries)
            DiaryCollapsedMealEntryRow(
              entry: entry,
              onTap: () => onTapEntry(entry),
            ),
        ],
      ),
    );
  }
}

/// A compact entry row rendered in collapsed state.
class DiaryCollapsedMealEntryRow extends StatelessWidget {
  /// Creates a compact entry row.
  const DiaryCollapsedMealEntryRow({
    required this.entry,
    required this.onTap,
    super.key,
  });

  /// Entry rendered in the row.
  final DiaryMealEntry entry;

  /// Callback when row is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final l10n = AppLocalizations.of(context)!;
    final portionText = formatDiaryMealPortionLabel(context, entry);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: AppInkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                MealThumb(entry: entry, compact: true),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        DiaryEntryNutrition(entry: entry),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${numberFormat.format(entry.totalKcal.round())} '
                      '${l10n.caloriesUnitKcal}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (portionText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        portionText,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
