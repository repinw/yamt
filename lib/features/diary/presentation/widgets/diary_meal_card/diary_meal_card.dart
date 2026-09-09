import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_card/diary_collapsed_meal_body.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_card/diary_expanded_meal_body.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_card/diary_meal_icon.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_card/diary_meal_section_nutrition.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_quick_add_menu.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// A collapsible diary meal card with quick-add actions and entries.
class DiaryMealCard extends StatelessWidget {
  /// Creates a diary meal card.
  const DiaryMealCard({
    required this.section,
    required this.isExpanded,
    required this.onToggle,
    required this.onTapEntry,
    required this.onQuickAdd,
    this.macroTargets,
    super.key,
  });

  /// Resolved targets of the selected diary day.
  final DiaryMacroTargets? macroTargets;

  /// Meal section data rendered by the card.
  final DiaryMealSection section;

  /// Whether entries are currently visible.
  final bool isExpanded;

  /// Toggles the card expansion state.
  final VoidCallback onToggle;

  /// Called when an entry row is selected.
  final ValueChanged<DiaryMealEntry> onTapEntry;

  /// Called when a quick-add source is selected.
  final ValueChanged<DiaryQuickEatSource> onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final l10n = AppLocalizations.of(context)!;
    final accentColors = MetricAccentColors.of(context);

    return DecoratedBox(
      decoration: AppQuietSurfaces.cardDecoration(colors),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: AppInkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Row(
                    children: [
                      DiaryMealIcon(mealType: section.mealType),
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
                                    section.mealType.localizedName(l10n),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: colors.onSurface,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                if (section.entries.isNotEmpty) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    '${numberFormat.format(
                                      section.totalKcal.round(),
                                    )} ${l10n.caloriesUnitKcal}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: colors.onSurfaceVariant,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                            if (section.entries.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              DiaryMealSectionNutrition(section: section),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      DiaryMealQuickAddMenu(
                        mealType: section.mealType,
                        onSelected: onQuickAdd,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: isExpanded
                              ? accentColors.today
                              : colors.onSurfaceVariant,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? DiaryExpandedMealBody(
                      macroTargets: macroTargets,
                      section: section,
                      onTapEntry: onTapEntry,
                    )
                  : DiaryCollapsedMealBody(
                      section: section,
                      onTapEntry: onTapEntry,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
