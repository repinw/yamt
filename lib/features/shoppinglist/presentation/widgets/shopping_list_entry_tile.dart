import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_letter_disc.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One entry of the list as a tile: a tap ticks it off, a long press opens
/// its details.
class ShoppingListEntryTile extends StatelessWidget {
  /// Creates the tile.
  const new({
    required this.item,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  /// The entry. A done entry shows ticked until it moves to the cart.
  final ShoppingListItem item;

  /// Ticks the entry off, or takes the tick back.
  final VoidCallback onTap;

  /// Opens the details of the entry.
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final brand = item.brand ?? '';
    return Semantics(
      button: true,
      selected: item.isDone,
      onTapHint: item.isDone
          ? l10n.shoppingListPutBackHint
          : l10n.shoppingListTickOffHint,
      onLongPressHint: l10n.shoppingListDetailsHint,
      child: Material(
        color: item.isDone
            ? colors.primaryContainer
            : colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: AppInkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppShopping.tileMinHeight,
            ),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShoppingListLetterDisc(
                          name: item.name,
                          size: AppShopping.letterDisc,
                          ticked: item.isDone,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (brand.isNotEmpty)
                          Text(
                            brand,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (item.quantity > 1)
                  PositionedDirectional(
                    top: AppSpacing.xs,
                    end: AppSpacing.xs,
                    child: _QuantityBadge(item: item),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuantityBadge extends StatelessWidget {
  const new({required this.item});

  final ShoppingListItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(
        minWidth: AppShopping.quantityBadge,
        minHeight: AppShopping.quantityBadge,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.inverseSurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '${item.quantity}',
        key: ShoppingListPageKeys.tileQuantity(item.id),
        style: theme.textTheme.labelMedium?.copyWith(
          color: colors.onInverseSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
