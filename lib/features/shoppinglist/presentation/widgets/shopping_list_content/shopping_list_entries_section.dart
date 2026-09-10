import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_clear_crossed_off_action.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_item_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Displays the open or completed entries with their section controls.
class ShoppingListEntriesSection extends StatelessWidget {
  /// Creates an entry section.
  const ShoppingListEntriesSection({
    required this.items,
    required this.controller,
    required this.currency,
    required this.completed,
    super.key,
  });

  /// Entries already partitioned by application state.
  final List<ShoppingListItem> items;

  /// Mutation controller.
  final ShoppingListController controller;

  /// Localized price formatter.
  final NumberFormat currency;

  /// Whether to show completed-list controls.
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (completed) const SizedBox(height: 24),
        Text(
          completed ? l10n.shoppingListDoneTitle : l10n.shoppingListOpenTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        _controls(l10n),
        ...items.map((item) => _tile(item, l10n)),
        if (!completed) const SizedBox(height: 24),
      ],
    );
  }

  Widget _controls(AppLocalizations l10n) => completed
      ? ShoppingListClearCrossedOffAction(
          crossedOffCount: items.length,
          controller: controller,
          l10n: l10n,
        )
      : const SizedBox(height: 8);

  Widget _tile(ShoppingListItem item, AppLocalizations l10n) => Padding(
    key: ValueKey(item.id),
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: ShoppingListItemTile(
      item: item,
      l10n: l10n,
      currency: currency,
      onDismissed: controller.removeItem,
      onIncrement: controller.incrementQuantity,
      onDecrement: controller.decrementQuantity,
    ),
  );
}
