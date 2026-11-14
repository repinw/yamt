import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_product_menu.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_schedule_dialog/shopping_list_schedule_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Reusable favorites and scheduled entries remain available after clearing.
class ShoppingListSavedProducts extends ConsumerWidget {
  /// Creates the saved products section.
  const new({required this.items, super.key});

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
                  onPressed: item.isOpen
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
    final brand = item.brand ?? '';
    final schedule = shoppingScheduleSummary(context, item);
    return [
      if (brand.isNotEmpty) brand,
      ?schedule,
      if (schedule == null && item.isFavorite)
        AppLocalizations.of(context)!.shoppingListFavorite,
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
      ScaffoldMessenger.of(context).showAppSnackBar(
        AppLocalizations.of(context)!.shoppingListAddFailedError,
        tone: AppSnackBarTone.error,
      );
    }
  }
}
