import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/config/barcode_backfill_feature_flags.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/text_voice_search_bar.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_search_service.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_consumption_filter.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_all_items_sliver.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_consumed_items_toggle.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_mode_toggle.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_top_controls_sliver.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_prepared_meals_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_sections.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_group.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_groups_sliver.dart';
import 'package:yamt/features/shoppinglist/application/'
    'shopping_list_operations.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryList extends ConsumerStatefulWidget {
  const InventoryList({
    super.key,
    required this.items,
    required this.preparedMeals,
    this.expandedPreparedMealId,
    required this.emptyStateActionButton,
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
  final Widget emptyStateActionButton;
  final Future<bool> Function(String itemId) onDeleteItem;
  final Future<bool> Function(String itemId, InventoryItemEatRequest request)
  onEatItem;
  final Future<bool> Function(
    String itemId,
    int amount,
    InventoryDiscardReason reason,
  )
  onThrowAwayItem;
  final Future<bool> Function({
    required String mealId,
    required int portions,
    required MealType mealType,
    required DateTime loggedDay,
  })
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
  static const _searchService = InventorySearchService();
  final _voiceSearchController = TextVoiceSearchController();
  var _mode = InventoryListMode.allItems;
  var _consumptionFilter = const InventoryConsumptionFilter();
  var _hideFullyConsumedPreparedMeals = false;
  var _isPreparedMealsSectionExpanded = true;
  late final VoiceSearchService _voiceSearchService;
  late final TextEditingController _searchController;
  late List<InventoryItem> _visibleItems;
  late List<PreparedMeal> _visiblePreparedMeals;
  var _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _voiceSearchService = ref.read(voiceSearchServiceProvider);
    _searchController = TextEditingController();
    _recomputeVisibleContent();
  }

  @override
  void didUpdateWidget(covariant InventoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.items, widget.items) ||
        !listEquals(oldWidget.preparedMeals, widget.preparedMeals)) {
      _recomputeVisibleContent();
    }
  }

  @override
  void dispose() {
    _voiceSearchController.dispose();
    _searchController.dispose();
    super.dispose();
  }

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
    final filteredItems = _visibleItems;
    final filteredPreparedMeals = _visiblePreparedMeals;
    final hasPreparedMealSource = widget.preparedMeals.isNotEmpty;
    final hasPreparedMeals = filteredPreparedMeals.isNotEmpty;
    final showPreparedMealsSection =
        hasPreparedMeals ||
        (hasPreparedMealSource && _hideFullyConsumedPreparedMeals);
    final hasAnySourceItems =
        widget.items.isNotEmpty || widget.preparedMeals.isNotEmpty;
    final hasFilteredItems = filteredItems.isNotEmpty;
    final modeToggle = InventoryListModeToggle(
      mode: _mode,
      l10n: l10n,
      onModeChanged: _onModeChanged,
      enabled: !widget.isSelectionMode,
    );

    return CustomScrollView(
      slivers: [
        InventoryListTopControlsSliver(
          modeToggle: InventoryModeToolbar(modeToggle: modeToggle),
          showSearch: hasAnySourceItems,
          searchController: _searchController,
          enabled: !widget.isSelectionMode,
          onSearchChanged: _onSearchQueryChanged,
          voiceSearchService: _voiceSearchService,
          voiceSearchController: _voiceSearchController,
          l10n: l10n,
        ),
        if (showPreparedMealsSection)
          InventoryPreparedMealsSection(
            meals: filteredPreparedMeals,
            expandedPreparedMealId: widget.expandedPreparedMealId,
            isExpanded: _isPreparedMealsSectionExpanded,
            isSelectionMode: widget.isSelectionMode,
            onShowFilters: () =>
                _showPreparedMealFiltersSheet(context, l10n: l10n),
            onToggleExpanded: _togglePreparedMealsSection,
            onEatPreparedMeal: widget.onEatPreparedMeal,
            onThrowAwayPreparedMeal: widget.onThrowAwayPreparedMeal,
            onFillPendingPreparedMealIngredient:
                widget.onFillPendingPreparedMealIngredient,
            onIgnorePendingPreparedMealIngredient:
                widget.onIgnorePendingPreparedMealIngredient,
            onUnbundlePreparedMeal: widget.onUnbundlePreparedMeal,
            onEditPreparedMeal: widget.onEditPreparedMeal,
            onSavePreparedMealTemplate: widget.onSavePreparedMealTemplate,
            l10n: l10n,
          ),
        if (hasAnySourceItems && _mode == InventoryListMode.allItems)
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
                  onPressed: () =>
                      _showInventoryFiltersSheet(context, l10n: l10n),
                ),
              ),
            ),
          ),
        if (!hasAnySourceItems)
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

  void _onHideFullyConsumedItemsChanged(bool hideFullyConsumedItems) {
    if (_consumptionFilter.hideFullyConsumedItems == hideFullyConsumedItems) {
      return;
    }
    setState(() {
      _consumptionFilter = _consumptionFilter.copyWith(
        hideFullyConsumedItems: hideFullyConsumedItems,
      );
      _recomputeVisibleContent();
    });
  }

  void _onHideFullyConsumedPreparedMealsChanged(
    bool hideFullyConsumedPreparedMeals,
  ) {
    if (_hideFullyConsumedPreparedMeals == hideFullyConsumedPreparedMeals) {
      return;
    }
    setState(() {
      _hideFullyConsumedPreparedMeals = hideFullyConsumedPreparedMeals;
      _recomputeVisibleContent();
    });
  }

  void _onSearchQueryChanged(String value) {
    if (_searchQuery == value) {
      return;
    }
    setState(() {
      _searchQuery = value;
      _recomputeVisibleContent();
    });
  }

  void _togglePreparedMealsSection() {
    if (widget.isSelectionMode) {
      return;
    }
    setState(() {
      _isPreparedMealsSectionExpanded = !_isPreparedMealsSectionExpanded;
    });
  }

  Future<void> _showInventoryFiltersSheet(
    BuildContext context, {
    required AppLocalizations l10n,
  }) {
    var hideFullyConsumedItems = _consumptionFilter.hideFullyConsumedItems;

    return _showFiltersSheet(
      context,
      title: l10n.inventoryFiltersTitle,
      childrenBuilder: (setModalState) {
        return <Widget>[
          InventoryConsumedItemsToggle(
            value: hideFullyConsumedItems,
            enabled: !widget.isSelectionMode,
            label: l10n.inventoryHideFullyConsumedItemsToggle,
            onChanged: (nextHideFullyConsumedItems) {
              setModalState(() {
                hideFullyConsumedItems = nextHideFullyConsumedItems;
              });
              _onHideFullyConsumedItemsChanged(nextHideFullyConsumedItems);
            },
          ),
        ];
      },
    );
  }

  Future<void> _showPreparedMealFiltersSheet(
    BuildContext context, {
    required AppLocalizations l10n,
  }) {
    var hideFullyConsumedPreparedMeals = _hideFullyConsumedPreparedMeals;

    return _showFiltersSheet(
      context,
      title: l10n.preparedMealFiltersTitle,
      childrenBuilder: (setModalState) {
        return <Widget>[
          InventoryConsumedItemsToggle(
            value: hideFullyConsumedPreparedMeals,
            enabled: !widget.isSelectionMode,
            label: l10n.preparedMealHideFullyConsumedItemsToggle,
            onChanged: (nextHideFullyConsumedPreparedMeals) {
              setModalState(() {
                hideFullyConsumedPreparedMeals =
                    nextHideFullyConsumedPreparedMeals;
              });
              _onHideFullyConsumedPreparedMealsChanged(
                nextHideFullyConsumedPreparedMeals,
              );
            },
          ),
        ];
      },
    );
  }

  Future<void> _showFiltersSheet(
    BuildContext context, {
    required String title,
    required List<Widget> Function(StateSetter setModalState) childrenBuilder,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return InventoryFiltersSheet(
              title: title,
              children: childrenBuilder(setModalState),
            );
          },
        );
      },
    );
  }

  SliverFillRemaining _buildEmptyStateSliver({String? message}) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: AppInsets.pageLarge,
        child: Align(
          alignment: Alignment.topCenter,
          child: InventoryEmptyState(
            message: message,
            actionButton: widget.emptyStateActionButton,
          ),
        ),
      ),
    );
  }

  void _recomputeVisibleContent() {
    _visibleItems = _searchService.filterItems(
      items: _consumptionFilter.apply(widget.items),
      query: _searchQuery,
    );
    _visiblePreparedMeals = _searchService.filterPreparedMeals(
      meals: _applyPreparedMealFilter(widget.preparedMeals),
      query: _searchQuery,
    );
  }

  List<PreparedMeal> _applyPreparedMealFilter(List<PreparedMeal> meals) {
    if (!_hideFullyConsumedPreparedMeals) {
      return meals;
    }
    return meals.where((meal) => !meal.isDepleted).toList(growable: false);
  }
}
