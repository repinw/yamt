import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_manual_add_product_factory.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_manual_add_amount_service.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_dialogs.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_manual_add_initial_action.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_list/inventory_item_row/inventory_item_eat_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_manual_add_product_page.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_types.dart';
import 'package:yamt/features/product_search/provider/'
    'manual_product_search_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

export 'package:yamt/features/inventory/presentation/models/'
    'inventory_manual_add_initial_action.dart'
    show InventoryManualAddInitialAction;

const _inventoryManualAddItemId = Uuid();
const _inventoryManualAddGlobalFoodItemId = Uuid();

/// Route args for inventory manual add.
class InventoryManualAddRouteArgs {
  /// Creates route args.
  const InventoryManualAddRouteArgs({
    this.initialAction = InventoryManualAddInitialAction.launcher,
    this.quickEatOnly = false,
    this.preselectedMealType,
    this.preselectedLoggedAt,
  });

  /// Initial action for the manual add flow.
  final InventoryManualAddInitialAction initialAction;

  /// Whether only eat actions should be shown.
  final bool quickEatOnly;

  /// Preselected meal type for eat flow.
  final MealType? preselectedMealType;

  /// Preselected logged-at for eat flow.
  final DateTime? preselectedLoggedAt;
}

/// Defines inventory manual add page.
@Dependencies([
  inventoryItemRepository,
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
class InventoryManualAddPage extends ConsumerStatefulWidget {
  /// The inventory manual add page.
  const InventoryManualAddPage({
    super.key,
    this.initialAction = InventoryManualAddInitialAction.launcher,
    this.quickEatOnly = false,
    this.preselectedMealType,
    this.preselectedLoggedAt,
  });

  /// Initial action for the manual add flow.
  final InventoryManualAddInitialAction initialAction;

  /// Whether only eat actions should be shown.
  final bool quickEatOnly;

  /// Preselected meal type.
  final MealType? preselectedMealType;

  /// Preselected logged-at.
  final DateTime? preselectedLoggedAt;

  @override
  ConsumerState<InventoryManualAddPage> createState() {
    return _InventoryManualAddPageState();
  }
}

class _InventoryManualAddPageState
    extends ConsumerState<InventoryManualAddPage> {
  bool _hasInitializedDraft = false;
  late InventoryItem _draftItem;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitializedDraft) {
      return;
    }
    _hasInitializedDraft = true;
    _draftItem = buildInventoryManualAddDraftItem(
      id: _inventoryManualAddItemId.v4(),
      scannedBarcode: '',
      now: DateTime.now(),
      name: '',
      storeName: AppLocalizations.of(context)!.inventoryManualAddStoreName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final quickEatConfig = _quickEatConfig;
    return ProviderScope(
      overrides: [
        inventoryManualAddQuickEatConfigProvider.overrideWithValue(
          quickEatConfig,
        ),
      ],
      child: InventoryManualAddProductPage(
        item: _draftItem,
        initialIntent: _initialIntentFor(widget.initialAction),
        initialAction: quickEatConfig.quickEatOnly
            ? InventoryReceiptManualProductAction.eatNow
            : InventoryReceiptManualProductAction.addToInventory,
        onSaved: _saveSheetResult,
      ),
    );
  }

  Future<void> _saveSheetResult(
    InventoryReceiptManualProductResult result,
  ) async {
    if (!mounted) {
      return;
    }

    var itemToSave = result.item;
    if (result.action == InventoryReceiptManualProductAction.eatNow) {
      final resolvedEatItem = await _resolveEatItem(result.item);
      if (!mounted || resolvedEatItem == null) {
        return;
      }
      itemToSave = resolvedEatItem;
    }
    final promptResult = result.skipMissingBarcodePrompt
        ? _ManualBarcodePromptResult(
            item: itemToSave,
            barcode: itemToSave.normalizedBarcode,
          )
        : await _resolveMissingBarcode(itemToSave);
    if (!mounted || promptResult == null) {
      return;
    }
    itemToSave = promptResult.item;

    final savedItem = await _persistProduct(
      item: itemToSave,
      barcode: promptResult.barcode,
      selectedProduct: result.selectedProduct,
      selectedGlobalFoodItemId: result.selectedGlobalFoodItemId,
      requiresGlobalPersistence: result.requiresGlobalPersistence,
      globalPackageWeight: result.globalPackageWeight,
    );
    if (!mounted) {
      return;
    }
    if (savedItem == null) {
      _showSnackBar(AppLocalizations.of(context)!.inventoryManualAddSaveFailed);
      return;
    }

    if (result.action == InventoryReceiptManualProductAction.addToInventory) {
      _showSnackBar(AppLocalizations.of(context)!.inventoryManualAddSaved);
      return;
    }

    _closeEditorsIfNeeded();
    if (!mounted) {
      return;
    }

    final eatRequest = inventoryManualAddEatRequestFromSelection(
      result.eatSelection,
    );
    if (eatRequest == null) {
      await _openImmediateEatFlow(
        savedItem,
        initialEatWeight: savedItem.weight,
      );
      return;
    }

    await _completeImmediateEatFlow(savedItem, eatRequest);
  }

  Future<InventoryItem?> _resolveEatItem(InventoryItem item) async {
    if (!requiresInventoryManualAddConsumedAmountPrompt(item)) {
      return item;
    }

    final eatAmount = await showInventoryManualAddEatAmountDialog(
      context: context,
      initialUnit: defaultInventoryManualAddConsumedAmountUnit(item),
    );
    if (!mounted || eatAmount == null) {
      return null;
    }

    return resolveInventoryManualAddItemAmount(
      item: item,
      amount: eatAmount.amount,
      unit: eatAmount.unit,
    );
  }

  Future<_ManualBarcodePromptResult?> _resolveMissingBarcode(
    InventoryItem item,
  ) async {
    final currentBarcode = item.normalizedBarcode;
    if (currentBarcode != null) {
      return _ManualBarcodePromptResult(item: item, barcode: currentBarcode);
    }

    final enteredBarcode = await showInventoryManualAddMissingBarcodeDialog(
      context: context,
    );
    if (!mounted || enteredBarcode == null) {
      return null;
    }
    if (enteredBarcode.isEmpty) {
      return _ManualBarcodePromptResult(item: item, barcode: null);
    }

    final updatedItem = item.copyWith(barcode: enteredBarcode);
    return _ManualBarcodePromptResult(
      item: updatedItem,
      barcode: updatedItem.normalizedBarcode,
    );
  }

  Future<InventoryItem?> _persistProduct({
    required InventoryItem item,
    required String? barcode,
    required bool requiresGlobalPersistence,
    OffProductSearchResult? selectedProduct,
    String? selectedGlobalFoodItemId,
    String? globalPackageWeight,
  }) async {
    final now = DateTime.now();
    final storeName = AppLocalizations.of(context)!.inventoryManualAddStoreName;
    final globalFoodItemRepository = ref.read(globalFoodItemRepositoryProvider);
    final inventoryItemsController = ref.read(
      inventoryItemsControllerProvider.notifier,
    );
    final globalBarcodeCandidateRepository = ref.read(
      globalBarcodeCandidateRepositoryProvider,
    );
    final globalProduct = buildInventoryManualAddGlobalFoodItem(
      item: item,
      barcode: barcode,
      now: now,
      selectedProduct: selectedProduct,
      selectedGlobalFoodItemId: selectedGlobalFoodItemId,
      packageWeight: globalPackageWeight,
      manualGlobalFoodItemId: _inventoryManualAddGlobalFoodItemId.v4(),
    );

    final globalSaved =
        !requiresGlobalPersistence ||
        await globalFoodItemRepository.appendAll([globalProduct]);

    final savedItem = buildInventoryManualAddSavedItem(
      id: _inventoryManualAddItemId.v4(),
      globalProduct: globalProduct,
      globalSaved: globalSaved,
      now: now,
      storeName: storeName,
      inventoryWeight: resolveInventoryManualAddInventoryWeight(item.weight),
    );
    final inventorySaved = await inventoryItemsController.addItem(savedItem);
    if (!inventorySaved) {
      return null;
    }
    if (globalSaved && barcode != null) {
      await globalBarcodeCandidateRepository.recordSelection(
        barcode: barcode,
        globalFoodItem: globalProduct,
        selectedAt: now,
      );
    }
    return savedItem;
  }

  Future<void> _openImmediateEatFlow(
    InventoryItem item, {
    String? initialEatWeight,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final quickEatConfig = _quickEatConfig;
    final maxAmount = resolveInventoryManualAddConsumableAmount(item);
    if (maxAmount == null) {
      _showSnackBar(l10n.inventoryItemActionFailed);
      return;
    }

    final request = await showInventoryItemEatSheet(
      context: context,
      item: item,
      maxAmount: maxAmount,
      invalidAmountMessage: l10n.inventoryReceiptReviewInvalidNumber,
      initialInventoryAmount: resolveInventoryManualAddInitialConsumedAmount(
        item: item,
        rawWeight: initialEatWeight,
      ),
      initialLoggedAt: quickEatConfig.preselectedLoggedAt,
      initialMealType: quickEatConfig.preselectedMealType,
    );
    if (!mounted || request == null) {
      return;
    }

    await _completeImmediateEatFlow(item, request);
  }

  InventoryManualAddQuickEatConfig get _quickEatConfig {
    return InventoryManualAddQuickEatConfig(
      quickEatOnly: widget.quickEatOnly,
      preselectedMealType: widget.preselectedMealType,
      preselectedLoggedAt: widget.preselectedLoggedAt,
    );
  }

  Future<void> _completeImmediateEatFlow(
    InventoryItem item,
    InventoryItemEatRequest request,
  ) async {
    final itemForConsumption = await _prepareImmediateEatItem(
      item: item,
      request: request,
    );
    if (!mounted || itemForConsumption == null) {
      return;
    }
    await completeInventoryManualAddEatFlow(
      context: context,
      ref: ref,
      item: itemForConsumption,
      request: request,
    );
  }

  Future<InventoryItem?> _prepareImmediateEatItem({
    required InventoryItem item,
    required InventoryItemEatRequest request,
  }) async {
    final resizedItem = resizeInventoryManualAddItemToConsumedAmount(
      item: item,
      inventoryAmount: request.inventoryAmount,
    );
    if (resizedItem == item) {
      return item;
    }

    final saved = await ref
        .read(inventoryItemsControllerProvider.notifier)
        .updateItem(resizedItem);
    if (!mounted) {
      return null;
    }
    if (!saved) {
      _showSnackBar(AppLocalizations.of(context)!.inventoryItemActionFailed);
      return null;
    }
    return resizedItem;
  }

  void _closeEditorsIfNeeded() {
    final route = ModalRoute.of(context);
    if (route == null || route.isCurrent) {
      return;
    }
    Navigator.of(context).popUntil((candidate) => candidate == route);
  }

  void _showSnackBar(String message) {
    showInventoryManualAddSnackBar(context: context, message: message);
  }
}

InventoryReceiptManualProductInitialIntent _initialIntentFor(
  InventoryManualAddInitialAction action,
) {
  return switch (action) {
    InventoryManualAddInitialAction.launcher =>
      InventoryReceiptManualProductInitialIntent.launcher,
    InventoryManualAddInitialAction.manualSearch =>
      InventoryReceiptManualProductInitialIntent.manualSearch,
    InventoryManualAddInitialAction.aiSuggestion =>
      InventoryReceiptManualProductInitialIntent.aiSuggestion,
    InventoryManualAddInitialAction.barcodeScan =>
      InventoryReceiptManualProductInitialIntent.barcodeScan,
  };
}

class _ManualBarcodePromptResult {
  const _ManualBarcodePromptResult({
    required this.item,
    required this.barcode,
  });

  final InventoryItem item;
  final String? barcode;
}
