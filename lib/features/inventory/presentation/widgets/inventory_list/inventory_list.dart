import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/config/barcode_backfill_feature_flags.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_consumption_filter.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_all_items_sliver.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_consumption_filter_toggle.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_mode_toggle.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_sections.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_group.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_groups_sliver.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_card.dart';
import 'package:yamt/features/shoppinglist/application/'
    'shopping_list_operations.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryList extends ConsumerStatefulWidget {
  const InventoryList({
    super.key,
    required this.items,
    required this.preparedMeals,
    this.expandedPreparedMealId,
    required this.onDeleteItem,
    required this.onEatItem,
    required this.onThrowAwayItem,
    required this.onEatPreparedMeal,
    required this.onThrowAwayPreparedMeal,
    required this.onFillPendingPreparedMealIngredient,
    required this.onIgnorePendingPreparedMealIngredient,
    required this.onUnbundlePreparedMeal,
    required this.onEditPreparedMeal,
    required this.onSavePreparedMealTemplate,
    required this.isSelectionMode,
    required this.selectedItemIds,
    required this.onItemLongPress,
    required this.onSelectionToggle,
  });

  final List<InventoryItem> items;
  final List<PreparedMeal> preparedMeals;
  final String? expandedPreparedMealId;
  final Future<bool> Function(String itemId) onDeleteItem;
  final Future<bool> Function(String itemId, int amount) onEatItem;
  final Future<bool> Function(
    String itemId,
    int amount,
    InventoryDiscardReason reason,
  )
  onThrowAwayItem;
  final Future<bool> Function(
    String mealId,
    int portions,
    MealType mealType,
    DateTime loggedDay,
  )
  onEatPreparedMeal;
  final Future<bool> Function(
    String mealId,
    int portions,
    InventoryDiscardReason reason,
  )
  onThrowAwayPreparedMeal;
  final Future<bool> Function(
    String mealId,
    String ingredient,
    List<String> inventoryItemIds,
  )
  onFillPendingPreparedMealIngredient;
  final Future<bool> Function(String mealId, String ingredient)
  onIgnorePendingPreparedMealIngredient;
  final Future<bool> Function(String mealId) onUnbundlePreparedMeal;
  final Future<bool> Function(
    String mealId,
    String name,
    bool imageChanged,
    Uint8List? imageBytes,
  )
  onEditPreparedMeal;
  final Future<bool> Function(PreparedMeal meal) onSavePreparedMealTemplate;
  final bool isSelectionMode;
  final Set<String> selectedItemIds;
  final ValueChanged<String> onItemLongPress;
  final ValueChanged<String> onSelectionToggle;

  @override
  ConsumerState<InventoryList> createState() => _InventoryListState();
}

