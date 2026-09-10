import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_product_menu.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Reusable favorites and scheduled entries remain available after clearing.
class ShoppingListSavedProducts extends ConsumerWidget {
  /// Creates the saved products section.
  const ShoppingListSavedProducts({required this.items, super.key});

  /// Saved products supplied by the presentation state.
  final List<ShoppingListItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      title: Text(l10n.shoppingListSavedProducts),
      children: [
        for (final item in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              item.isFavorite ? Icons.star_rounded : Icons.event_repeat,
            ),
            title: Text(item.name),
            subtitle: Text(_subtitle(context, item)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l10n.shoppingListAddAction,
                  icon: const Icon(Icons.add),
                  onPressed: item.quantity > 0 && !item.isArchived
                      ? null
                      : () => _add(context, ref, item),
                ),
                ShoppingListProductMenu(item: item),
              ],
            ),
          ),
      ],
    );
  }

  String _subtitle(BuildContext context, ShoppingListItem item) {
    final l10n = AppLocalizations.of(context)!;
    return [
      if (item.brand?.isNotEmpty ?? false) item.brand!,
      if (item.repeatEveryDays > 0)
        l10n.shoppingListRepeatSummary(
          item.repeatQuantity,
          item.repeatEveryDays,
        ),
      if (item.nextDueDate != null && item.repeatEveryDays > 0)
        l10n.shoppingListNextDue(
          DateFormat.yMd(
            Localizations.localeOf(context).toLanguageTag(),
          ).format(item.nextDueDate!),
        ),
      if (item.isFavorite && item.repeatEveryDays == 0)
        l10n.shoppingListFavorite,
    ].join(' · ');
  }

  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    ShoppingListItem item,
  ) async {
    final saved = await ref
        .read(shoppingListControllerProvider.notifier)
        .addSavedItem(item.id);
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.shoppingListAddFailedError,
          ),
        ),
      );
    }
  }
}
