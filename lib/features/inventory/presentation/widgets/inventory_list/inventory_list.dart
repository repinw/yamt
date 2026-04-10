import 'dart:async';
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
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_all_items_sliver.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_consumed_items_toggle.dart';
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
import 'package:yamt/features/product_search/data/'
    'manual_product_speech_service.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'text_voice_search_bar.dart';
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
  final _searchBarKey = GlobalKey<TextVoiceSearchBarState>();
  var _mode = InventoryListMode.allItems;
  var _consumptionFilter = const InventoryConsumptionFilter();
  late final ManualProductSpeechService _speechService;
  late final TextEditingController _searchController;
  var _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _speechService = ref.read(manualProductSpeechServiceProvider);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    unawaited(
      _searchBarKey.currentState?.cancelVoiceSearch() ?? Future<void>.value(),
    );
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
    final filteredItems = _applySearchToItems(
      _consumptionFilter.apply(widget.items),
    );
    final filteredPreparedMeals = _applySearchToPreparedMeals(
      widget.preparedMeals,
    );
    final hasPreparedMeals = filteredPreparedMeals.isNotEmpty;
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
        if (hasAnySourceItems)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: TextVoiceSearchBar(
                key: _searchBarKey,
                controller: _searchController,
                label: l10n.inventorySearchLabel,
                fieldKey: const Key('inventory_list_search_field'),
                voiceButtonKey: const Key('inventory_list_voice_search_button'),
                clearButtonKey: const Key('inventory_list_search_clear_button'),
                enabled: !widget.isSelectionMode,
                onChanged: _onSearchQueryChanged,
                speechService: _speechService,
              ),
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
                children: filteredPreparedMeals
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
                  onPressed: () => _showFiltersSheet(
                    context,
                    title: l10n.inventoryFiltersTitle,
                    l10n: l10n,
                  ),
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
    setState(() {
      _consumptionFilter = _consumptionFilter.copyWith(
        hideFullyConsumedItems: hideFullyConsumedItems,
      );
    });
  }

  void _onSearchQueryChanged(String value) {
    if (_searchQuery == value) {
      return;
    }
    setState(() {
      _searchQuery = value;
    });
  }

  Future<void> _showFiltersSheet(
    BuildContext context, {
    required String title,
    required AppLocalizations l10n,
  }) {
    var hideFullyConsumedItems = _consumptionFilter.hideFullyConsumedItems;

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return InventoryFiltersSheet(
              title: title,
              consumptionToggle: InventoryConsumedItemsToggle(
                value: hideFullyConsumedItems,
                enabled: !widget.isSelectionMode,
                l10n: l10n,
                onChanged: (nextHideFullyConsumedItems) {
                  setModalState(() {
                    hideFullyConsumedItems = nextHideFullyConsumedItems;
                  });
                  _onHideFullyConsumedItemsChanged(nextHideFullyConsumedItems);
                },
              ),
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

  List<InventoryItem> _applySearchToItems(List<InventoryItem> items) {
    final queryTokens = _buildSearchTokens(_searchQuery);
    if (queryTokens.isEmpty) {
      return items;
    }

    return items
        .where((item) {
          return _matchesSearchTokens(
            haystack: _buildInventoryItemSearchText(item),
            queryTokens: queryTokens,
          );
        })
        .toList(growable: false);
  }

  List<PreparedMeal> _applySearchToPreparedMeals(List<PreparedMeal> meals) {
    final queryTokens = _buildSearchTokens(_searchQuery);
    if (queryTokens.isEmpty) {
      return meals;
    }

    return meals
        .where((meal) {
          return _matchesSearchTokens(
            haystack: _buildPreparedMealSearchText(meal),
            queryTokens: queryTokens,
          );
        })
        .toList(growable: false);
  }
}

List<String> _buildSearchTokens(String query) {
  final normalizedQuery = _normalizeSearchText(query);
  if (normalizedQuery.isEmpty) {
    return const <String>[];
  }

  return normalizedQuery
      .split(' ')
      .where((token) => token.isNotEmpty)
      .toList(growable: false);
}

bool _matchesSearchTokens({
  required String haystack,
  required List<String> queryTokens,
}) {
  final normalizedHaystack = _normalizeSearchText(haystack);
  final haystackTokens = normalizedHaystack
      .split(' ')
      .where((token) => token.isNotEmpty)
      .toList(growable: false);
  final compactHaystack = _compactSearchText(normalizedHaystack);

  return queryTokens.every((queryToken) {
    if (normalizedHaystack.contains(queryToken)) {
      return true;
    }

    final compactQueryToken = _compactSearchText(queryToken);
    if (compactQueryToken.isEmpty) {
      return true;
    }
    if (compactHaystack.contains(compactQueryToken)) {
      return true;
    }

    return _hasApproximateCompactMatch(
      compactQueryToken: compactQueryToken,
      haystackTokens: haystackTokens,
    );
  });
}

String _buildInventoryItemSearchText(InventoryItem item) {
  return <String>[
    item.name,
    item.brand ?? '',
    item.category ?? '',
    item.storeName,
    item.weight ?? '',
    item.ocrName ?? '',
    item.normalizedBarcode ?? '',
  ].join(' ');
}

String _buildPreparedMealSearchText(PreparedMeal meal) {
  return <String>[meal.name, ...meal.recipeIngredients].join(' ');
}

String _normalizeSearchText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('ß', 'ss')
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll(RegExp(r'\s+'), ' ');
}

