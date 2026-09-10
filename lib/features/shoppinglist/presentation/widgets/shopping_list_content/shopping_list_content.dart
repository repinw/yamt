import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_sections.dart';
import 'package:yamt/features/shoppinglist/application/shopping_suggestions.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_content/shopping_list_empty_state.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_content/shopping_list_entries_section.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_saved_products.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_stats_card.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_suggestions.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines shopping list content.
@Dependencies([shoppingSuggestions, shoppingSuggestionRetry])
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
    final sections = ShoppingListSections(items);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 104),
      children: _children(sections),
    );
  }

  List<Widget> _children(ShoppingListSections sections) => [
    _stats(sections),
    const SizedBox(height: 24),
    if (sections.entryCount == 0) const ShoppingListEmptyState(),
    if (sections.open.isNotEmpty) _entries(sections.open),
    ShoppingListSavedProducts(
      key: const ValueKey('saved-products'),
      items: sections.saved,
    ),
    const ShoppingListSuggestions(key: ValueKey('shopping-suggestions')),
    if (sections.done.isNotEmpty) _entries(sections.done, completed: true),
  ];

  Widget _stats(ShoppingListSections sections) => ShoppingListStatsCard(
    entryCount: sections.entryCount,
    totalQuantity: sections.totalQuantity,
    estimatedTotal: sections.estimatedTotal,
    currency: currency,
    l10n: l10n,
  );

  Widget _entries(List<ShoppingListItem> entries, {bool completed = false}) =>
      ShoppingListEntriesSection(
        items: entries,
        controller: controller,
        currency: currency,
        completed: completed,
      );
}
