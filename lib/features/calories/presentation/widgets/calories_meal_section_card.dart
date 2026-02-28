import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

class CaloriesMealSectionCard extends StatelessWidget {
  const CaloriesMealSectionCard({
    super.key,
    required this.section,
    required this.title,
    required this.emptyMessage,
    required this.deleteTooltip,
    required this.onTapEntry,
    required this.onDeleteEntry,
  });

  final CalorieMealSection section;
  final String title;
  final String emptyMessage;
  final String deleteTooltip;
  final ValueChanged<CalorieEntry> onTapEntry;
  final ValueChanged<CalorieEntry> onDeleteEntry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final kcalUnit = l10n.caloriesUnitKcal;

    return Card(
      key: CaloriesPageKeys.sectionCard(section.mealType.name),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('${section.totalKcal.toStringAsFixed(0)} $kcalUnit'),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (section.entries.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  emptyMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              ...section.entries.map((entry) {
                return ListTile(
                  key: CaloriesPageKeys.entryTile(entry.id),
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.name),
                  subtitle: Text(
                    '${entry.consumedAmount.toStringAsFixed(0)} '
                    '${_consumedUnitLabel(l10n, entry.consumedUnit)}',
                  ),
                  trailing: Wrap(
                    spacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text('${entry.totalKcal.toStringAsFixed(0)} $kcalUnit'),
                      IconButton(
                        key: CaloriesPageKeys.entryDeleteButton(entry.id),
                        tooltip: deleteTooltip,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => onDeleteEntry(entry),
                      ),
                    ],
                  ),
                  onTap: () => onTapEntry(entry),
                  onLongPress: () => onDeleteEntry(entry),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _consumedUnitLabel(AppLocalizations l10n, ConsumedUnit unit) {
    return switch (unit) {
      ConsumedUnit.grams => l10n.caloriesUnitGram,
      ConsumedUnit.milliliters => l10n.caloriesUnitMilliliter,
    };
  }
}
