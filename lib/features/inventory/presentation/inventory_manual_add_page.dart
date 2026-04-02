import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/product_image_url.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_scanner_page.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_manual_product_sheet.dart';
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
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InventoryBarcodeScannerPage(
      title: l10n.inventoryManualAddTitle,
      onProductSelected: (candidate, scannedBarcode) async {
        return _confirmAndSaveCandidate(
          candidate: candidate,
          scannedBarcode: scannedBarcode,
        );
      },
      onProductNotFound: (scannedBarcode) async {
        return _openManualFallback(scannedBarcode: scannedBarcode);
      },
    );
  }

  Future<bool> _confirmAndSaveCandidate({
    required OffProductSearchResult candidate,
    required String scannedBarcode,
  }) async {
    final barcode = candidate.code.trim().isEmpty
        ? scannedBarcode
        : candidate.code.trim();
    return _editAndSave(
      item: _buildDraftItem(
        scannedBarcode: barcode,
        now: DateTime.now(),
        name: candidate.name,
        brand: candidate.brand,
        imageUrl: normalizeProductImageUrl(candidate.imageUrl),
        weight: candidate.packageWeight,
        nutrition: candidate.nutrition,
      ),
      selectedProduct: candidate,
    );
  }

  Future<bool> _openManualFallback({required String scannedBarcode}) async {
    return _editAndSave(
      item: _buildDraftItem(
        scannedBarcode: scannedBarcode,
        now: DateTime.now(),
        name: scannedBarcode,
      ),
    );
  }

  Future<InventoryReceiptManualProductResult?> _openManualProductSheet({
    required InventoryItem item,
    OffProductSearchResult? selectedProduct,
  }) {
    return showModalBottomSheet<InventoryReceiptManualProductResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return InventoryReceiptManualProductSheet(
          item: item,
          selectedProduct: selectedProduct,
        );
      },
    );
  }

  Future<bool> _editAndSave({
    required InventoryItem item,
    OffProductSearchResult? selectedProduct,
  }) async {
    final result = await _openManualProductSheet(
      item: item,
      selectedProduct: selectedProduct,
    );
    return _saveSheetResult(result);
  }

  Future<bool> _saveSheetResult(
    InventoryReceiptManualProductResult? result,
  ) async {
    if (!mounted || result == null) {
      return false;
    }

    final barcode = result.item.normalizedBarcode;
    if (barcode == null) {
      return false;
    }

    final saved = await _persistProduct(
      item: result.item,
      barcode: barcode,
      selectedProduct: result.selectedProduct,
    );
    if (!mounted) {
      return false;
    }
    if (!saved) {
      _showSnackBar(AppLocalizations.of(context)!.inventoryManualAddSaveFailed);
      return false;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(true);
    }
    return true;
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
