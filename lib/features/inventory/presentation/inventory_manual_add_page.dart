import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_manual_product_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _inventoryManualAddItemId = Uuid();

class InventoryManualAddPage extends ConsumerStatefulWidget {
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

    final saved = await _persistProduct(
      item: result.item,
      barcode: barcode,
      selectedProduct: result.selectedProduct,
    );
    if (!mounted) {
      return;
    }
    if (!saved) {
      _showSnackBar(AppLocalizations.of(context)!.inventoryManualAddSaveFailed);
      return;
    }

    if (context.canPop()) {
      context.pop(true);
    }
  }

  Future<bool> _persistProduct({
    required InventoryItem item,
    required String barcode,
    OffProductSearchResult? selectedProduct,
  }) async {
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context)!;
    final globalProduct = _buildGlobalFoodItem(
      item: item,
      barcode: barcode,
      now: now,
      selectedProduct: selectedProduct,
    );

    final globalSaved = await ref
        .read(globalFoodItemRepositoryProvider)
        .appendAll(<GlobalFoodItem>[globalProduct]);

    final inventoryItem = InventoryItem.create(
      id: _inventoryManualAddItemId.v4(),
      globalFoodItemId: globalSaved ? globalProduct.id : null,
      name: globalProduct.name,
      entryDate: now,
      storeName: l10n.inventoryManualAddStoreName,
      quantity: 1,
      initialQuantity: 1,
      brand: globalProduct.brand,
      barcode: globalProduct.barcode,
      imageUrl: globalProduct.imageUrl,
      nutrition: globalProduct.nutrition,
      weight: item.weight,
      foodFingerprint: globalProduct.resolvedFoodFingerprint,
      barcodeCandidates: <String>[barcode],
      barcodeResolvedAt: now,
    ).withDerivedAmount(weight: item.weight, quantity: 1);

    final inventorySaved = await ref
        .read(inventoryItemRepositoryProvider)
        .appendAll(<InventoryItem>[inventoryItem]);
    return inventorySaved;
  }

  InventoryItem _buildDraftItem({
    required String scannedBarcode,
    required DateTime now,
    required String name,
    String? brand,
    String? imageUrl,
    String? weight,
    GlobalFoodNutrition? nutrition,
  }) {
    return InventoryItem.create(
      id: _inventoryManualAddItemId.v4(),
      name: name,
      entryDate: now,
      storeName: AppLocalizations.of(context)!.inventoryManualAddStoreName,
      quantity: 1,
      initialQuantity: 1,
      brand: brand,
      barcode: scannedBarcode,
      imageUrl: imageUrl,
      nutrition: nutrition,
      weight: weight,
    ).withDerivedAmount(weight: weight, quantity: 1);
  }

  GlobalFoodItem _buildGlobalFoodItem({
    required InventoryItem item,
    required String barcode,
    required DateTime now,
    OffProductSearchResult? selectedProduct,
  }) {
    return GlobalFoodItem.create(
      id: _globalFoodItemIdFor(item, barcode: barcode),
      name: item.name,
      now: now,
      brand: item.brand,
      barcode: barcode,
      imageUrl: normalizeProductImageUrl(item.imageUrl),
      packageWeight: selectedProduct?.packageWeight ?? item.weight,
      nutrition: item.nutrition,
      status: GlobalFoodItemStatus.active,
    );
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

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
