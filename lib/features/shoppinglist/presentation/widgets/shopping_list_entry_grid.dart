import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_entry_tile.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';

/// Lays the entry tiles out in rows of equal height. The number of tiles in
/// a row follows the width and the text size.
class ShoppingListEntryGrid extends StatelessWidget {
  /// Creates the grid.
  const new({
    required this.items,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  /// The entries, in list order.
  final List<ShoppingListItem> items;

  /// Called with the tapped entry.
  final ValueChanged<ShoppingListItem> onTap;

  /// Called with the long-pressed entry.
  final ValueChanged<ShoppingListItem> onLongPress;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columns(constraints.maxWidth, scale);
        return Column(
          children: [
            for (var start = 0; start < items.length; start += columns)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _row(start, columns),
                  ),
                ),
              ),
          ],
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
        child: start + column < items.length
            ? _tile(items[start + column])
            : const SizedBox.shrink(),
      ),
    ],
  ];

  Widget _tile(ShoppingListItem item) => ShoppingListEntryTile(
    key: ShoppingListPageKeys.tile(item.id),
    item: item,
    onTap: () => onTap(item),
    onLongPress: () => onLongPress(item),
  );
}
