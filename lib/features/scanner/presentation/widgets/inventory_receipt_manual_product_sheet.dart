import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/calories/data/calorie_nutrition_ocr_repository.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/product_image_url.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_scanner_page.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_manual_product_form.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_manual_product_form_utils.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryReceiptManualProductSheet extends ConsumerStatefulWidget {
  const InventoryReceiptManualProductSheet({
    super.key,
    required this.item,
    this.selectedProduct,
  });

  final InventoryItem item;
  final OffProductSearchResult? selectedProduct;

  @override
  ConsumerState<InventoryReceiptManualProductSheet> createState() =>
      _InventoryReceiptManualProductSheetState();
}

class InventoryReceiptManualProductResult {
  const InventoryReceiptManualProductResult({
    required this.item,
    this.selectedProduct,
  });

  final InventoryItem item;
  final OffProductSearchResult? selectedProduct;
}

enum _ManualBarcodeScanResultKind { selected, notFound }

class _ManualBarcodeScanResult {
  const _ManualBarcodeScanResult._({
    required this.kind,
    this.product,
    this.scannedBarcode,
  });

  const _ManualBarcodeScanResult.selected({
    required OffProductSearchResult product,
    required String scannedBarcode,
  }) : this._(
         kind: _ManualBarcodeScanResultKind.selected,
         product: product,
         scannedBarcode: scannedBarcode,
       );

  const _ManualBarcodeScanResult.notFound({required String scannedBarcode})
    : this._(
        kind: _ManualBarcodeScanResultKind.notFound,
        scannedBarcode: scannedBarcode,
      );

  final _ManualBarcodeScanResultKind kind;
  final OffProductSearchResult? product;
  final String? scannedBarcode;
}

