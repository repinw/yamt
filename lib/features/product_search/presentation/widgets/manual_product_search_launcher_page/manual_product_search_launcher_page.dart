import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_scanner_page.dart';
import 'package:yamt/features/product_search/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_barcode_scan_result.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_search_form.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_types.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'product_ai_search_page/product_ai_search_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _manualProductPageLogName = 'InventoryReceiptManualProductPage';

/// Launcher surface for manual product search entry points.
@Dependencies([
  inventoryManualAddQuickEatConfig,
  manualProductRecentItemsService,
])
class InventoryReceiptManualProductLauncherPage extends ConsumerStatefulWidget {
  /// Creates a manual product launcher page.
  const InventoryReceiptManualProductLauncherPage({
    required this.config,
    required this.showEatImmediatelyOption,
    required this.initialIntent,
    this.onSaved,
    super.key,
  });

  /// Product search configuration.
  final InventoryReceiptManualProductConfig config;

  /// Whether the user can complete the flow as an immediate eat action.
  final bool showEatImmediatelyOption;

  /// Optional action to start immediately after the launcher mounts.
  final InventoryReceiptManualProductInitialIntent initialIntent;

  /// Called when a child flow saves a product.
  final Future<void> Function(InventoryReceiptManualProductResult result)?
  onSaved;

  @override
  ConsumerState<InventoryReceiptManualProductLauncherPage> createState() =>
      _InventoryReceiptManualProductLauncherPageState();
}

