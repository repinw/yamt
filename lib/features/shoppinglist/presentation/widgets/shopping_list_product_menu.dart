import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_schedule_dialog/shopping_list_schedule_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Favorite and recurrence controls shared by listed and saved products.
class ShoppingListProductMenu extends ConsumerWidget {
  /// Creates product settings.
  const ShoppingListProductMenu({required this.item, super.key});

  /// Product being edited.
  final ShoppingListItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      tooltip: l10n.shoppingListProductSettings,
      onSelected: (action) => _select(context, ref, action),
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

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final controller = ref.read(shoppingListControllerProvider.notifier);
    bool saved;
    if (action == 'favorite') {
      saved = await controller.toggleFavorite(item.id);
    } else {
      final input = await showShoppingScheduleDialog(context, item);
      if (input == null || !context.mounted) return;
      saved = await controller.setSchedule(
        item.id,
        days: input.days,
        quantity: input.quantity,
        firstDue: input.firstDue,
      );
    }
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.shoppingListSettingsFailed,
          ),
        ),
      );
    }
  }
}