class _InventoryReceiptManualProductSheetState
    extends ConsumerState<InventoryReceiptManualProductSheet> {
  late final TextEditingController _barcodeController;
  late final TextEditingController _kcalController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  OffProductSearchResult? _selectedScannedProduct;
  CalorieProductProfile? _ocrProfile;
  bool _isRunningNutritionOcr = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final nutrition =
        widget.item.nutrition ?? widget.selectedProduct?.nutrition;
    _barcodeController = TextEditingController(
      text: widget.item.normalizedBarcode ?? widget.selectedProduct?.code ?? '',
    );
    _barcodeController.addListener(_handleBarcodeChanged);
    _kcalController = TextEditingController(
      text: formatManualProductDouble(nutrition?.per100Kcal),
    );
    _proteinController = TextEditingController(
      text: formatManualProductDouble(nutrition?.per100Protein),
    );
    _carbsController = TextEditingController(
      text: formatManualProductDouble(nutrition?.per100Carbs),
    );
    _fatController = TextEditingController(
      text: formatManualProductDouble(nutrition?.per100Fat),
    );
    _selectedScannedProduct = widget.selectedProduct;
  }

  @override
  void dispose() {
    _barcodeController.removeListener(_handleBarcodeChanged);
    _barcodeController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InventoryReceiptManualProductForm(
      preview: _buildPreviewData(),
      barcodeController: _barcodeController,
      kcalController: _kcalController,
      fatController: _fatController,
      carbsController: _carbsController,
      proteinController: _proteinController,
      errorText: _errorText,
      onScanBarcode: () {
        _openBarcodeScanner();
      },
      onScanNutritionLabel: _canScanNutritionLabel
          ? () {
              _scanNutritionLabel();
            }
          : null,
      onCancel: () => Navigator.of(context).pop(),
      onSave: _save,
    );
  }

  bool get _canScanNutritionLabel {
    return !_isRunningNutritionOcr &&
        normalizeBarcode(_barcodeController.text).isNotEmpty;
  }

  InventoryReceiptManualProductPreviewData? _buildPreviewData() {
    final selectedProduct = _currentPreviewProduct();
    final imageUrl = normalizeProductImageUrl(
      selectedProduct?.imageUrl ?? widget.item.imageUrl,
    );
    if (imageUrl == null) {
      return null;
    }

    final ocrProfile = _resolvedOcrProfile();
    return InventoryReceiptManualProductPreviewData(
      imageUrl: imageUrl,
      name:
          selectedProduct?.name ??
          _resolvedNameFromOcr(ocrProfile) ??
          widget.item.name,
      brand: selectedProduct?.brand ?? ocrProfile?.brand ?? widget.item.brand,
      weight: selectedProduct?.packageWeight ?? widget.item.weight,
    );
  }

  OffProductSearchResult? _currentPreviewProduct() {
    final selectedProduct = _selectedScannedProduct;
    if (selectedProduct == null) {
      return null;
    }

    final normalizedBarcode = normalizeBarcode(_barcodeController.text);
    if (normalizedBarcode.isEmpty) {
      return selectedProduct;
    }
    if (normalizedBarcode != normalizeBarcode(selectedProduct.code)) {
      return null;
    }
    return selectedProduct;
  }

  void _save() {
    final barcode = normalizeManualProductText(_barcodeController.text);
    final kcal = parseManualProductDouble(_kcalController.text);
    final protein = parseManualProductDouble(_proteinController.text);
    final carbs = parseManualProductDouble(_carbsController.text);
    final fat = parseManualProductDouble(_fatController.text);
    final selectedProduct = _effectiveSelectedProduct(
      barcode: barcode,
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );

    final hasNutrition =
        kcal != null || protein != null || carbs != null || fat != null;
    if (barcode == null && !hasNutrition) {
      setState(() {
        _errorText = AppLocalizations.of(
          context,
        )!.inventoryReceiptReviewManualDataRequired;
      });
      return;
    }

    final ocrProfile = _resolvedOcrProfile();
    final updatedItem = widget.item.copyWith(
      name:
          selectedProduct?.name ??
          _resolvedNameFromOcr(ocrProfile) ??
          widget.item.name,
      brand: selectedProduct?.brand ?? ocrProfile?.brand ?? widget.item.brand,
      barcode: barcode,
      imageUrl: selectedProduct?.imageUrl ?? widget.item.imageUrl,
      weight: selectedProduct?.packageWeight ?? widget.item.weight,
      nutrition: hasNutrition
          ? GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: kcal,
              per100Protein: protein,
              per100Carbs: carbs,
              per100Fat: fat,
            )
          : selectedProduct?.nutrition ??
                _nutritionFromProfile(ocrProfile) ??
                widget.item.nutrition,
    );
    Navigator.of(context).pop(
      InventoryReceiptManualProductResult(
        item: updatedItem,
        selectedProduct: selectedProduct,
      ),
    );
  }

  Future<void> _openBarcodeScanner() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<_ManualBarcodeScanResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 1,
          child: InventoryBarcodeScannerPage(
            title: l10n.inventoryBarcodeMissingPromptScanNow,
            onProductSelected: (candidate, scannedBarcode) async {
              Navigator.of(sheetContext).pop(
                _ManualBarcodeScanResult.selected(
                  product: candidate,
                  scannedBarcode: scannedBarcode,
                ),
              );
              return true;
            },
            onProductNotFound: (scannedBarcode) async {
              Navigator.of(sheetContext).pop(
                _ManualBarcodeScanResult.notFound(
                  scannedBarcode: scannedBarcode,
                ),
              );
              return true;
            },
          ),
        );
      },
    );
    if (!mounted || result == null) {
      return;
    }

    switch (result.kind) {
      case _ManualBarcodeScanResultKind.selected:
        final product = result.product;
        if (product == null) {
          return;
        }
        _applySelectedProduct(product);
      case _ManualBarcodeScanResultKind.notFound:
        final scannedBarcode = result.scannedBarcode;
        if (scannedBarcode == null || scannedBarcode.isEmpty) {
          return;
        }
        _applyBarcodeOnly(scannedBarcode);
        _showSnackBar(AppLocalizations.of(context)!.inventoryManualAddNotFound);
    }
  }

  Future<void> _scanNutritionLabel() async {
    final barcode = normalizeBarcode(_barcodeController.text);
    if (barcode.isEmpty || _isRunningNutritionOcr) {
      if (barcode.isEmpty && mounted) {
        setState(() {
          _errorText = AppLocalizations.of(
            context,
          )!.inventoryReceiptReviewManualDataRequired;
        });
      }
      return;
    }

    setState(() {
      _isRunningNutritionOcr = true;
      _errorText = null;
    });

    try {
      final result = await ref
          .read(calorieNutritionOcrRepositoryProvider)
          .scanNutritionLabel(barcode: barcode);
      if (!mounted) {
        return;
      }

      if (result.status == CalorieNutritionOcrStatus.succeeded &&
          result.profile != null) {
        _applyOcrProfile(result.profile!);
        return;
      }

      if (result.status == CalorieNutritionOcrStatus.failed) {
        _showSnackBar(AppLocalizations.of(context)!.caloriesOcrFailed);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRunningNutritionOcr = false;
        });
      }
    }
  }

  OffProductSearchResult? _effectiveSelectedProduct({
    required String? barcode,
    required double? kcal,
    required double? protein,
    required double? carbs,
    required double? fat,
  }) {
    final selectedProduct = _selectedScannedProduct;
    if (selectedProduct == null) {
      return null;
    }

    final normalizedBarcode = barcode == null ? '' : normalizeBarcode(barcode);
    if (normalizedBarcode != normalizeBarcode(selectedProduct.code)) {
      return null;
    }

    final nutrition = selectedProduct.nutrition;
    final matchesOriginalNutrition =
        kcal == nutrition?.per100Kcal &&
        protein == nutrition?.per100Protein &&
        carbs == nutrition?.per100Carbs &&
        fat == nutrition?.per100Fat;
    if (!matchesOriginalNutrition) {
      return null;
    }
    return selectedProduct;
  }

  CalorieProductProfile? _resolvedOcrProfile() {
    final profile = _ocrProfile;
    if (profile == null) {
      return null;
    }

    final barcode = normalizeBarcode(_barcodeController.text);
    if (barcode.isEmpty || barcode != normalizeBarcode(profile.barcode)) {
      return null;
    }
    return profile;
  }

  String? _resolvedNameFromOcr(CalorieProductProfile? profile) {
    if (profile == null) {
      return null;
    }
    final name = profile.name.trim();
    if (name.isEmpty || name == profile.barcode) {
      return null;
    }
    return name;
  }

  GlobalFoodNutrition? _nutritionFromProfile(CalorieProductProfile? profile) {
    if (profile == null) {
      return null;
    }
    return GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: profile.per100Kcal,
      per100Protein: profile.per100Protein,
      per100Carbs: profile.per100Carbs,
      per100Fat: profile.per100Fat,
    );
  }

  void _applySelectedProduct(OffProductSearchResult product) {
    final nutrition = product.nutrition;
    setState(() {
      _selectedScannedProduct = product;
      _ocrProfile = null;
      _barcodeController.text = product.code;
      _fillNutritionFields(
        kcal: nutrition?.per100Kcal,
        protein: nutrition?.per100Protein,
        carbs: nutrition?.per100Carbs,
        fat: nutrition?.per100Fat,
      );
      _errorText = null;
    });
  }

  void _applyBarcodeOnly(String barcode) {
    setState(() {
      _selectedScannedProduct = null;
      _ocrProfile = null;
      _barcodeController.text = barcode;
      _fillNutritionFields();
      _errorText = null;
    });
  }

  void _applyOcrProfile(CalorieProductProfile profile) {
    setState(() {
      _ocrProfile = profile;
      _fillNutritionFields(
        kcal: profile.per100Kcal,
        protein: profile.per100Protein,
        carbs: profile.per100Carbs,
        fat: profile.per100Fat,
      );
    });
  }

  void _fillNutritionFields({
    double? kcal,
    double? protein,
    double? carbs,
    double? fat,
  }) {
    _kcalController.text = formatManualProductDouble(kcal);
    _proteinController.text = formatManualProductDouble(protein);
    _carbsController.text = formatManualProductDouble(carbs);
    _fatController.text = formatManualProductDouble(fat);
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleBarcodeChanged() {
    if (mounted) {
      setState(() {});
    }
  }
}
