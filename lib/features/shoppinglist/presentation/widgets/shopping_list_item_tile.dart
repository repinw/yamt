import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines shopping list item tile.
class ShoppingListItemTile extends StatelessWidget {
  /// The shopping list item tile.
  const ShoppingListItemTile({
    required this.item,
    required this.l10n,
    required this.currency,
    required this.onDismissed,
    required this.onIncrement,
    required this.onDecrement,
    super.key,
  });

  /// The item.
  final ShoppingListItem item;

  /// The l10n.
  final AppLocalizations l10n;

  /// The currency.
  final NumberFormat currency;

  /// The on dismissed.
  final ValueChanged<String> onDismissed;

  /// The on increment.
  final ValueChanged<String> onIncrement;

  /// The on decrement.
  final ValueChanged<String> onDecrement;

  @override
  Widget build(BuildContext context) {
    final isCrossedOff = item.quantity == 0;
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final subtitleStyle = Theme.of(context).textTheme.bodySmall;

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
          title: Text(
            item.name,
            style: _crossedOffStyle(titleStyle, isCrossedOff),
          ),
          subtitle: Text(
            _subtitle(),
            style: _crossedOffStyle(subtitleStyle, isCrossedOff),
          ),
          trailing: _ShoppingListQuantityStepper(
            quantity: item.quantity,
            isCrossedOff: isCrossedOff,
            onIncrement: () => onIncrement(item.id),
            onDecrement: isCrossedOff ? null : () => onDecrement(item.id),
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
    required this.isCrossedOff,
    required this.onIncrement,
    required this.onDecrement,
    required this.increaseTooltip,
    required this.decreaseTooltip,
  });

  final int quantity;
  final bool isCrossedOff;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;
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
        Text(quantity.toString(), style: _quantityStyle(context, isCrossedOff)),
        IconButton(
          onPressed: onIncrement,
          icon: const Icon(Icons.add_circle_outline),
          tooltip: increaseTooltip,
        ),
      ],
    );
  }
}

TextStyle? _crossedOffStyle(TextStyle? base, bool isCrossedOff) {
  if (!isCrossedOff) {
    return base;
  }
  return (base ?? const TextStyle()).copyWith(
    decoration: TextDecoration.lineThrough,
  );
}

TextStyle? _quantityStyle(BuildContext context, bool isCrossedOff) {
  final base = Theme.of(context).textTheme.bodyMedium;
  final withWeight = (base ?? const TextStyle()).copyWith(
    fontWeight: FontWeight.w700,
  );
  return _crossedOffStyle(withWeight, isCrossedOff);
}
