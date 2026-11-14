import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_entry_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Favorite and recurrence controls of a saved product.
class ShoppingListProductMenu extends ConsumerWidget {
  /// Creates product settings.
  const new({required this.item, super.key});

  /// Product being edited.
  final ShoppingListItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      tooltip: l10n.shoppingListProductSettings,
      onSelected: (action) => action == 'favorite'
          ? ShoppingListEntryFlow.toggleFavorite(context, ref, item)
          : ShoppingListEntryFlow.editSchedule(context, ref, item),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'favorite',
          child: Text(
            item.isFavorite
                ? l10n.shoppingListRemoveFavorite
                : l10n.shoppingListAddFavorite,
          ),
        ),
        PopupMenuItem(
          value: 'schedule',
          child: Text(l10n.shoppingListSchedule),
        ),
      ],
    );
  }
}
