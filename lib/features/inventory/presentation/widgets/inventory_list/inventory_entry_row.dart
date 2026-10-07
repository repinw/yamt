import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/graphit_stock_bar.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_entry.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_entry_picture.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_entry_texts.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Flat Vorrat row: framed picture, name, amount left, info line and a stock
/// bar with one segment per pack or portion. A rule separates the rows.
class InventoryEntryRow extends StatelessWidget {
  /// Creates the row for [entry].
  const new({
    required this.entry,
    required this.tiltLeft,
    this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.planned = 0,
    super.key,
  });

  /// The food or meal.
  final InventoryListEntry entry;

  /// Whether the picture tilts to the left; rows alternate.
  final bool tiltLeft;

  /// Opens the entry, or toggles it in selection mode.
  final VoidCallback? onTap;

  /// Starts the selection.
  final VoidCallback? onLongPress;

  /// Whether the list selects foods.
  final bool isSelectionMode;

  /// Whether this entry is selected.
  final bool isSelected;

  /// Stock of the food that open plans take, in its stored unit.
  final int planned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final texts = InventoryEntryTexts.of(entry, l10n, planned: planned);
    final amountColor = entry.isLow ? colors.low : colors.ink;
    final small = textTheme.labelSmall?.copyWith(color: colors.muted);

    return AppInkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.rule)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppGraphit.stockRowMinHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              spacing: AppSpacing.md,
              children: [
                if (isSelectionMode && entry is InventoryFoodEntry)
                  Checkbox(value: isSelected, onChanged: (_) => onTap?.call())
                else
                  InventoryEntryPicture(
                    entry: entry,
                    size: AppGraphit.stockRowPicture,
                    tiltLeft: tiltLeft,
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.xxs,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        spacing: AppSpacing.sm,
                        children: [
                          Expanded(
                            child: Text(
                              entry.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                color: colors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: texts.amount,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: amountColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: texts.unit,
                                  style: small?.copyWith(color: amountColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        spacing: AppSpacing.sm,
                        children: [
                          Expanded(
                            child: Text(
                              texts.info,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: texts.infoIsWarning
                                  ? small?.copyWith(
                                      color: colors.low,
                                      fontWeight: FontWeight.w700,
                                    )
                                  : small,
                            ),
                          ),
                          Text(
                            texts.ofFull,
                            style: entry.isLow
                                ? small?.copyWith(
                                    color: colors.low,
                                    fontWeight: FontWeight.w700,
                                  )
                                : small,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxs),
                        child: GraphitStockBar(
                          share: entry.remainingShare,
                          segments: entry.segments,
                          isLow: entry.isLow,
                          plannedShare: switch (entry) {
                            final InventoryFoodEntry food => food.shareOf(
                              planned,
                            ),
                            _ => 0,
                          },
                        ),
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
