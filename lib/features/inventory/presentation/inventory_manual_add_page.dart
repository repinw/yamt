import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_list/inventory_item_row/inventory_item_eat_sheet.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'inventory_receipt_manual_product_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _inventoryManualAddItemId = Uuid();
const _inventoryAmountParser = InventoryAmountParser();

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

/// Defines inventory manual add page.
@Dependencies([
  inventoryItemRepository,
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
class InventoryManualAddPage extends ConsumerStatefulWidget {
  /// The inventory manual add page.
  const InventoryManualAddPage({super.key});

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
      onSaved: _saveSheetResult,
    );
  }

  Future<void> _saveSheetResult(
    InventoryReceiptManualProductResult result,
  ) async {
    if (!mounted) {
      return;
    }

    final barcode = result.item.normalizedBarcode;
    if (barcode == null) {
      _showSnackBar(AppLocalizations.of(context)!.inventoryManualAddSaveFailed);
      return;
    }

    final savedItem = await _persistProduct(
      item: result.item,
      barcode: barcode,
      selectedProduct: result.selectedProduct,
      selectedGlobalFoodItemId: result.selectedGlobalFoodItemId,
      requiresGlobalPersistence: result.requiresGlobalPersistence,
      eatNowWeight: result.eatNowWeight,
    );
    if (!mounted) {
      return;
    }
    if (savedItem == null) {
      _showSnackBar(AppLocalizations.of(context)!.inventoryManualAddSaveFailed);
      return;
    }

    await _closeEditorIfNeeded();
    if (!mounted) {
      return;
    }

    if (result.eatImmediately) {
      await _openImmediateEatFlow(
        savedItem,
        initialEatWeight: result.eatNowWeight,
      );
      if (!mounted) {
        return;
      }
    }

    if (context.canPop()) {
      context.pop(true);
    }
  }

  Future<void> _closeEditorIfNeeded() async {
    final route = ModalRoute.of(context);
    if (route?.isCurrent ?? false) {
      return;
    }
    await Navigator.of(context).maybePop();
  }

  Future<InventoryItem?> _persistProduct({
    required InventoryItem item,
    required String barcode,
    required bool requiresGlobalPersistence, OffProductSearchResult? selectedProduct,
    String? selectedGlobalFoodItemId,
    String? eatNowWeight,
  }) async {
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context)!;
    final globalProduct = _buildGlobalFoodItem(
      item: item,
      barcode: barcode,
      now: now,
      selectedProduct: selectedProduct,
      selectedGlobalFoodItemId: selectedGlobalFoodItemId,
    );

    final globalSaved =
        !requiresGlobalPersistence ||
        await ref.read(globalFoodItemRepositoryProvider).appendAll(
          <GlobalFoodItem>[globalProduct],
        );

    final inventoryWeight = _resolveInventoryWeight(
      packageWeight: item.weight,
      eatNowWeight: eatNowWeight,
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
      barcodeCandidates: <String>[barcode],
      barcodeResolvedAt: now,
    ).withDerivedAmount(weight: inventoryWeight, quantity: 1);

    final inventorySaved = await ref
        .read(inventoryItemsControllerProvider.notifier)
        .addItem(savedItem);
    if (!inventorySaved) {
      return null;
    }
    if (globalSaved) {
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
    required String barcode,
    required DateTime now,
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
      packageWeight: selectedProduct?.packageWeight ?? item.weight,
      servingSize: item.servingSize ?? selectedProduct?.servingSize,
      servingQuantity: item.servingQuantity ?? selectedProduct?.servingQuantity,
      servingQuantityUnit:
          item.servingQuantityUnit ?? selectedProduct?.servingQuantityUnit,
      nutrition: item.nutrition,
    );
  }

  String? _selectedProductGlobalFoodItemId({
    required OffProductSearchResult? selectedProduct,
    required String barcode,
  }) {
    if (selectedProduct == null) {
      return null;
    }
    final normalizedBarcode = selectedProduct.code.trim().isEmpty
        ? barcode
        : selectedProduct.code;
    return 'off-$normalizedBarcode';
  }

  String _globalFoodItemIdFor(InventoryItem item, {required String barcode}) {
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

    final inventoryController = ref.read(
      inventoryItemsControllerProvider.notifier,
    );
    final pendingConsumption = await inventoryController
        .stagePendingConsumption(item.id, request.inventoryAmount);
    if (pendingConsumption == null) {
      if (mounted) {
        _showSnackBar(l10n.inventoryItemActionFailed);
      }
      return;
    }
    if (!mounted) {
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

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  String? _resolveInventoryWeight({
    required String? packageWeight,
    required String? eatNowWeight,
  }) {
    final normalizedPackageWeight = packageWeight?.trim();
    if (normalizedPackageWeight != null && normalizedPackageWeight.isNotEmpty) {
      return normalizedPackageWeight;
    }
    final normalizedEatNowWeight = eatNowWeight?.trim();
    if (normalizedEatNowWeight == null || normalizedEatNowWeight.isEmpty) {
      return null;
    }
    return normalizedEatNowWeight;
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
