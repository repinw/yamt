import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/shoppinglist/provider/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_list_item_tile.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_list_stats_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

class ShoppingListPageKeys {
  const ShoppingListPageKeys._();

  static const clearCrossedOffButton = Key(
    'shopping_list_clear_crossed_off_button',
  );
  static const clearCrossedOffConfirmButton = Key(
    'shopping_list_clear_crossed_off_confirm_button',
  );
  static const clearCrossedOffCancelButton = Key(
    'shopping_list_clear_crossed_off_cancel_button',
  );
}

class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final currency = NumberFormat.currency(locale: locale, symbol: '€');
    final items = ref.watch(shoppingListControllerProvider);
    final controller = ref.read(shoppingListControllerProvider.notifier);
    final crossedOffCount = items.where((item) => item.quantity == 0).length;
    final totals = items.fold<(double, int)>((0.0, 0), (sum, item) {
      return (sum.$1 + item.estimatedTotal, sum.$2 + item.quantity);
    });
    final estimatedTotal = totals.$1;
    final totalQuantity = totals.$2;

    return Column(
      children: [
        Padding(
          padding: AppInsets.page,
          child: ShoppingListStatsCard(
            entryCount: items.length,
            totalQuantity: totalQuantity,
            estimatedTotal: estimatedTotal,
            currency: currency,
            l10n: l10n,
          ),
        ),
        if (crossedOffCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: ShoppingListPageKeys.clearCrossedOffButton,
                onPressed: () async {
                  final confirmed = await _confirmClearCrossedOff(
                    context: context,
                    l10n: l10n,
                  );
                  if (confirmed != true) {
                    return;
                  }
                  controller.clearCrossedOffItems();
                },
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(
                  l10n.shoppingListClearCrossedOffAction(crossedOffCount),
                ),
              ),
            ),
          ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    l10n.shoppingListEmptyState,
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.xxxxl + AppSpacing.xxxxl,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ShoppingListItemTile(
                      item: item,
                      l10n: l10n,
                      currency: currency,
                      onDismissed: controller.removeItem,
                      onIncrement: controller.incrementQuantity,
                      onDecrement: controller.decrementQuantity,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<bool?> _confirmClearCrossedOff({
    required BuildContext context,
    required AppLocalizations l10n,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.shoppingListClearCrossedOffDialogTitle),
          content: Text(l10n.shoppingListClearCrossedOffDialogMessage),
          actions: [
            TextButton(
              key: ShoppingListPageKeys.clearCrossedOffCancelButton,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.inventoryReceiptReviewCancelAction),
            ),
            FilledButton(
              key: ShoppingListPageKeys.clearCrossedOffConfirmButton,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.shoppingListClearCrossedOffConfirmAction),
            ),
          ],
        );
      },
    );
  }
}