class _InventoryListState extends ConsumerState<InventoryList> {
  var _mode = InventoryListMode.allItems;
  var _consumptionFilter = const InventoryConsumptionFilter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final showBarcodeMarkers = ref.watch(
      barcodeBackfillFeatureFlagsProvider.select(
        (flags) => flags.showInventoryBarcodeMarkers,
      ),
    );
    final activeShoppingListItemKeys = ref.watch(
      activeShoppingListItemKeysProvider,
    );
    final filteredItems = _consumptionFilter.apply(widget.items);
    final hasPreparedMeals = widget.preparedMeals.isNotEmpty;
    final hasSourceItems = widget.items.isNotEmpty || hasPreparedMeals;
    final hasFilteredItems = filteredItems.isNotEmpty;
    final modeToggle = InventoryListModeToggle(
      mode: _mode,
      l10n: l10n,
      onModeChanged: _onModeChanged,
      enabled: !widget.isSelectionMode,
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          sliver: SliverToBoxAdapter(
            child: InventoryModeToolbar(modeToggle: modeToggle),
          ),
        ),
        if (hasPreparedMeals) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: InventorySectionHeader(
                title: l10n.preparedMealSectionTitle,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: widget.preparedMeals
                    .map((meal) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: PreparedMealCard(
                          key: ValueKey(meal.id),
                          meal: meal,
                          initiallyExpanded:
                              meal.id == widget.expandedPreparedMealId,
                          enabled: !widget.isSelectionMode,
                          onEatPressed: widget.onEatPreparedMeal,
                          onThrowAwayPressed: widget.onThrowAwayPreparedMeal,
                          onFillPendingIngredientPressed:
                              widget.onFillPendingPreparedMealIngredient,
                          onIgnorePendingIngredientPressed:
                              widget.onIgnorePendingPreparedMealIngredient,
                          onUnbundlePressed: widget.onUnbundlePreparedMeal,
                          onEditPressed: widget.onEditPreparedMeal,
                          onSaveTemplatePressed:
                              widget.onSavePreparedMealTemplate,
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
          ),
        ],
        if (hasSourceItems && _mode == InventoryListMode.allItems)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: InventorySectionHeader(
                title: l10n.inventoryRecentSectionTitle,
                trailing: InventoryFilterButton(
                  enabled: !widget.isSelectionMode,
                  onPressed: () => _showFiltersSheet(
                    context,
                    title: l10n.inventoryFiltersTitle,
                    l10n: l10n,
                  ),
                ),
              ),
            ),
          ),
        if (!hasSourceItems)
          _buildEmptyStateSliver()
        else if (!hasFilteredItems && !hasPreparedMeals)
          _buildEmptyStateSliver(message: l10n.inventoryFilteredEmptyState)
        else if (_mode == InventoryListMode.byReceipt)
          InventoryReceiptGroupsSliver(
            groups: groupInventoryItemsByReceipt(filteredItems),
            dateFormat: DateFormat.yMMMd(locale),
            showBarcodeMarkers: showBarcodeMarkers,
            activeShoppingListItemKeys: activeShoppingListItemKeys,
            onDeleteItem: widget.onDeleteItem,
            onEatItem: widget.onEatItem,
            onThrowAwayItem: widget.onThrowAwayItem,
            isSelectionMode: widget.isSelectionMode,
            selectedItemIds: widget.selectedItemIds,
            onItemLongPress: widget.onItemLongPress,
            onSelectionToggle: widget.onSelectionToggle,
          )
        else if (hasFilteredItems)
          InventoryAllItemsSliver(
            items: filteredItems,
            l10n: l10n,
            showBarcodeMarkers: showBarcodeMarkers,
            activeShoppingListItemKeys: activeShoppingListItemKeys,
            onDeleteItem: widget.onDeleteItem,
            onEatItem: widget.onEatItem,
            onThrowAwayItem: widget.onThrowAwayItem,
            isSelectionMode: widget.isSelectionMode,
            selectedItemIds: widget.selectedItemIds,
            onItemLongPress: widget.onItemLongPress,
            onSelectionToggle: widget.onSelectionToggle,
          ),
      ],
    );
  }

  void _onModeChanged(InventoryListMode mode) {
    if (widget.isSelectionMode) {
      return;
    }
    setState(() {
      _mode = mode;
    });
  }

  void _onShowConsumedChanged(bool showConsumed) {
    setState(() {
      _consumptionFilter = _consumptionFilter.toggleConsumed(showConsumed);
    });
  }

  void _onShowNotConsumedChanged(bool showNotConsumed) {
    setState(() {
      _consumptionFilter = _consumptionFilter.toggleNotConsumed(
        showNotConsumed,
      );
    });
  }

  Future<void> _showFiltersSheet(
    BuildContext context, {
    required String title,
    required AppLocalizations l10n,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return InventoryFiltersSheet(
          title: title,
          consumptionToggle: InventoryConsumptionFilterToggle(
            showConsumed: _consumptionFilter.showConsumed,
            showNotConsumed: _consumptionFilter.showNotConsumed,
            l10n: l10n,
            onShowConsumedChanged: (showConsumed) {
              _onShowConsumedChanged(showConsumed);
              Navigator.of(context).pop();
            },
            onShowNotConsumedChanged: (showNotConsumed) {
              _onShowNotConsumedChanged(showNotConsumed);
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  SliverFillRemaining _buildEmptyStateSliver({String? message}) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: AppInsets.pageLarge,
        child: InventoryEmptyState(message: message),
      ),
    );
  }
}