String _compactSearchText(String value) {
  return _normalizeSearchText(value).replaceAll(RegExp(r'[\s\-_/,.;:()]+'), '');
}

bool _hasApproximateCompactMatch({
  required String compactQueryToken,
  required List<String> haystackTokens,
}) {
  if (compactQueryToken.length < 4) {
    return false;
  }

  for (var start = 0; start < haystackTokens.length; start++) {
    var candidate = '';
    for (var end = start; end < haystackTokens.length; end++) {
      candidate += _compactSearchText(haystackTokens[end]);
      final lengthDifference = candidate.length - compactQueryToken.length;
      if (lengthDifference > 1) {
        break;
      }
      if (lengthDifference.abs() > 1) {
        continue;
      }
      if (_isWithinEditDistanceOne(candidate, compactQueryToken)) {
        return true;
      }
      if (end - start >= 2) {
        break;
      }
    }
  }

  return false;
}

bool _isWithinEditDistanceOne(String left, String right) {
  if (left == right) {
    return true;
  }

  final lengthDifference = left.length - right.length;
  if (lengthDifference.abs() > 1) {
    return false;
  }

  if (left.length == right.length) {
    return _isSingleReplacementOrSwap(left, right);
  }

  final longer = lengthDifference > 0 ? left : right;
  final shorter = lengthDifference > 0 ? right : left;
  return _isSingleInsertionOrDeletion(longer, shorter);
}

bool _isSingleReplacementOrSwap(String left, String right) {
  final mismatches = <int>[];

  for (var index = 0; index < left.length; index++) {
    if (left[index] == right[index]) {
      continue;
    }
    mismatches.add(index);
    if (mismatches.length > 2) {
      return false;
    }
  }

  if (mismatches.isEmpty) {
    return true;
  }
  if (mismatches.length == 1) {
    return true;
  }

  final firstMismatch = mismatches[0];
  final secondMismatch = mismatches[1];
  return secondMismatch == firstMismatch + 1 &&
      left[firstMismatch] == right[secondMismatch] &&
      left[secondMismatch] == right[firstMismatch];
}

bool _isSingleInsertionOrDeletion(String longer, String shorter) {
  var longerIndex = 0;
  var shorterIndex = 0;
  var skippedCharacter = false;

  while (longerIndex < longer.length && shorterIndex < shorter.length) {
    if (longer[longerIndex] == shorter[shorterIndex]) {
      longerIndex++;
      shorterIndex++;
      continue;
    }
    if (skippedCharacter) {
      return false;
    }

    skippedCharacter = true;
    longerIndex++;
  }

  return true;
}
