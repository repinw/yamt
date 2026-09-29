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

/// Small Vorrat tile for the quick overview grid: picture, name, amount left
/// and the stock bar.
class InventoryEntryTile extends StatelessWidget {
  /// Creates the tile for [entry].
  const new({
    required this.entry,
    required this.tiltLeft,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    super.key,
  });

  /// The food or meal.
  final InventoryListEntry entry;

  /// Whether the picture tilts to the left.
  final bool tiltLeft;

  /// Opens the entry, or toggles it in selection mode.
  final VoidCallback? onTap;

  /// Starts the selection.
  final VoidCallback? onLongPress;

  /// Whether this entry is selected.
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final texts = InventoryEntryTexts.of(entry, l10n);
    final amountColor = entry.isLow ? colors.low : colors.ink;
    final radius = BorderRadius.circular(AppRadius.lg);

    return Material(
      color: isSelected ? colors.tile : colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: isSelected
            ? BorderSide(color: colors.ink, width: AppGraphit.stockBarGap)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: AppInkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                child: InventoryEntryPicture(
                  entry: entry,
                  size: AppGraphit.stockTilePicture,
                  tiltLeft: tiltLeft,
                ),
              ),
              Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelLarge?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                l10n.inventoryEatSheetAmountWithUnit(texts.amount, texts.unit),
                maxLines: 1,
                style: textTheme.labelLarge?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              GraphitStockBar(
                share: entry.remainingShare,
                segments: entry.segments,
                isLow: entry.isLow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
