import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_sections.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shelf/shopping_shelf_labels.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_entry_grid.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The entry tiles as slivers, each group under the heading of its shelf,
/// or in one group without a heading when sorted by name.
class ShoppingListShelfGrid extends StatelessWidget {
  /// Creates the grid.
  const new({
    required this.groups,
    required this.onTap,
    required this.onLongPress,
    this.markPrivate = false,
    super.key,
  });

  /// The tiles in their groups, in list order.
  final List<ShoppingListTileGroup> groups;

  /// Called with the tapped entry.
  final ValueChanged<ShoppingListItem> onTap;

  /// Called with the long-pressed entry.
  final ValueChanged<ShoppingListItem> onLongPress;

  /// Whether private entries show a lock.
  final bool markPrivate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SliverMainAxisGroup(
      slivers: [
        for (final group in groups) ...[
          if (group.shelf case final shelf?)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Text(
                  shoppingShelfLabel(l10n, shelf).toUpperCase(),
                  key: ShoppingListPageKeys.shelfHeading(shelf.name),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: AppShopping.shelfHeadingLetterSpacing,
                  ),
                ),
              ),
            ),
          ShoppingListEntryGrid(
            tiles: group.tiles,
            onTap: onTap,
            onLongPress: onLongPress,
            markPrivate: markPrivate,
          ),
        ],
      ],
    );
  }
}
