import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_macro_summary.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_meal_portion_formatter.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_meal_thumb.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One logged food: image, name, macros, kcal, and amount.
class DiaryMealEntryTile extends StatelessWidget {
  /// Creates a diary entry row.
  const new({
    required this.entry,
    required this.onTap,
    this.count = 1,
    this.expanded,
    super.key,
  });

  /// Entry to display, or the combined entry of a merged group.
  final DiaryMealEntry entry;

  /// How many logged entries the row stands for.
  final int count;

  /// Expansion state of a merged group; `null` for a single entry.
  final bool? expanded;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final portionText = formatDiaryMealPortionLabel(context, entry);
    final expanded = this.expanded;

    return Material(
      key: DiaryMealsSectionKeys.entryTile(entry.id),
      color: Colors.transparent,
      child: AppInkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: Row(
              children: [
                if (count > 1)
                  _CountBadge(
                    count: count,
                    child: MealThumb(entry: entry),
                  )
                else
                  MealThumb(entry: entry),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      DiaryMacroSummary(
                        protein: entry.totalProtein,
                        carbs: entry.totalCarbs,
                        fat: entry.totalFat,
                      ),
                    ],
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (portionText != null)
                      Text(
                        portionText,
                        maxLines: 1,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                if (expanded != null) ...[
                  const SizedBox(width: AppSpacing.xxs),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: AppDurations.compactMetricExpansion,
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows how many entries a merged row stands for, on the food image.
class _CountBadge extends StatelessWidget {
  const new({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      label: AppLocalizations.of(context)!.diaryMealEntryCount(count),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            right: -AppSpacing.xxs,
            bottom: -AppSpacing.xxs,
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: colors.surface, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  child: Text(
                    '$count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