class _InventoryReceiptManualProductLauncherPageState
    extends ConsumerState<InventoryReceiptManualProductLauncherPage> {
  late final TextEditingController _searchController;
  List<InventoryItem> _recentItems = const <InventoryItem>[];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: buildManualProductInitialSearchQuery(widget.config) ?? '',
    );
    unawaited(_loadRecentItems());
    if (widget.initialIntent !=
        InventoryReceiptManualProductInitialIntent.launcher) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        switch (widget.initialIntent) {
          case InventoryReceiptManualProductInitialIntent.manualSearch:
            unawaited(_openSearchEditor());
          case InventoryReceiptManualProductInitialIntent.aiSuggestion:
            unawaited(_openAiSearchPage());
          case InventoryReceiptManualProductInitialIntent.barcodeScan:
            unawaited(_openBarcodeScanner());
          case InventoryReceiptManualProductInitialIntent.launcher:
            break;
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final quickEatConfig = ref.watch(
      inventoryManualAddQuickEatConfigProvider,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: InventoryReceiptManualProductLauncherContent(
        title: l10n.inventoryManualAddSearchDialogTitle,
        searchController: _searchController,
        recentItems: _recentItems,
        onClose: _closePage,
        onAiSearchTap: () {
          unawaited(_openAiSearchPage());
        },
        onSearchTap: () {
          unawaited(_openSearchEditor());
        },
        onVoiceSearchTap: () {
          unawaited(_openVoiceSearchEditor());
        },
        onRecentItemSelected: (item) {
          unawaited(_openRecentItemEditor(item));
        },
        onRecentItemStoreSelected: widget.showEatImmediatelyOption
            ? quickEatConfig.quickEatOnly
                  ? null
                  : _handleRecentItemStoreSelected
            : null,
        onRecentItemEatSelected: widget.showEatImmediatelyOption
            ? _handleRecentItemEatSelected
            : null,
        showRecentItemActions: widget.showEatImmediatelyOption,
        onScanBarcode: () {
          unawaited(_openBarcodeScanner());
        },
      ),
    );
  }

  Future<void> _loadRecentItems() async {
    try {
      final recentItemsService = ref.read(
        manualProductRecentItemsServiceProvider,
      );
      final items = await recentItemsService.readRecentItems();
      if (!mounted) {
        return;
      }
      setState(() {
        _recentItems = items;
      });
    } on Object catch (error, stackTrace) {
      log(
        'Failed to load recent manual product items.',
        name: _manualProductPageLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _openSearchEditor() async {
    await _openEditor(autofocusSearch: true);
  }

  Future<void> _openVoiceSearchEditor() async {
    await _openEditor(autofocusSearch: true, initialStartVoiceSearch: true);
  }

  Future<void> _openAiSearchPage() async {
    final quickEatConfig = ref.read(inventoryManualAddQuickEatConfigProvider);
    final result =
        await pushManualProductSearchPage<ManualProductAiSearchResult>(
          context: context,
          args: ManualProductSearchRouteArgs.aiSearch(
            item: widget.config.item,
            initialPrompt: _searchController.text,
            showEatImmediatelyOption: widget.showEatImmediatelyOption,
            initialAction: quickEatConfig.quickEatOnly
                ? InventoryReceiptManualProductAction.eatNow
                : InventoryReceiptManualProductAction.addToInventory,
          ),
        );
    if (!mounted || result == null) {
      return;
    }

    await _completeSelectedResult(
      InventoryReceiptManualProductResult(
        item: result.item,
        action: result.action,
        globalPackageWeight: result.globalPackageWeight,
        skipMissingBarcodePrompt: true,
        eatSelection: result.eatSelection,
      ),
    );
  }

  Future<void> _openRecentItemEditor(InventoryItem item) async {
    await _openEditor(initialRecentItem: item);
  }

  void _handleRecentItemStoreSelected(InventoryItem item) {
    unawaited(
      _handleRecentItemActionSelected(
        item,
        InventoryReceiptManualProductAction.addToInventory,
      ),
    );
  }

  void _handleRecentItemEatSelected(InventoryItem item) {
    unawaited(
      _handleRecentItemActionSelected(
        item,
        InventoryReceiptManualProductAction.eatNow,
      ),
    );
  }

  Future<void> _handleRecentItemActionSelected(
    InventoryItem item,
    InventoryReceiptManualProductAction action,
  ) async {
    final directResult = action == InventoryReceiptManualProductAction.eatNow
        ? _directResultForRecentItem(item)
        : null;
    if (directResult != null) {
      await _completeSelectedResult(directResult);
      return;
    }

    await _openEditor(
      initialRecentItem: item,
      initialAction: action,
      showActionSelector: false,
      initialInfoMessage: action == InventoryReceiptManualProductAction.eatNow
          ? AppLocalizations.of(
              context,
            )!.inventoryManualAddEatNowRequiresNutrition
          : null,
    );
  }

  Future<void> _openEditor({
    InventoryItem? itemOverride,
    OffProductSearchResult? selectedProduct,
    InventoryItem? initialRecentItem,
    bool autofocusSearch = false,
    bool initialStartVoiceSearch = false,
    String? initialInfoMessage,
    InventoryReceiptManualProductAction initialAction =
        InventoryReceiptManualProductAction.addToInventory,
    bool showActionSelector = true,
  }) async {
    final config = InventoryReceiptManualProductConfig(
      item: itemOverride ?? widget.config.item,
      selectedProduct: selectedProduct,
      includeStoreInSearch: widget.config.includeStoreInSearch,
      includeWeightInSearch: widget.config.includeWeightInSearch,
    );
    final keepEditorOpenOnSave = autofocusSearch && widget.onSaved != null;
    final onSavedHandlerId = keepEditorOpenOnSave
        ? registerManualProductSearchRouteSaveHandler(
            _handleNestedEditorSaved,
          )
        : null;
    InventoryReceiptManualProductResult? result;
    try {
      result =
          await pushManualProductSearchPage<
            InventoryReceiptManualProductResult
          >(
            context: context,
            args: ManualProductSearchRouteArgs.editor(
              config: config,
              showEatImmediatelyOption: widget.showEatImmediatelyOption,
              initialAction: initialAction,
              closeCurrentEditorOnSave: !autofocusSearch,
              showActionSelector: showActionSelector,
              autofocusSearch: autofocusSearch,
              initialStartVoiceSearch: initialStartVoiceSearch,
              initialRecentItem: initialRecentItem,
              initialInfoMessage: initialInfoMessage,
              onSavedHandlerId: onSavedHandlerId,
            ),
          );
    } finally {
      unregisterManualProductSearchRouteSaveHandler(onSavedHandlerId);
    }
    if (!mounted || result == null) {
      return;
    }

    final onSaved = widget.onSaved;
    if (onSaved != null) {
      await onSaved(result);
      return;
    }
    _closePage(result);
  }

  Future<void> _handleNestedEditorSaved(
    InventoryReceiptManualProductResult result,
  ) async {
    if (!mounted) {
      return;
    }
    final onSaved = widget.onSaved;
    if (onSaved == null) {
      return;
    }
    await onSaved(result);
  }

  Future<void> _openBarcodeScanner() async {
    final l10n = AppLocalizations.of(context)!;
    final quickEatConfig = ref.read(inventoryManualAddQuickEatConfigProvider);
    final result = await showModalBottomSheet<ManualBarcodeScanResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 1,
          child: InventoryBarcodeScannerPage(
            title: l10n.inventoryManualAddScanBarcodeAction,
            showActionButtons: widget.showEatImmediatelyOption,
            onProductSelected: (candidate, scannedBarcode, action) async {
              sheetContext.pop(
                ManualBarcodeScanResult.selected(
                  candidate: candidate,
                  scannedBarcode: scannedBarcode,
                  action: action,
                ),
              );
              return true;
            },
            onProductNotFound: (scannedBarcode) async {
              sheetContext.pop(
                ManualBarcodeScanResult.notFound(
                  scannedBarcode: scannedBarcode,
                ),
              );
              return true;
            },
            eatOnly: quickEatConfig.quickEatOnly,
          ),
        );
      },
    );
    if (!mounted || result == null) {
      return;
    }

    switch (result.kind) {
      case ManualBarcodeScanResultKind.selected:
        final candidate = result.candidate;
        if (candidate == null) {
          return;
        }
        final action = manualProductActionFromBarcodeAction(result.action);
        final selectedProduct = candidate.externalProduct;
        if (selectedProduct != null) {
          final directResult = _directResultForSelectedProduct(
            product: selectedProduct,
            action: action,
          );
          if (directResult != null) {
            await _completeSelectedResult(directResult);
            return;
          }
          await _openEditor(
            selectedProduct: selectedProduct,
            initialAction: action,
            showActionSelector: false,
            initialInfoMessage:
                action == InventoryReceiptManualProductAction.eatNow
                ? l10n.inventoryManualAddEatNowRequiresNutrition
                : null,
          );
          return;
        }

        final globalFoodItem = candidate.globalFoodItem;
        if (globalFoodItem == null) {
          return;
        }
        final selectedItem = inventoryItemFromBarcodeCandidate(
          baseItem: widget.config.item,
          globalFoodItem: globalFoodItem,
          barcode: result.scannedBarcode ?? candidate.barcode,
        );
        final directResult = _directResultForInventoryItem(
          item: selectedItem,
          action: action,
          selectedGlobalFoodItemId: candidate.globalFoodItemId,
          globalPackageWeight: candidate.packageWeight,
        );
        if (directResult != null) {
          await _completeSelectedResult(directResult);
          return;
        }
        await _openEditor(
          itemOverride: selectedItem,
          initialRecentItem: selectedItem,
          initialAction: action,
          showActionSelector: false,
          initialInfoMessage:
              action == InventoryReceiptManualProductAction.eatNow
              ? l10n.inventoryManualAddEatNowRequiresNutrition
              : null,
        );
      case ManualBarcodeScanResultKind.notFound:
        final scannedBarcode = result.scannedBarcode;
        if (scannedBarcode == null || scannedBarcode.isEmpty) {
          return;
        }
        await _openEditor(
          itemOverride: widget.config.item.copyWith(barcode: scannedBarcode),
          initialInfoMessage: l10n.inventoryManualAddNotFound,
        );
    }
  }

  InventoryReceiptManualProductResult? _directResultForSelectedProduct({
    required OffProductSearchResult product,
    required InventoryReceiptManualProductAction action,
  }) {
    if (action != InventoryReceiptManualProductAction.eatNow) {
      return null;
    }
    final config = InventoryReceiptManualProductConfig(
      item: widget.config.item,
      selectedProduct: product,
      includeStoreInSearch: widget.config.includeStoreInSearch,
      includeWeightInSearch: widget.config.includeWeightInSearch,
    );
    final controller = ref.read(
      inventoryReceiptManualProductControllerProvider(config).notifier,
    );
    final payload = controller.buildDirectSearchResultPayload(
      product: product,
      action: action,
    );
    if (payload == null) {
      return null;
    }
    return InventoryReceiptManualProductResult(
      item: payload.item,
      action: action,
      selectedProduct: payload.selectedProduct,
      selectedGlobalFoodItemId: payload.selectedGlobalFoodItemId,
      requiresGlobalPersistence: payload.requiresGlobalPersistence,
      globalPackageWeight: payload.globalPackageWeight,
    );
  }

  InventoryReceiptManualProductResult? _directResultForInventoryItem({
    required InventoryItem item,
    required InventoryReceiptManualProductAction action,
    required String? selectedGlobalFoodItemId,
    required String? globalPackageWeight,
  }) {
    if (action != InventoryReceiptManualProductAction.eatNow ||
        item.nutrition?.hasAnyNutritionValue != true) {
      return null;
    }
    return InventoryReceiptManualProductResult(
      item: item,
      action: action,
      selectedGlobalFoodItemId: selectedGlobalFoodItemId,
      requiresGlobalPersistence: false,
      globalPackageWeight: globalPackageWeight,
    );
  }

  InventoryReceiptManualProductResult? _directResultForRecentItem(
    InventoryItem item,
  ) {
    return _directResultForInventoryItem(
      item: item,
      action: InventoryReceiptManualProductAction.eatNow,
      selectedGlobalFoodItemId: manualProductRecentItemGlobalFoodItemId(item),
      globalPackageWeight: item.weight,
    );
  }

  Future<void> _completeSelectedResult(
    InventoryReceiptManualProductResult result,
  ) async {
    if (!mounted) {
      return;
    }
    final onSaved = widget.onSaved;
    if (onSaved != null) {
      await onSaved(result);
      return;
    }
    _closePage(result);
  }

  void _closePage<T extends Object?>([T? result]) {
    if (!mounted) {
      return;
    }

    popManualProductSearchPage(context, result);
  }
}
