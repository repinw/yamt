import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

class ShoppingListItemTile extends StatelessWidget {
  const ShoppingListItemTile({
    super.key,
    required this.item,
    required this.l10n,
    required this.currency,
    required this.onDismissed,
    required this.onIncrement,
    required this.onDecrement,
  });

  final ShoppingListItem item;
  final AppLocalizations l10n;
  final NumberFormat currency;
  final ValueChanged<String> onDismissed;
  final ValueChanged<String> onIncrement;
  final ValueChanged<String> onDecrement;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey<String>(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(item.id),
      background: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xl),
            child: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          title: Text(item.name),
          subtitle: Text(_subtitle()),
          trailing: _ShoppingListQuantityStepper(
            quantity: item.quantity,
            onIncrement: () => onIncrement(item.id),
            onDecrement: () => onDecrement(item.id),
            increaseTooltip: l10n.shoppingListIncreaseQuantityAction,
            decreaseTooltip: l10n.shoppingListDecreaseQuantityAction,
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    final brand = item.brand;
    final hasBrand = brand != null && brand.isNotEmpty;
    final estimated = item.estimatedTotal > 0
        ? ' · ${currency.format(item.estimatedTotal)}'
        : '';
    final quantity = '${l10n.shoppingListQuantityLabel}: ${item.quantity}';
    if (!hasBrand) {
      return '$quantity$estimated';
    }
    return '$brand · $quantity$estimated';
  }
}

class _ShoppingListQuantityStepper extends StatelessWidget {
  const _ShoppingListQuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.increaseTooltip,
    required this.decreaseTooltip,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final String increaseTooltip;
  final String decreaseTooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onDecrement,
          icon: const Icon(Icons.remove_circle_outline),
          tooltip: decreaseTooltip,
        ),
        Text(
          quantity.toString(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        IconButton(
          onPressed: onIncrement,
          icon: const Icon(Icons.add_circle_outline),
          tooltip: increaseTooltip,
        ),
      ],
    );
  }
}
