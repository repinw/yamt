import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_sections.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_entry_tile.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';

/// Lays the entry tiles out as a sliver of rows of equal height, built as
/// they scroll into view. The number of tiles in a row follows the width and
/// the text size.
class ShoppingListEntryGrid extends StatelessWidget {
  /// Creates the grid.
  const new({
    required this.tiles,
    required this.onTap,
    required this.onLongPress,
    this.markPrivate = false,
    super.key,
  });

  /// The entries with their shelf and picture, in list order.
  final List<ShoppingListTile> tiles;

  /// Called with the tapped entry.
  final ValueChanged<ShoppingListItem> onTap;

  /// Called with the long-pressed entry.
  final ValueChanged<ShoppingListItem> onLongPress;

  /// Whether private entries show a lock.
  final bool markPrivate;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = _columns(constraints.crossAxisExtent, scale);
        return SliverList.builder(
          itemCount: (tiles.length + columns - 1) ~/ columns,
          itemBuilder: (context, row) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _row(row * columns, columns),
              ),
            ),
          ),
        );
      },
    );
  }

  int _columns(double width, double scale) {
    const gaps = AppSpacing.xs * (AppShopping.tileColumns - 1);
    final tileWidth = (width - gaps) / AppShopping.tileColumns;
    return tileWidth < AppShopping.tileMinWidth * scale
        ? AppShopping.tileColumnsLargeText
        : AppShopping.tileColumns;
  }

  List<Widget> _row(int start, int columns) => [
    for (var column = 0; column < columns; column++) ...[
      if (column > 0) const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: start + column < tiles.length
            ? _tile(tiles[start + column])
            : const SizedBox.shrink(),
      ),
    ],
  ];

  Widget _tile(ShoppingListTile tile) => ShoppingListEntryTile(
    key: ShoppingListPageKeys.tile(tile.item.id),
    item: tile.item,
    placement: tile.placement,
    onTap: () => onTap(tile.item),
    onLongPress: () => onLongPress(tile.item),
    markPrivate: markPrivate,
  );
}
