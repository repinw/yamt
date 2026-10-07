import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_meal_entry_group_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_planned_entry_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Logged meal: quiet heading (kcal total when it has several foods), then
/// its entries, then its plans.
class DiaryMealGroup extends StatelessWidget {
  /// Creates a diary meal group.
  const new({
    required this.section,
    required this.onTapEntry,
    required this.onTapPlan,
    this.onAcceptPlan,
    this.onAcceptAllPlans,
    this.shortPlanIds = const {},
    this.onCopy,
    super.key,
  });

  /// Meal section with at least one entry or plan.
  final DiaryMealSection section;

  /// Called when an entry row is tapped.
  final ValueChanged<DiaryMealEntry> onTapEntry;

  /// Called when a plan row is tapped.
  final ValueChanged<DiaryMealEntry> onTapPlan;

  /// Eats a plan as planned. Without it, plan rows have no check button.
  final ValueChanged<DiaryMealEntry>? onAcceptPlan;

  /// Eats every plan of the meal. Shown only with more than one plan.
  final VoidCallback? onAcceptAllPlans;

  /// Plans the Vorrat cannot cover in full.
  final Set<String> shortPlanIds;

  /// Copies the meal as plans to other days. Without it, no copy icon.
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
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
            Expanded(
              child: Text(
                section.mealType.localizedName(l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
            ),
            // A single counted row already shows the same kcal.
            if (section.countedRowCount > 1) ...[
              const SizedBox(width: AppSpacing.md),
              Text(
                '${numberFormat.format(section.totalKcal.round())} '
                '${l10n.caloriesUnitKcal}',
                maxLines: 1,
                style: labelStyle,
              ),
            ],
            if (onCopy case final copy?)
              IconButton(
                key: DiaryMealsSectionKeys.mealCopyButton(section.mealType),
                tooltip: l10n.diaryMealCopyAction,
                onPressed: copy,
                // Keeps the heading as low as a heading without the icon.
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.content_copy_rounded),
              ),
            if (onAcceptAllPlans case final acceptAll?
                when section.plannedEntries.length > 1)
              IconButton(
                key: DiaryMealsSectionKeys.planAcceptAllButton(
                  section.mealType,
                ),
                tooltip: l10n.diaryPlanAcceptAllAction,
                onPressed: acceptAll,
                icon: const Icon(Icons.done_all_rounded),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        for (final group in section.entryGroups)
          DiaryMealEntryGroupTile(
            key: ValueKey<String>(group.entries.first.id),
            group: group,
            onTapEntry: onTapEntry,
          ),
        for (final plan in section.plannedEntries)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: DiaryPlannedEntryTile(
              plan: plan,
              isShort: shortPlanIds.contains(plan.id),
              onTap: () => onTapPlan(plan),
              onAccept: switch (onAcceptPlan) {
                final accept? => () => accept(plan),
                null => null,
              },
            ),
          ),
      ],
    );
  }
}
