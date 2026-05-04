import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_item_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_dialogs.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_list/inventory_item_row/inventory_item_eat_sheet.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/product_search/domain/'
    'manual_product_eat_selection.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page.dart';
import 'package:yamt/features/product_search/provider/'
    'manual_product_search_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _inventoryManualAddItemId = Uuid();
const _inventoryManualAddGlobalFoodItemId = Uuid();
const _inventoryAmountParser = InventoryAmountParser();

/// Initial action for inventory manual add route.
enum InventoryManualAddInitialAction {
  /// Show the manual add launcher.
  launcher,

  /// Open manual search immediately.
  manualSearch,

  /// Open AI suggestion immediately.
  aiSuggestion,
}

/// Resolve inventory manual add eat flow max amount.
@visibleForTesting
int? resolveInventoryManualAddEatFlowMaxAmount(InventoryItem item) {
  if (item.usesAmountProgress) {
    if (item.amountUnit == null || item.currentAmount < 1) {
      return null;
    }
    return item.currentAmount;
  }
  if (item.quantity < 1) {
    return null;
  }
  return item.quantity;
}

/// Complete inventory manual-add eat flow.
@visibleForTesting
@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
Future<void> completeInventoryManualAddEatFlow({
  required BuildContext context,
  required WidgetRef ref,
  required InventoryItem item,
  required InventoryItemEatRequest request,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final maxAmount = resolveInventoryManualAddEatFlowMaxAmount(item);
  if (maxAmount == null ||
      request.inventoryAmount < 1 ||
      request.inventoryAmount > maxAmount) {
    _showInventoryManualAddSnackBar(
      context: context,
      message: l10n.inventoryItemActionFailed,
    );
    return;
  }

  final inventoryController = ref.read(
    inventoryItemsControllerProvider.notifier,
  );
  final pendingConsumption = await inventoryController.stagePendingConsumption(
    item.id,
    request.inventoryAmount,
  );
  if (pendingConsumption == null) {
    if (context.mounted) {
      _showInventoryManualAddSnackBar(
        context: context,
        message: l10n.inventoryItemActionFailed,
      );
    }
    return;
  }
  if (!context.mounted) {
    await inventoryController.discardPendingConsumption(
      pendingConsumption.id,
    );
    return;
  }

  await InventoryItemEatFlow.complete(
    context: context,
    ref: ref,
    itemBeforeMutation: item,
    request: request,
    pendingConsumptionId: pendingConsumption.id,
  );
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
  });

  /// Initial action for the manual add flow.
  final InventoryManualAddInitialAction initialAction;

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
    _draftItem = _buildDraftItem(
      scannedBarcode: '',
      now: DateTime.now(),
      name: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return InventoryReceiptManualProductPage(
      item: _draftItem,
      showEatImmediatelyOption: true,
      initialIntent: _initialIntentFor(widget.initialAction),
      onSaved: _saveSheetResult,
    );
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
    };
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

    if (result.action == InventoryReceiptManualProductAction.eatNow) {
      _closeEditorsIfNeeded();
    }
    if (!mounted) {
      return;
    }

    if (result.action == InventoryReceiptManualProductAction.eatNow) {
      final eatRequest = _eatRequestFromAiSelection(result.eatSelection);
      if (eatRequest == null) {
        await _openImmediateEatFlow(
          savedItem,
          initialEatWeight: savedItem.weight,
        );
      } else {
        await _completeImmediateEatFlow(savedItem, eatRequest);
      }
      if (!mounted) {
        return;
      }
    }
  }

  Future<InventoryItem?> _resolveEatItem(InventoryItem item) async {
    if (!_requiresEatAmountPrompt(item)) {
      return item;
    }

    final eatAmount = await showInventoryManualAddEatAmountDialog(
      context: context,
      initialUnit: _defaultEatAmountUnit(item),
    );
    if (!mounted || eatAmount == null) {
      return null;
    }

    final amountScale = eatAmount.unit == InventoryAmountUnit.piece
        ? inventoryPieceAmountScale
        : 1;
    final weight =
        '${formatInventoryAmountValue(
          amount: eatAmount.amount,
          unit: eatAmount.unit,
          scale: amountScale,
        )} ${eatAmount.unit.code}';
    final parsedAmount = InventoryAmountParseResult(
      amount: eatAmount.amount,
      unit: eatAmount.unit,
      scale: amountScale,
    );
    return item.withResolvedAmount(
      weight: weight,
      parsedAmount: parsedAmount,
      quantity: item.quantity,
    );
  }

  InventoryItemEatRequest? _eatRequestFromAiSelection(
    ManualProductEatSelection? selection,
  ) {
    if (selection == null) {
      return null;
    }
    return InventoryItemEatRequest(
      inventoryAmount: selection.inventoryAmount,
      loggedAt: selection.loggedAt,
      mealType: selection.mealType,
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

  bool _requiresEatAmountPrompt(InventoryItem item) {
    return item.weight == null ||
        item.amountUnit == null ||
        item.initialAmount < 1;
  }

  void _closeEditorsIfNeeded() {
    final route = ModalRoute.of(context);
    if (route == null || route.isCurrent) {
      return;
    }
    Navigator.of(context).popUntil((candidate) => candidate == route);
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
    final l10n = AppLocalizations.of(context)!;
    final globalProduct = _buildGlobalFoodItem(
      item: item,
      barcode: barcode,
      now: now,
      selectedProduct: selectedProduct,
      selectedGlobalFoodItemId: selectedGlobalFoodItemId,
      packageWeight: globalPackageWeight,
    );

    final globalSaved =
        !requiresGlobalPersistence ||
        await ref.read(globalFoodItemRepositoryProvider).appendAll(
          <GlobalFoodItem>[globalProduct],
        );

    final inventoryWeight = _resolveInventoryWeight(
      packageWeight: item.weight,
    );
    final savedItem = InventoryItem.create(
      id: _inventoryManualAddItemId.v4(),
      globalFoodItemId: globalSaved ? globalProduct.id : null,
      name: globalProduct.name,
      entryDate: now,
      storeName: l10n.inventoryManualAddStoreName,
      origin: InventoryItemOrigin.manualAdd,
      quantity: 1,
      brand: globalProduct.brand,
      barcode: globalProduct.barcode,
      imageUrl: globalProduct.imageUrl,
      servingSize: globalProduct.servingSize,
      servingQuantity: globalProduct.servingQuantity,
      servingQuantityUnit: globalProduct.servingQuantityUnit,
      nutrition: globalProduct.nutrition,
      weight: inventoryWeight,
      foodFingerprint: globalProduct.resolvedFoodFingerprint,
    ).withDerivedAmount(weight: inventoryWeight, quantity: 1);

    final inventorySaved = await ref
        .read(inventoryItemsControllerProvider.notifier)
        .addItem(savedItem);
    if (!inventorySaved) {
      return null;
    }
    if (globalSaved && barcode != null) {
      await ref
          .read(globalBarcodeCandidateRepositoryProvider)
          .recordSelection(
            barcode: barcode,
            globalFoodItem: globalProduct,
            selectedAt: now,
          );
    }
    return savedItem;
  }

  InventoryItem _buildDraftItem({
    required String scannedBarcode,
    required DateTime now,
    required String name,
    String? brand,
    String? imageUrl,
    String? weight,
    String? servingSize,
    double? servingQuantity,
    String? servingQuantityUnit,
    GlobalFoodNutrition? nutrition,
  }) {
    return InventoryItem.create(
      id: _inventoryManualAddItemId.v4(),
      name: name,
      entryDate: now,
      storeName: AppLocalizations.of(context)!.inventoryManualAddStoreName,
      origin: InventoryItemOrigin.manualAdd,
      quantity: 1,
      brand: brand,
      barcode: scannedBarcode,
      imageUrl: imageUrl,
      servingSize: servingSize,
      servingQuantity: servingQuantity,
      servingQuantityUnit: servingQuantityUnit,
      nutrition: nutrition,
      weight: weight,
    ).withDerivedAmount(weight: weight, quantity: 1);
  }

  GlobalFoodItem _buildGlobalFoodItem({
    required InventoryItem item,
    required String? barcode,
    required DateTime now,
    required String? packageWeight,
    OffProductSearchResult? selectedProduct,
    String? selectedGlobalFoodItemId,
  }) {
    return GlobalFoodItem.create(
      id:
          selectedGlobalFoodItemId ??
          _selectedProductGlobalFoodItemId(
            selectedProduct: selectedProduct,
            barcode: barcode,
          ) ??
          _globalFoodItemIdFor(item, barcode: barcode),
      name: item.name,
      now: now,
      brand: item.brand,
      barcode: barcode,
      imageUrl: normalizeProductImageUrl(item.imageUrl),
      packageWeight: packageWeight,
      servingSize: item.servingSize ?? selectedProduct?.servingSize,
      servingQuantity: item.servingQuantity ?? selectedProduct?.servingQuantity,
      servingQuantityUnit:
          item.servingQuantityUnit ?? selectedProduct?.servingQuantityUnit,
      nutrition: item.nutrition,
    );
  }

  String? _selectedProductGlobalFoodItemId({
    required OffProductSearchResult? selectedProduct,
    required String? barcode,
  }) {
    if (selectedProduct == null) {
      return null;
    }
    final normalizedBarcode = selectedProduct.code.trim().isEmpty
        ? barcode
        : selectedProduct.code;
    if (normalizedBarcode == null || normalizedBarcode.isEmpty) {
      return null;
    }
    return 'off-$normalizedBarcode';
  }

  String _globalFoodItemIdFor(InventoryItem item, {required String? barcode}) {
    if (barcode == null || barcode.isEmpty) {
      return 'manual-food-${_inventoryManualAddGlobalFoodItemId.v4()}';
    }
    final normalizedName = normalizeGlobalFoodText(item.name);
    final normalizedBrand = normalizeGlobalFoodText(item.brand ?? '');
    final suffix = <String>[
      normalizedName,
      normalizedBrand,
    ].where((value) => value.isNotEmpty).join('-');
    if (suffix.isEmpty) {
      return 'off-$barcode';
    }
    return 'off-$barcode-$suffix';
  }

  Future<void> _openImmediateEatFlow(
    InventoryItem item, {
    String? initialEatWeight,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final maxAmount = resolveInventoryManualAddEatFlowMaxAmount(item);
    if (maxAmount == null) {
      _showSnackBar(l10n.inventoryItemActionFailed);
      return;
    }

    final request = await showInventoryItemEatSheet(
      context: context,
      item: item,
      maxAmount: maxAmount,
      invalidAmountMessage: l10n.inventoryReceiptReviewInvalidNumber,
      initialInventoryAmount: _resolveInitialEatAmount(
        item: item,
        rawWeight: initialEatWeight,
      ),
    );
    if (!mounted || request == null) {
      return;
    }

    await _completeImmediateEatFlow(item, request);
  }

  Future<void> _completeImmediateEatFlow(
    InventoryItem item,
    InventoryItemEatRequest request,
  ) async {
    await completeInventoryManualAddEatFlow(
      context: context,
      ref: ref,
      item: item,
      request: request,
    );
  }

  void _showSnackBar(String message) {
    _showInventoryManualAddSnackBar(context: context, message: message);
  }

  InventoryAmountUnit _defaultEatAmountUnit(InventoryItem item) {
    if (item.amountUnit case final InventoryAmountUnit unit) {
      return unit;
    }

    final combinedHint = <String>[
      item.servingSize ?? '',
      item.servingQuantityUnit ?? '',
    ].join(' ').toLowerCase();
    if (combinedHint.contains('ml') ||
        RegExp(r'(^|\s)l\b').hasMatch(combinedHint)) {
      return InventoryAmountUnit.milliliter;
    }
    if (combinedHint.contains('stk') ||
        combinedHint.contains('stück') ||
        combinedHint.contains('pc')) {
      return InventoryAmountUnit.piece;
    }
    return InventoryAmountUnit.gram;
  }

  String? _resolveInventoryWeight({
    required String? packageWeight,
  }) {
    final normalizedPackageWeight = packageWeight?.trim();
    if (normalizedPackageWeight != null && normalizedPackageWeight.isNotEmpty) {
      return normalizedPackageWeight;
    }
    return null;
  }

  int? _resolveInitialEatAmount({
    required InventoryItem item,
    required String? rawWeight,
  }) {
    final amountUnit = item.amountUnit;
    if (amountUnit == null) {
      return null;
    }
    final parsed = _inventoryAmountParser.tryParse(
      rawWeight: rawWeight,
      quantity: 1,
      fallbackUnit: amountUnit,
    );
    if (parsed == null || parsed.unit != amountUnit || parsed.amount < 1) {
      return null;
    }
    return parsed.amount;
  }
}

void _showInventoryManualAddSnackBar({
  required BuildContext context,
  required String message,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _ManualBarcodePromptResult {
  const _ManualBarcodePromptResult({
    required this.item,
    required this.barcode,
  });

  final InventoryItem item;
  final String? barcode;
}
