import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/config/barcode_backfill_feature_flags.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
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
    'inventory_list_view_preferences.dart';
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

enum _PreparedMealSortCriterion { added, eaten, alphabetical, quantity }

enum _InventoryItemSortCriterion { added, eaten, alphabetical, quantity }

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
  static const _viewPreferencesStore = InventoryListViewPreferencesStore();
  final _voiceSearchController = TextVoiceSearchController();
  var _mode = InventoryListMode.allItems;
  var _consumptionFilter = const InventoryConsumptionFilter();
  var _inventoryItemSortMode = InventoryItemSortMode.recentlyAddedDescending;
  var _preparedMealCompletionFilter = PreparedMealCompletionFilter.all;
  var _preparedMealConsumptionFilter = PreparedMealConsumptionFilter.all;
  var _preparedMealSortMode = PreparedMealSortMode.addedDescending;
  var _isRecentItemsSectionExpanded = true;
  var _isPreparedMealsSectionExpanded = true;
  late final AppPreferences _preferences;
  late final VoiceSearchService _voiceSearchService;
  late final TextEditingController _searchController;
  late List<InventoryItem> _visibleItems;
  late List<PreparedMeal> _visiblePreparedMeals;
  var _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _preferences = ref.read(appPreferencesProvider);
    _voiceSearchService = ref.read(voiceSearchServiceProvider);
    _searchController = TextEditingController();
    _restorePersistedViewPreferences();
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
            subtitle: _preparedMealSortModeLabel(l10n),
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

  void _restorePersistedViewPreferences() {
    final preferences = _viewPreferencesStore.readSync(_preferences);
    _consumptionFilter = preferences.consumptionFilter;
    _inventoryItemSortMode = preferences.inventoryItemSortMode;
    _preparedMealCompletionFilter = preferences.preparedMealCompletionFilter;
    _preparedMealConsumptionFilter = preferences.preparedMealConsumptionFilter;
    _preparedMealSortMode = preferences.preparedMealSortMode;
    _isRecentItemsSectionExpanded = preferences.isRecentItemsSectionExpanded;
    _isPreparedMealsSectionExpanded =
        preferences.isPreparedMealsSectionExpanded;
  }

  Future<void> _persistViewPreferences() {
    return _viewPreferencesStore.save(
      _preferences,
      InventoryListViewPreferences(
        consumptionFilter: _consumptionFilter,
        inventoryItemSortMode: _inventoryItemSortMode,
        preparedMealCompletionFilter: _preparedMealCompletionFilter,
        preparedMealConsumptionFilter: _preparedMealConsumptionFilter,
        preparedMealSortMode: _preparedMealSortMode,
        isRecentItemsSectionExpanded: _isRecentItemsSectionExpanded,
        isPreparedMealsSectionExpanded: _isPreparedMealsSectionExpanded,
      ),
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
    unawaited(_persistViewPreferences());
  }

  void _onInventoryItemSortModeChanged(InventoryItemSortMode sortMode) {
    if (_inventoryItemSortMode == sortMode) {
      return;
    }
    setState(() {
      _inventoryItemSortMode = sortMode;
    });
    unawaited(_persistViewPreferences());
  }

  void _onPreparedMealConsumptionFilterChanged(
    PreparedMealConsumptionFilter filter,
  ) {
    if (_preparedMealConsumptionFilter == filter) {
      return;
    }
    setState(() {
      _preparedMealConsumptionFilter = filter;
      _recomputeVisibleContent();
    });
    unawaited(_persistViewPreferences());
  }

  void _onPreparedMealCompletionFilterChanged(
    PreparedMealCompletionFilter filter,
  ) {
    if (_preparedMealCompletionFilter == filter) {
      return;
    }
    setState(() {
      _preparedMealCompletionFilter = filter;
      _recomputeVisibleContent();
    });
    unawaited(_persistViewPreferences());
  }

  void _onPreparedMealSortModeChanged(
    PreparedMealSortMode preparedMealSortMode,
  ) {
    if (_preparedMealSortMode == preparedMealSortMode) {
      return;
    }
    setState(() {
      _preparedMealSortMode = preparedMealSortMode;
      _recomputeVisibleContent();
    });
    unawaited(_persistViewPreferences());
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
    unawaited(_persistViewPreferences());
  }

  void _togglePreparedMealsSection() {
    if (widget.isSelectionMode) {
      return;
    }
    setState(() {
      _isPreparedMealsSectionExpanded = !_isPreparedMealsSectionExpanded;
    });
    unawaited(_persistViewPreferences());
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
      subtitle: l10n.inventoryFiltersSubtitle,
      actionLabel: l10n.inventoryFiltersShowResultsAction,
      childrenBuilder: (setModalState) {
        void updateSortMode(InventoryItemSortMode nextSortMode) {
          setModalState(() {
            inventoryItemSortMode = nextSortMode;
          });
          _onInventoryItemSortModeChanged(nextSortMode);
        }

        final selectedCriterion = _inventoryItemSortCriterionFor(
          inventoryItemSortMode,
        );
        final sortAscending = _isInventoryItemSortAscending(
          inventoryItemSortMode,
        );

        return <Widget>[
          InventoryFiltersSectionLabel(label: l10n.inventorySortSectionTitle),
          const SizedBox(height: AppSpacing.md),
          InventorySortOptionCard(
            key: const Key('inventory_items_sort_added_option'),
            title: l10n.inventorySortAdded,
            icon: Icons.access_time_rounded,
            isSelected: selectedCriterion == _InventoryItemSortCriterion.added,
            enabled: !widget.isSelectionMode,
            directionLabel:
                selectedCriterion == _InventoryItemSortCriterion.added
                ? _inventoryItemSortDirectionLabel(
                    l10n,
                    criterion: _InventoryItemSortCriterion.added,
                    ascending: sortAscending,
                  )
                : null,
            directionButtonKey: const Key(
              'inventory_items_sort_added_direction_button',
            ),
            sortDirectionAscending: sortAscending,
            onSelect: () {
              updateSortMode(
                _inventoryItemSortModeFor(
                  _InventoryItemSortCriterion.added,
                  ascending: _defaultAscendingForCriterion(
                    _InventoryItemSortCriterion.added,
                  ),
                ),
              );
            },
            onToggleDirection:
                selectedCriterion == _InventoryItemSortCriterion.added
                ? () {
                    updateSortMode(
                      _inventoryItemSortModeFor(
                        _InventoryItemSortCriterion.added,
                        ascending: !sortAscending,
                      ),
                    );
                  }
                : null,
          ),
          const SizedBox(height: AppSpacing.xs),
          InventorySortOptionCard(
            key: const Key('inventory_items_sort_eaten_option'),
            title: l10n.inventorySortEaten,
            icon: Icons.restaurant_rounded,
            isSelected: selectedCriterion == _InventoryItemSortCriterion.eaten,
            enabled: !widget.isSelectionMode,
            directionLabel:
                selectedCriterion == _InventoryItemSortCriterion.eaten
                ? _inventoryItemSortDirectionLabel(
                    l10n,
                    criterion: _InventoryItemSortCriterion.eaten,
                    ascending: sortAscending,
                  )
                : null,
            directionButtonKey: const Key(
              'inventory_items_sort_eaten_direction_button',
            ),
            sortDirectionAscending: sortAscending,
            onSelect: () {
              updateSortMode(
                _inventoryItemSortModeFor(
                  _InventoryItemSortCriterion.eaten,
                  ascending: _defaultAscendingForCriterion(
                    _InventoryItemSortCriterion.eaten,
                  ),
                ),
              );
            },
            onToggleDirection:
                selectedCriterion == _InventoryItemSortCriterion.eaten
                ? () {
                    updateSortMode(
                      _inventoryItemSortModeFor(
                        _InventoryItemSortCriterion.eaten,
                        ascending: !sortAscending,
                      ),
                    );
                  }
                : null,
          ),
          const SizedBox(height: AppSpacing.xs),
          InventorySortOptionCard(
            key: const Key('inventory_items_sort_alphabetical_option'),
            title: l10n.inventorySortAlphabetical,
            icon: Icons.sort_by_alpha_rounded,
            isSelected:
                selectedCriterion == _InventoryItemSortCriterion.alphabetical,
            enabled: !widget.isSelectionMode,
            directionLabel:
                selectedCriterion == _InventoryItemSortCriterion.alphabetical
                ? _inventoryItemSortDirectionLabel(
                    l10n,
                    criterion: _InventoryItemSortCriterion.alphabetical,
                    ascending: sortAscending,
                  )
                : null,
            directionButtonKey: const Key(
              'inventory_items_sort_alphabetical_direction_button',
            ),
            sortDirectionAscending: sortAscending,
            onSelect: () {
              updateSortMode(
                _inventoryItemSortModeFor(
                  _InventoryItemSortCriterion.alphabetical,
                  ascending: _defaultAscendingForCriterion(
                    _InventoryItemSortCriterion.alphabetical,
                  ),
                ),
              );
            },
            onToggleDirection:
                selectedCriterion == _InventoryItemSortCriterion.alphabetical
                ? () {
                    updateSortMode(
                      _inventoryItemSortModeFor(
                        _InventoryItemSortCriterion.alphabetical,
                        ascending: !sortAscending,
                      ),
                    );
                  }
                : null,
          ),
          const SizedBox(height: AppSpacing.xs),
          InventorySortOptionCard(
            key: const Key('inventory_items_sort_quantity_option'),
            title: l10n.inventorySortQuantity,
            icon: Icons.inventory_2_rounded,
            isSelected:
                selectedCriterion == _InventoryItemSortCriterion.quantity,
            enabled: !widget.isSelectionMode,
            directionLabel:
                selectedCriterion == _InventoryItemSortCriterion.quantity
                ? _inventoryItemSortDirectionLabel(
                    l10n,
                    criterion: _InventoryItemSortCriterion.quantity,
                    ascending: sortAscending,
                  )
                : null,
            directionButtonKey: const Key(
              'inventory_items_sort_quantity_direction_button',
            ),
            sortDirectionAscending: sortAscending,
            onSelect: () {
              updateSortMode(
                _inventoryItemSortModeFor(
                  _InventoryItemSortCriterion.quantity,
                  ascending: _defaultAscendingForCriterion(
                    _InventoryItemSortCriterion.quantity,
                  ),
                ),
              );
            },
            onToggleDirection:
                selectedCriterion == _InventoryItemSortCriterion.quantity
                ? () {
                    updateSortMode(
                      _inventoryItemSortModeFor(
                        _InventoryItemSortCriterion.quantity,
                        ascending: !sortAscending,
                      ),
                    );
                  }
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Divider(
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          InventoryFiltersSectionLabel(label: l10n.inventoryFilterSectionTitle),
          const SizedBox(height: AppSpacing.md),
          InventoryFilterToggle(
            key: const Key('inventory_items_hide_consumed_toggle'),
            value: hideFullyConsumedItems,
            enabled: !widget.isSelectionMode,
            label: l10n.inventoryHideConsumedFilterTitle,
            description: l10n.inventoryHideConsumedFilterSubtitle,
            icon: hideFullyConsumedItems
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
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
    var preparedMealConsumptionFilter = _preparedMealConsumptionFilter;
    var preparedMealCompletionFilter = _preparedMealCompletionFilter;
    var preparedMealSortMode = _preparedMealSortMode;

    return _showFiltersSheet(
      context,
      title: l10n.preparedMealFiltersTitle,
      subtitle: l10n.preparedMealFiltersSubtitle,
      actionLabel: l10n.inventoryFiltersShowResultsAction,
      childrenBuilder: (setModalState) {
        void updatePreparedMealSortMode(PreparedMealSortMode nextSortMode) {
          setModalState(() {
            preparedMealSortMode = nextSortMode;
          });
          _onPreparedMealSortModeChanged(nextSortMode);
        }

        final selectedCriterion = _preparedMealSortCriterionFor(
          preparedMealSortMode,
        );
        final sortAscending = _isPreparedMealSortAscending(
          preparedMealSortMode,
        );

        return <Widget>[
          InventoryFiltersSectionLabel(label: l10n.inventorySortSectionTitle),
          const SizedBox(height: AppSpacing.md),
          InventorySortOptionCard(
            key: const Key('prepared_meals_sort_added_option'),
            title: l10n.inventorySortAdded,
            icon: Icons.access_time_rounded,
            isSelected: selectedCriterion == _PreparedMealSortCriterion.added,
            enabled: !widget.isSelectionMode,
            directionLabel:
                selectedCriterion == _PreparedMealSortCriterion.added
                ? _preparedMealSortDirectionLabel(
                    l10n,
                    criterion: _PreparedMealSortCriterion.added,
                    ascending: sortAscending,
                  )
                : null,
            directionButtonKey: const Key(
              'prepared_meals_sort_added_direction_button',
            ),
            sortDirectionAscending: sortAscending,
            onSelect: () {
              updatePreparedMealSortMode(
                _preparedMealSortModeFor(
                  _PreparedMealSortCriterion.added,
                  ascending: _defaultAscendingForPreparedMealSortCriterion(
                    _PreparedMealSortCriterion.added,
                  ),
                ),
              );
            },
            onToggleDirection:
                selectedCriterion == _PreparedMealSortCriterion.added
                ? () {
                    updatePreparedMealSortMode(
                      _preparedMealSortModeFor(
                        _PreparedMealSortCriterion.added,
                        ascending: !sortAscending,
                      ),
                    );
                  }
                : null,
          ),
          const SizedBox(height: AppSpacing.xs),
          InventorySortOptionCard(
            key: const Key('prepared_meals_sort_eaten_option'),
            title: l10n.inventorySortEaten,
            icon: Icons.restaurant_rounded,
            isSelected: selectedCriterion == _PreparedMealSortCriterion.eaten,
            enabled: !widget.isSelectionMode,
            directionLabel:
                selectedCriterion == _PreparedMealSortCriterion.eaten
                ? _preparedMealSortDirectionLabel(
                    l10n,
                    criterion: _PreparedMealSortCriterion.eaten,
                    ascending: sortAscending,
                  )
                : null,
            directionButtonKey: const Key(
              'prepared_meals_sort_eaten_direction_button',
            ),
            sortDirectionAscending: sortAscending,
            onSelect: () {
              updatePreparedMealSortMode(
                _preparedMealSortModeFor(
                  _PreparedMealSortCriterion.eaten,
                  ascending: _defaultAscendingForPreparedMealSortCriterion(
                    _PreparedMealSortCriterion.eaten,
                  ),
                ),
              );
            },
            onToggleDirection:
                selectedCriterion == _PreparedMealSortCriterion.eaten
                ? () {
                    updatePreparedMealSortMode(
                      _preparedMealSortModeFor(
                        _PreparedMealSortCriterion.eaten,
                        ascending: !sortAscending,
                      ),
                    );
                  }
                : null,
          ),
          const SizedBox(height: AppSpacing.xs),
          InventorySortOptionCard(
            key: const Key('prepared_meals_sort_alphabetical_option'),
            title: l10n.inventorySortAlphabetical,
            icon: Icons.sort_by_alpha_rounded,
            isSelected:
                selectedCriterion == _PreparedMealSortCriterion.alphabetical,
            enabled: !widget.isSelectionMode,
            directionLabel:
                selectedCriterion == _PreparedMealSortCriterion.alphabetical
                ? _preparedMealSortDirectionLabel(
                    l10n,
                    criterion: _PreparedMealSortCriterion.alphabetical,
                    ascending: sortAscending,
                  )
                : null,
            directionButtonKey: const Key(
              'prepared_meals_sort_alphabetical_direction_button',
            ),
            sortDirectionAscending: sortAscending,
            onSelect: () {
              updatePreparedMealSortMode(
                _preparedMealSortModeFor(
                  _PreparedMealSortCriterion.alphabetical,
                  ascending: _defaultAscendingForPreparedMealSortCriterion(
                    _PreparedMealSortCriterion.alphabetical,
                  ),
                ),
              );
            },
            onToggleDirection:
                selectedCriterion == _PreparedMealSortCriterion.alphabetical
                ? () {
                    updatePreparedMealSortMode(
                      _preparedMealSortModeFor(
                        _PreparedMealSortCriterion.alphabetical,
                        ascending: !sortAscending,
                      ),
                    );
                  }
                : null,
          ),
          const SizedBox(height: AppSpacing.xs),
          InventorySortOptionCard(
            key: const Key('prepared_meals_sort_quantity_option'),
            title: l10n.inventorySortQuantity,
            icon: Icons.inventory_2_rounded,
            isSelected:
                selectedCriterion == _PreparedMealSortCriterion.quantity,
            enabled: !widget.isSelectionMode,
            directionLabel:
                selectedCriterion == _PreparedMealSortCriterion.quantity
                ? _preparedMealSortDirectionLabel(
                    l10n,
                    criterion: _PreparedMealSortCriterion.quantity,
                    ascending: sortAscending,
                  )
                : null,
            directionButtonKey: const Key(
              'prepared_meals_sort_quantity_direction_button',
            ),
            sortDirectionAscending: sortAscending,
            onSelect: () {
              updatePreparedMealSortMode(
                _preparedMealSortModeFor(
                  _PreparedMealSortCriterion.quantity,
                  ascending: _defaultAscendingForPreparedMealSortCriterion(
                    _PreparedMealSortCriterion.quantity,
                  ),
                ),
              );
            },
            onToggleDirection:
                selectedCriterion == _PreparedMealSortCriterion.quantity
                ? () {
                    updatePreparedMealSortMode(
                      _preparedMealSortModeFor(
                        _PreparedMealSortCriterion.quantity,
                        ascending: !sortAscending,
                      ),
                    );
                  }
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Divider(
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          InventoryFiltersSectionLabel(label: l10n.inventoryFilterSectionTitle),
          const SizedBox(height: AppSpacing.md),
          InventoryFilterToggle(
            key: const Key('prepared_meals_ready_only_toggle'),
            value:
                preparedMealCompletionFilter ==
                PreparedMealCompletionFilter.readyOnly,
            enabled: !widget.isSelectionMode,
            label: l10n.preparedMealShowReadyOnlyToggle,
            icon: Icons.check_circle_outline_rounded,
            onChanged: (isEnabled) {
              final nextFilter = isEnabled
                  ? PreparedMealCompletionFilter.readyOnly
                  : PreparedMealCompletionFilter.all;
              setModalState(() {
                preparedMealCompletionFilter = nextFilter;
              });
              _onPreparedMealCompletionFilterChanged(nextFilter);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          InventoryFilterToggle(
            key: const Key('prepared_meals_incomplete_only_toggle'),
            value:
                preparedMealCompletionFilter ==
                PreparedMealCompletionFilter.incompleteOnly,
            enabled: !widget.isSelectionMode,
            label: l10n.preparedMealShowIncompleteOnlyToggle,
            icon: Icons.rule_folder_outlined,
            onChanged: (isEnabled) {
              final nextFilter = isEnabled
                  ? PreparedMealCompletionFilter.incompleteOnly
                  : PreparedMealCompletionFilter.all;
              setModalState(() {
                preparedMealCompletionFilter = nextFilter;
              });
              _onPreparedMealCompletionFilterChanged(nextFilter);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          InventoryFilterToggle(
            key: const Key('prepared_meals_depleted_only_toggle'),
            value:
                preparedMealConsumptionFilter ==
                PreparedMealConsumptionFilter.depletedOnly,
            enabled: !widget.isSelectionMode,
            label: l10n.preparedMealShowDepletedOnlyToggle,
            icon: Icons.remove_circle_outline_rounded,
            onChanged: (isEnabled) {
              final nextFilter = isEnabled
                  ? PreparedMealConsumptionFilter.depletedOnly
                  : PreparedMealConsumptionFilter.all;
              setModalState(() {
                preparedMealConsumptionFilter = nextFilter;
              });
              _onPreparedMealConsumptionFilterChanged(nextFilter);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          InventoryFilterToggle(
            key: const Key('prepared_meals_hide_consumed_toggle'),
            value:
                preparedMealConsumptionFilter ==
                PreparedMealConsumptionFilter.hideConsumed,
            enabled: !widget.isSelectionMode,
            label: l10n.preparedMealHideFullyConsumedItemsToggle,
            icon: Icons.visibility_off_rounded,
            onChanged: (isEnabled) {
              final nextFilter = isEnabled
                  ? PreparedMealConsumptionFilter.hideConsumed
                  : PreparedMealConsumptionFilter.all;
              setModalState(() {
                preparedMealConsumptionFilter = nextFilter;
              });
              _onPreparedMealConsumptionFilterChanged(nextFilter);
            },
          ),
        ];
      },
    );
  }

  Future<void> _showFiltersSheet(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String actionLabel,
    required List<Widget> Function(StateSetter setModalState) childrenBuilder,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.38),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return InventoryFiltersSheet(
              title: title,
              subtitle: subtitle,
              actionLabel: actionLabel,
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

    switch (_preparedMealCompletionFilter) {
      case PreparedMealCompletionFilter.all:
        break;
      case PreparedMealCompletionFilter.readyOnly:
        filteredMeals.removeWhere((meal) => meal.hasPendingRecipeIngredients);
        break;
      case PreparedMealCompletionFilter.incompleteOnly:
        filteredMeals.removeWhere((meal) => !meal.hasPendingRecipeIngredients);
        break;
    }

    switch (_preparedMealConsumptionFilter) {
      case PreparedMealConsumptionFilter.all:
        break;
      case PreparedMealConsumptionFilter.hideConsumed:
        filteredMeals.removeWhere((meal) => meal.isDepleted);
        break;
      case PreparedMealConsumptionFilter.depletedOnly:
        filteredMeals.removeWhere((meal) => !meal.isDepleted);
        break;
    }
    return filteredMeals;
  }

  bool get _hasPreparedMealFiltersActive {
    return _preparedMealCompletionFilter != PreparedMealCompletionFilter.all ||
        _preparedMealConsumptionFilter != PreparedMealConsumptionFilter.all;
  }

  bool get _hasInventoryItemFiltersActive {
    return _consumptionFilter.hideFullyConsumedItems;
  }

  String _inventoryItemSortModeLabel(AppLocalizations l10n) {
    final criterion = _inventoryItemSortCriterionFor(_inventoryItemSortMode);
    final ascending = _isInventoryItemSortAscending(_inventoryItemSortMode);

    return '${_inventoryItemSortCriterionLabel(l10n, criterion)} - '
        '${_inventoryItemSortDirectionLabel(l10n, criterion: criterion, ascending: ascending)}';
  }

  String _preparedMealSortModeLabel(AppLocalizations l10n) {
    final criterion = _preparedMealSortCriterionFor(_preparedMealSortMode);
    final ascending = _isPreparedMealSortAscending(_preparedMealSortMode);

    return '${_preparedMealSortCriterionLabel(l10n, criterion)} - '
        '${_preparedMealSortDirectionLabel(l10n, criterion: criterion, ascending: ascending)}';
  }

  _InventoryItemSortCriterion _inventoryItemSortCriterionFor(
    InventoryItemSortMode sortMode,
  ) {
    return switch (sortMode) {
      InventoryItemSortMode.recentlyAddedDescending ||
      InventoryItemSortMode.recentlyAddedAscending =>
        _InventoryItemSortCriterion.added,
      InventoryItemSortMode.recentlyEatenDescending ||
      InventoryItemSortMode.recentlyEatenAscending =>
        _InventoryItemSortCriterion.eaten,
      InventoryItemSortMode.alphabeticalAscending ||
      InventoryItemSortMode.alphabeticalDescending =>
        _InventoryItemSortCriterion.alphabetical,
      InventoryItemSortMode.availableAmountAscending ||
      InventoryItemSortMode.availableAmountDescending =>
        _InventoryItemSortCriterion.quantity,
    };
  }

  bool _isInventoryItemSortAscending(InventoryItemSortMode sortMode) {
    return switch (sortMode) {
      InventoryItemSortMode.recentlyAddedAscending ||
      InventoryItemSortMode.recentlyEatenAscending ||
      InventoryItemSortMode.alphabeticalAscending ||
      InventoryItemSortMode.availableAmountAscending => true,
      InventoryItemSortMode.recentlyAddedDescending ||
      InventoryItemSortMode.recentlyEatenDescending ||
      InventoryItemSortMode.alphabeticalDescending ||
      InventoryItemSortMode.availableAmountDescending => false,
    };
  }

  bool _defaultAscendingForCriterion(_InventoryItemSortCriterion criterion) {
    return switch (criterion) {
      _InventoryItemSortCriterion.added ||
      _InventoryItemSortCriterion.eaten => false,
      _InventoryItemSortCriterion.alphabetical ||
      _InventoryItemSortCriterion.quantity => true,
    };
  }

  InventoryItemSortMode _inventoryItemSortModeFor(
    _InventoryItemSortCriterion criterion, {
    required bool ascending,
  }) {
    return switch ((criterion, ascending)) {
      (_InventoryItemSortCriterion.added, true) =>
        InventoryItemSortMode.recentlyAddedAscending,
      (_InventoryItemSortCriterion.added, false) =>
        InventoryItemSortMode.recentlyAddedDescending,
      (_InventoryItemSortCriterion.eaten, true) =>
        InventoryItemSortMode.recentlyEatenAscending,
      (_InventoryItemSortCriterion.eaten, false) =>
        InventoryItemSortMode.recentlyEatenDescending,
      (_InventoryItemSortCriterion.alphabetical, true) =>
        InventoryItemSortMode.alphabeticalAscending,
      (_InventoryItemSortCriterion.alphabetical, false) =>
        InventoryItemSortMode.alphabeticalDescending,
      (_InventoryItemSortCriterion.quantity, true) =>
        InventoryItemSortMode.availableAmountAscending,
      (_InventoryItemSortCriterion.quantity, false) =>
        InventoryItemSortMode.availableAmountDescending,
    };
  }

  String _inventoryItemSortCriterionLabel(
    AppLocalizations l10n,
    _InventoryItemSortCriterion criterion,
  ) {
    return switch (criterion) {
      _InventoryItemSortCriterion.added => l10n.inventorySortAdded,
      _InventoryItemSortCriterion.eaten => l10n.inventorySortEaten,
      _InventoryItemSortCriterion.alphabetical =>
        l10n.inventorySortAlphabetical,
      _InventoryItemSortCriterion.quantity => l10n.inventorySortQuantity,
    };
  }

  String _inventoryItemSortDirectionLabel(
    AppLocalizations l10n, {
    required _InventoryItemSortCriterion criterion,
    required bool ascending,
  }) {
    if (criterion == _InventoryItemSortCriterion.alphabetical) {
      return ascending
          ? l10n.inventorySortDirectionAlphaAscending
          : l10n.inventorySortDirectionAlphaDescending;
    }

    return ascending
        ? l10n.inventorySortDirectionAscending
        : l10n.inventorySortDirectionDescending;
  }

  _PreparedMealSortCriterion _preparedMealSortCriterionFor(
    PreparedMealSortMode sortMode,
  ) {
    return switch (sortMode) {
      PreparedMealSortMode.addedDescending ||
      PreparedMealSortMode.addedAscending => _PreparedMealSortCriterion.added,
      PreparedMealSortMode.eatenDescending ||
      PreparedMealSortMode.eatenAscending => _PreparedMealSortCriterion.eaten,
      PreparedMealSortMode.alphabeticalAscending ||
      PreparedMealSortMode.alphabeticalDescending =>
        _PreparedMealSortCriterion.alphabetical,
      PreparedMealSortMode.quantityAscending ||
      PreparedMealSortMode.quantityDescending =>
        _PreparedMealSortCriterion.quantity,
    };
  }

  bool _isPreparedMealSortAscending(PreparedMealSortMode sortMode) {
    return switch (sortMode) {
      PreparedMealSortMode.addedAscending ||
      PreparedMealSortMode.eatenAscending ||
      PreparedMealSortMode.alphabeticalAscending ||
      PreparedMealSortMode.quantityAscending => true,
      PreparedMealSortMode.addedDescending ||
      PreparedMealSortMode.eatenDescending ||
      PreparedMealSortMode.alphabeticalDescending ||
      PreparedMealSortMode.quantityDescending => false,
    };
  }

  bool _defaultAscendingForPreparedMealSortCriterion(
    _PreparedMealSortCriterion criterion,
  ) {
    return switch (criterion) {
      _PreparedMealSortCriterion.added ||
      _PreparedMealSortCriterion.eaten => false,
      _PreparedMealSortCriterion.alphabetical => true,
      _PreparedMealSortCriterion.quantity => true,
    };
  }

  PreparedMealSortMode _preparedMealSortModeFor(
    _PreparedMealSortCriterion criterion, {
    required bool ascending,
  }) {
    return switch ((criterion, ascending)) {
      (_PreparedMealSortCriterion.added, true) =>
        PreparedMealSortMode.addedAscending,
      (_PreparedMealSortCriterion.added, false) =>
        PreparedMealSortMode.addedDescending,
      (_PreparedMealSortCriterion.eaten, true) =>
        PreparedMealSortMode.eatenAscending,
      (_PreparedMealSortCriterion.eaten, false) =>
        PreparedMealSortMode.eatenDescending,
      (_PreparedMealSortCriterion.alphabetical, true) =>
        PreparedMealSortMode.alphabeticalAscending,
      (_PreparedMealSortCriterion.alphabetical, false) =>
        PreparedMealSortMode.alphabeticalDescending,
      (_PreparedMealSortCriterion.quantity, true) =>
        PreparedMealSortMode.quantityAscending,
      (_PreparedMealSortCriterion.quantity, false) =>
        PreparedMealSortMode.quantityDescending,
    };
  }

  String _preparedMealSortDirectionLabel(
    AppLocalizations l10n, {
    required _PreparedMealSortCriterion criterion,
    required bool ascending,
  }) {
    if (criterion == _PreparedMealSortCriterion.alphabetical) {
      return ascending
          ? l10n.inventorySortDirectionAlphaAscending
          : l10n.inventorySortDirectionAlphaDescending;
    }

    return ascending
        ? l10n.inventorySortDirectionAscending
        : l10n.inventorySortDirectionDescending;
  }

  String _preparedMealSortCriterionLabel(
    AppLocalizations l10n,
    _PreparedMealSortCriterion criterion,
  ) {
    return switch (criterion) {
      _PreparedMealSortCriterion.added => l10n.inventorySortAdded,
      _PreparedMealSortCriterion.eaten => l10n.inventorySortEaten,
      _PreparedMealSortCriterion.alphabetical => l10n.inventorySortAlphabetical,
      _PreparedMealSortCriterion.quantity => l10n.inventorySortQuantity,
    };
  }

  List<PreparedMeal> _sortPreparedMeals(List<PreparedMeal> meals) {
    meals.sort((left, right) {
      final normalizedLeftName = left.name.toLowerCase();
      final normalizedRightName = right.name.toLowerCase();
      final nameCompare = normalizedLeftName.compareTo(normalizedRightName);
      final dateCompare = left.createdAt.compareTo(right.createdAt);
      final updatedCompare = left.updatedAt.compareTo(right.updatedAt);
      final ratioCompare = left.remainingRatio.compareTo(right.remainingRatio);
      final portionsCompare = left.remainingPortions.compareTo(
        right.remainingPortions,
      );

      return switch (_preparedMealSortMode) {
        PreparedMealSortMode.addedDescending =>
          dateCompare != 0 ? -dateCompare : nameCompare,
        PreparedMealSortMode.addedAscending =>
          dateCompare != 0 ? dateCompare : nameCompare,
        PreparedMealSortMode.eatenDescending =>
          updatedCompare != 0
              ? -updatedCompare
              : dateCompare != 0
              ? -dateCompare
              : nameCompare,
        PreparedMealSortMode.eatenAscending =>
          updatedCompare != 0
              ? updatedCompare
              : dateCompare != 0
              ? dateCompare
              : nameCompare,
        PreparedMealSortMode.alphabeticalAscending =>
          nameCompare != 0 ? nameCompare : -dateCompare,
        PreparedMealSortMode.alphabeticalDescending =>
          nameCompare != 0 ? -nameCompare : -dateCompare,
        PreparedMealSortMode.quantityAscending =>
          ratioCompare != 0
              ? ratioCompare
              : portionsCompare != 0
              ? portionsCompare
              : nameCompare,
        PreparedMealSortMode.quantityDescending =>
          ratioCompare != 0
              ? -ratioCompare
              : portionsCompare != 0
              ? -portionsCompare
              : nameCompare,
      };
    });
    return meals;
  }
}
