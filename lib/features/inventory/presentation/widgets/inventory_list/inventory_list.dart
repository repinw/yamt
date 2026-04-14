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
    'inventory_item_sort_mode.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_all_items_sliver.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_filter_toggle.dart';
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

enum _PreparedMealSortOrder { newestFirst, oldestFirst }

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
  static const _recentItemsSectionStorageKey =
      'inventory_recent_items_section_expanded';
  static const _preparedMealsSectionStorageKey =
      'inventory_prepared_meals_section_expanded';
  final _voiceSearchController = TextVoiceSearchController();
  var _mode = InventoryListMode.allItems;
  var _consumptionFilter = const InventoryConsumptionFilter();
  var _inventoryItemSortMode = InventoryItemSortMode.recentlyAddedDescending;
  var _hideFullyConsumedPreparedMeals = false;
  var _showOnlyDepletedPreparedMeals = false;
  var _showOnlyReadyPreparedMeals = false;
  var _showOnlyIncompletePreparedMeals = false;
  var _preparedMealSortOrder = _PreparedMealSortOrder.newestFirst;
  var _isRecentItemsSectionExpanded = true;
  var _isPreparedMealsSectionExpanded = true;
  var _didRestoreSectionExpandedStates = false;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRestoreSectionExpandedStates) {
      return;
    }
    _didRestoreSectionExpandedStates = true;

    final pageStorage = PageStorage.maybeOf(context);
    final restoredRecentItemsState = pageStorage?.readState(
      context,
      identifier: _recentItemsSectionStorageKey,
    );
    if (restoredRecentItemsState is bool) {
      _isRecentItemsSectionExpanded = restoredRecentItemsState;
    }

    final restoredPreparedMealsState = pageStorage?.readState(
      context,
      identifier: _preparedMealsSectionStorageKey,
    );
    if (restoredPreparedMealsState is bool) {
      _isPreparedMealsSectionExpanded = restoredPreparedMealsState;
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
    final hasItemSource = widget.items.isNotEmpty;
    final hasPreparedMealSource = widget.preparedMeals.isNotEmpty;
    final hasRecentItems = filteredItems.isNotEmpty;
    final hasPreparedMeals = filteredPreparedMeals.isNotEmpty;
    final showRecentItemsSection =
        _mode == InventoryListMode.allItems &&
        (hasItemSource || hasRecentItems || _hasInventoryItemFiltersActive);
    final showPreparedMealsSection =
        hasPreparedMeals ||
        (hasPreparedMealSource && _hasPreparedMealFiltersActive);
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
        if (showRecentItemsSection)
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
                subtitle: _inventoryItemSortModeLabel(l10n),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InventoryFilterButton(
                      key: const Key('inventory_items_filter_button'),
                      enabled: !widget.isSelectionMode,
                      onPressed: () =>
                          _showInventoryFiltersSheet(context, l10n: l10n),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    InventorySectionExpandButton(
                      key: const Key('inventory_items_section_expand_button'),
                      isExpanded: _isRecentItemsSectionExpanded,
                      semanticLabel: l10n.inventoryRecentSectionTitle,
                      enabled: !widget.isSelectionMode,
                      rotationKey: const Key(
                        'inventory_items_section_expand_indicator',
                      ),
                      onPressed: _toggleRecentItemsSection,
                    ),
                  ],
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
        else if (hasFilteredItems && _isRecentItemsSectionExpanded)
          InventoryAllItemsSliver(
            items: filteredItems,
            l10n: l10n,
            showBarcodeMarkers: showBarcodeMarkers,
            activeShoppingListItemKeys: activeShoppingListItemKeys,
            sortMode: _inventoryItemSortMode,
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

  void _onInventoryItemSortModeChanged(InventoryItemSortMode sortMode) {
    if (_inventoryItemSortMode == sortMode) {
      return;
    }
    setState(() {
      _inventoryItemSortMode = sortMode;
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
      if (hideFullyConsumedPreparedMeals) {
        _showOnlyDepletedPreparedMeals = false;
      }
      _recomputeVisibleContent();
    });
  }

  void _onShowOnlyDepletedPreparedMealsChanged(
    bool showOnlyDepletedPreparedMeals,
  ) {
    if (_showOnlyDepletedPreparedMeals == showOnlyDepletedPreparedMeals) {
      return;
    }
    setState(() {
      _showOnlyDepletedPreparedMeals = showOnlyDepletedPreparedMeals;
      if (showOnlyDepletedPreparedMeals) {
        _hideFullyConsumedPreparedMeals = false;
      }
      _recomputeVisibleContent();
    });
  }

  void _onShowOnlyReadyPreparedMealsChanged(bool showOnlyReadyPreparedMeals) {
    if (_showOnlyReadyPreparedMeals == showOnlyReadyPreparedMeals) {
      return;
    }
    setState(() {
      _showOnlyReadyPreparedMeals = showOnlyReadyPreparedMeals;
      if (showOnlyReadyPreparedMeals) {
        _showOnlyIncompletePreparedMeals = false;
      }
      _recomputeVisibleContent();
    });
  }

  void _onShowOnlyIncompletePreparedMealsChanged(
    bool showOnlyIncompletePreparedMeals,
  ) {
    if (_showOnlyIncompletePreparedMeals == showOnlyIncompletePreparedMeals) {
      return;
    }
    setState(() {
      _showOnlyIncompletePreparedMeals = showOnlyIncompletePreparedMeals;
      if (showOnlyIncompletePreparedMeals) {
        _showOnlyReadyPreparedMeals = false;
      }
      _recomputeVisibleContent();
    });
  }

  void _onPreparedMealSortOrderChanged(
    _PreparedMealSortOrder preparedMealSortOrder,
  ) {
    if (_preparedMealSortOrder == preparedMealSortOrder) {
      return;
    }
    setState(() {
      _preparedMealSortOrder = preparedMealSortOrder;
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

  void _toggleRecentItemsSection() {
    if (widget.isSelectionMode) {
      return;
    }
    setState(() {
      _isRecentItemsSectionExpanded = !_isRecentItemsSectionExpanded;
    });
    PageStorage.maybeOf(context)?.writeState(
      context,
      _isRecentItemsSectionExpanded,
      identifier: _recentItemsSectionStorageKey,
    );
  }

  void _togglePreparedMealsSection() {
    if (widget.isSelectionMode) {
      return;
    }
    setState(() {
      _isPreparedMealsSectionExpanded = !_isPreparedMealsSectionExpanded;
    });
    PageStorage.maybeOf(context)?.writeState(
      context,
      _isPreparedMealsSectionExpanded,
      identifier: _preparedMealsSectionStorageKey,
    );
  }

  Future<void> _showInventoryFiltersSheet(
    BuildContext context, {
    required AppLocalizations l10n,
  }) {
    var hideFullyConsumedItems = _consumptionFilter.hideFullyConsumedItems;
    var inventoryItemSortMode = _inventoryItemSortMode;

    return _showFiltersSheet(
      context,
      title: l10n.inventoryFiltersTitle,
      childrenBuilder: (setModalState) {
        return <Widget>[
          Text(
            l10n.inventorySortSectionTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          InventoryFilterRadioOption<InventoryItemSortMode>(
            key: const Key(
              'inventory_items_sort_recently_added_descending_option',
            ),
            value: InventoryItemSortMode.recentlyAddedDescending,
            groupValue: inventoryItemSortMode,
            enabled: !widget.isSelectionMode,
            label: l10n.inventorySortRecentlyAddedDescending,
            onChanged: (nextSortMode) {
              setModalState(() {
                inventoryItemSortMode = nextSortMode;
              });
              _onInventoryItemSortModeChanged(nextSortMode);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          InventoryFilterRadioOption<InventoryItemSortMode>(
            key: const Key(
              'inventory_items_sort_recently_added_ascending_option',
            ),
            value: InventoryItemSortMode.recentlyAddedAscending,
            groupValue: inventoryItemSortMode,
            enabled: !widget.isSelectionMode,
            label: l10n.inventorySortRecentlyAddedAscending,
            onChanged: (nextSortMode) {
              setModalState(() {
                inventoryItemSortMode = nextSortMode;
              });
              _onInventoryItemSortModeChanged(nextSortMode);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          InventoryFilterRadioOption<InventoryItemSortMode>(
            key: const Key(
              'inventory_items_sort_recently_eaten_descending_option',
            ),
            value: InventoryItemSortMode.recentlyEatenDescending,
            groupValue: inventoryItemSortMode,
            enabled: !widget.isSelectionMode,
            label: l10n.inventorySortRecentlyEatenDescending,
            onChanged: (nextSortMode) {
              setModalState(() {
                inventoryItemSortMode = nextSortMode;
              });
              _onInventoryItemSortModeChanged(nextSortMode);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          InventoryFilterRadioOption<InventoryItemSortMode>(
            key: const Key(
              'inventory_items_sort_recently_eaten_ascending_option',
            ),
            value: InventoryItemSortMode.recentlyEatenAscending,
            groupValue: inventoryItemSortMode,
            enabled: !widget.isSelectionMode,
            label: l10n.inventorySortRecentlyEatenAscending,
            onChanged: (nextSortMode) {
              setModalState(() {
                inventoryItemSortMode = nextSortMode;
              });
              _onInventoryItemSortModeChanged(nextSortMode);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          InventoryFilterRadioOption<InventoryItemSortMode>(
            key: const Key('inventory_items_sort_alphabetical_option'),
            value: InventoryItemSortMode.alphabetical,
            groupValue: inventoryItemSortMode,
            enabled: !widget.isSelectionMode,
            label: l10n.inventorySortAlphabetical,
            onChanged: (nextSortMode) {
              setModalState(() {
                inventoryItemSortMode = nextSortMode;
              });
              _onInventoryItemSortModeChanged(nextSortMode);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          InventoryFilterRadioOption<InventoryItemSortMode>(
            key: const Key(
              'inventory_items_sort_available_amount_ascending_option',
            ),
            value: InventoryItemSortMode.availableAmountAscending,
            groupValue: inventoryItemSortMode,
            enabled: !widget.isSelectionMode,
            label: l10n.inventorySortAvailableAmountAscending,
            onChanged: (nextSortMode) {
              setModalState(() {
                inventoryItemSortMode = nextSortMode;
              });
              _onInventoryItemSortModeChanged(nextSortMode);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          InventoryFilterRadioOption<InventoryItemSortMode>(
            key: const Key(
              'inventory_items_sort_available_amount_descending_option',
            ),
            value: InventoryItemSortMode.availableAmountDescending,
            groupValue: inventoryItemSortMode,
            enabled: !widget.isSelectionMode,
            label: l10n.inventorySortAvailableAmountDescending,
            onChanged: (nextSortMode) {
              setModalState(() {
                inventoryItemSortMode = nextSortMode;
              });
              _onInventoryItemSortModeChanged(nextSortMode);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          InventoryFilterToggle(
            key: const Key('inventory_items_hide_consumed_toggle'),
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
    var showOnlyDepletedPreparedMeals = _showOnlyDepletedPreparedMeals;
    var showOnlyReadyPreparedMeals = _showOnlyReadyPreparedMeals;
    var showOnlyIncompletePreparedMeals = _showOnlyIncompletePreparedMeals;
    var preparedMealSortOrder = _preparedMealSortOrder;

    return _showFiltersSheet(
      context,
      title: l10n.preparedMealFiltersTitle,
      childrenBuilder: (setModalState) {
        return <Widget>[
          InventoryFilterToggle(
            key: const Key('prepared_meals_sort_newest_button'),
            value: preparedMealSortOrder == _PreparedMealSortOrder.newestFirst,
            enabled: !widget.isSelectionMode,
            label: l10n.preparedMealSortNewestFirst,
            onChanged: (newestFirst) {
              final nextSortOrder = newestFirst
                  ? _PreparedMealSortOrder.newestFirst
                  : _PreparedMealSortOrder.oldestFirst;
              setModalState(() {
                preparedMealSortOrder = nextSortOrder;
              });
              _onPreparedMealSortOrderChanged(nextSortOrder);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          InventoryFilterToggle(
            key: const Key('prepared_meals_ready_only_toggle'),
            value: showOnlyReadyPreparedMeals,
            enabled: !widget.isSelectionMode,
            label: l10n.preparedMealShowReadyOnlyToggle,
            onChanged: (nextShowOnlyReadyPreparedMeals) {
              setModalState(() {
                showOnlyReadyPreparedMeals = nextShowOnlyReadyPreparedMeals;
                if (nextShowOnlyReadyPreparedMeals) {
                  showOnlyIncompletePreparedMeals = false;
                }
              });
              _onShowOnlyReadyPreparedMealsChanged(
                nextShowOnlyReadyPreparedMeals,
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          InventoryFilterToggle(
            key: const Key('prepared_meals_incomplete_only_toggle'),
            value: showOnlyIncompletePreparedMeals,
            enabled: !widget.isSelectionMode,
            label: l10n.preparedMealShowIncompleteOnlyToggle,
            onChanged: (nextShowOnlyIncompletePreparedMeals) {
              setModalState(() {
                showOnlyIncompletePreparedMeals =
                    nextShowOnlyIncompletePreparedMeals;
                if (nextShowOnlyIncompletePreparedMeals) {
                  showOnlyReadyPreparedMeals = false;
                }
              });
              _onShowOnlyIncompletePreparedMealsChanged(
                nextShowOnlyIncompletePreparedMeals,
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          InventoryFilterToggle(
            key: const Key('prepared_meals_depleted_only_toggle'),
            value: showOnlyDepletedPreparedMeals,
            enabled: !widget.isSelectionMode,
            label: l10n.preparedMealShowDepletedOnlyToggle,
            onChanged: (nextShowOnlyDepletedPreparedMeals) {
              setModalState(() {
                showOnlyDepletedPreparedMeals =
                    nextShowOnlyDepletedPreparedMeals;
                if (nextShowOnlyDepletedPreparedMeals) {
                  hideFullyConsumedPreparedMeals = false;
                }
              });
              _onShowOnlyDepletedPreparedMealsChanged(
                nextShowOnlyDepletedPreparedMeals,
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          InventoryFilterToggle(
            key: const Key('prepared_meals_hide_consumed_toggle'),
            value: hideFullyConsumedPreparedMeals,
            enabled: !widget.isSelectionMode,
            label: l10n.preparedMealHideFullyConsumedItemsToggle,
            onChanged: (nextHideFullyConsumedPreparedMeals) {
              setModalState(() {
                hideFullyConsumedPreparedMeals =
                    nextHideFullyConsumedPreparedMeals;
                if (nextHideFullyConsumedPreparedMeals) {
                  showOnlyDepletedPreparedMeals = false;
                }
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
      isScrollControlled: true,
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
      meals: _sortPreparedMeals(_applyPreparedMealFilter(widget.preparedMeals)),
      query: _searchQuery,
    );
  }

  List<PreparedMeal> _applyPreparedMealFilter(List<PreparedMeal> meals) {
    final filteredMeals = List<PreparedMeal>.from(meals);

    if (_showOnlyReadyPreparedMeals) {
      filteredMeals.removeWhere((meal) => meal.hasPendingRecipeIngredients);
    }
    if (_showOnlyIncompletePreparedMeals) {
      filteredMeals.removeWhere((meal) => !meal.hasPendingRecipeIngredients);
    }
    if (_showOnlyDepletedPreparedMeals) {
      filteredMeals.removeWhere((meal) => !meal.isDepleted);
    }
    if (_hideFullyConsumedPreparedMeals) {
      filteredMeals.removeWhere((meal) => meal.isDepleted);
    }
    return filteredMeals;
  }

  bool get _hasPreparedMealFiltersActive {
    return _hideFullyConsumedPreparedMeals ||
        _showOnlyDepletedPreparedMeals ||
        _showOnlyReadyPreparedMeals ||
        _showOnlyIncompletePreparedMeals;
  }

  bool get _hasInventoryItemFiltersActive {
    return _consumptionFilter.hideFullyConsumedItems;
  }

  String _inventoryItemSortModeLabel(AppLocalizations l10n) {
    return switch (_inventoryItemSortMode) {
      InventoryItemSortMode.recentlyAddedDescending =>
        l10n.inventorySortRecentlyAddedDescending,
      InventoryItemSortMode.recentlyAddedAscending =>
        l10n.inventorySortRecentlyAddedAscending,
      InventoryItemSortMode.recentlyEatenDescending =>
        l10n.inventorySortRecentlyEatenDescending,
      InventoryItemSortMode.recentlyEatenAscending =>
        l10n.inventorySortRecentlyEatenAscending,
      InventoryItemSortMode.alphabetical => l10n.inventorySortAlphabetical,
      InventoryItemSortMode.availableAmountAscending =>
        l10n.inventorySortAvailableAmountAscending,
      InventoryItemSortMode.availableAmountDescending =>
        l10n.inventorySortAvailableAmountDescending,
    };
  }

  List<PreparedMeal> _sortPreparedMeals(List<PreparedMeal> meals) {
    meals.sort((left, right) {
      final dateCompare = switch (_preparedMealSortOrder) {
        _PreparedMealSortOrder.newestFirst => right.createdAt.compareTo(
          left.createdAt,
        ),
        _PreparedMealSortOrder.oldestFirst => left.createdAt.compareTo(
          right.createdAt,
        ),
      };
      if (dateCompare != 0) {
        return dateCompare;
      }
      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });
    return meals;
  }
}
