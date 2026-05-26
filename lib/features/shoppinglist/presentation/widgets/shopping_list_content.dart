import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_list_clear_crossed_off_action.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_list_item_tile.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/'
    'shopping_list_stats_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines shopping list content.
class ShoppingListContent extends StatelessWidget {
  /// The shopping list content.
  const ShoppingListContent({
    required this.items,
    required this.controller,
    required this.l10n,
    required this.currency,
    super.key,
  });

  /// The items.
  final List<ShoppingListItem> items;

  /// The controller.
  final ShoppingListController controller;

  /// The l10n.
  final AppLocalizations l10n;

  /// The currency.
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final crossedOffCount = items.where((item) => item.quantity == 0).length;
    final (estimatedTotal, totalQuantity) = _totals();

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
        ShoppingListClearCrossedOffAction(
          crossedOffCount: crossedOffCount,
          controller: controller,
          l10n: l10n,
        ),
        Expanded(child: _listBody()),
      ],
    );
  }

  (double, int) _totals() {
    return items.fold<(double, int)>((0.0, 0), (sum, item) {
      return (sum.$1 + item.estimatedTotal, sum.$2 + item.quantity);
    });
  }

  Widget _listBody() {
    if (items.isEmpty) {
      return Center(
        child: Text(l10n.shoppingListEmptyState, textAlign: TextAlign.center),
      );
    }
    return ListView.separated(
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
    );
  }
}
