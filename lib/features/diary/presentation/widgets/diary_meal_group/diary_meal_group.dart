import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_group/diary_meal_entry_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Logged meal: quiet heading (kcal total when it has several foods), then
/// its entries.
class DiaryMealGroup extends StatelessWidget {
  /// Creates a diary meal group.
  const new({required this.section, required this.onTapEntry, super.key});

  /// Meal section with at least one entry.
  final DiaryMealSection section;

  /// Called when an entry row is tapped.
  final ValueChanged<DiaryMealEntry> onTapEntry;

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
            // A single food already shows the same kcal in its row.
            if (section.entries.length > 1) ...[
              const SizedBox(width: AppSpacing.md),
              Text(
                '${numberFormat.format(section.totalKcal.round())} '
                '${l10n.caloriesUnitKcal}',
                maxLines: 1,
                style: labelStyle,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        for (final entry in section.entries)
          DiaryMealEntryTile(entry: entry, onTap: () => onTapEntry(entry)),
      ],
    );
  }
}
