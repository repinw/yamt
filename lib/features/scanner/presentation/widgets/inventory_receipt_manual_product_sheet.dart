import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/calories/data/calorie_nutrition_ocr_repository.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_scanner_page.dart';
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
    final nutrition = widget.item.nutrition;
    _barcodeController = TextEditingController(
      text: widget.item.normalizedBarcode ?? '',
    );
    _kcalController = TextEditingController(
      text: _formatDouble(nutrition?.per100Kcal),
    );
    _proteinController = TextEditingController(
      text: _formatDouble(nutrition?.per100Protein),
    );
    _carbsController = TextEditingController(
      text: _formatDouble(nutrition?.per100Carbs),
    );
    _fatController = TextEditingController(
      text: _formatDouble(nutrition?.per100Fat),
    );
    _selectedScannedProduct = widget.selectedProduct;
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final insets = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl + insets,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.inventoryReceiptReviewManualDataTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.inventoryReceiptReviewManualDataHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildTextField(
              controller: _barcodeController,
              label: l10n.inventoryReceiptReviewManualDataBarcodeLabel,
              key: const Key('receipt_review_manual_barcode_field'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('receipt_review_manual_scan_button'),
                onPressed: _openBarcodeScanner,
                icon: const Icon(Icons.qr_code_scanner_outlined),
                label: Text(l10n.inventoryBarcodeMissingPromptScanNow),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('receipt_review_manual_nutrition_ocr_button'),
                onPressed: _isRunningNutritionOcr ? null : _scanNutritionLabel,
                icon: const Icon(Icons.document_scanner_outlined),
                label: Text(l10n.caloriesBarcodeNotFoundOcrAction),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _kcalController,
              label: l10n.caloriesPer100KcalLabel,
              key: const Key('receipt_review_manual_kcal_field'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _proteinController,
              label: l10n.caloriesPer100ProteinLabel,
              key: const Key('receipt_review_manual_protein_field'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _carbsController,
              label: l10n.caloriesPer100CarbsLabel,
              key: const Key('receipt_review_manual_carbs_field'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _fatController,
              label: l10n.caloriesPer100FatLabel,
              key: const Key('receipt_review_manual_fat_field'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            if (_errorText case final String message) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.inventoryReceiptReviewCancelAction),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    key: const Key('receipt_review_manual_save_button'),
                    onPressed: _save,
                    child: Text(
                      l10n.inventoryReceiptReviewManualDataSaveAction,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Key key,
    required TextInputType keyboardType,
  }) {
    return TextField(
      key: key,
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _save() {
    final barcode = _normalizeText(_barcodeController.text);
    final kcal = _parseDouble(_kcalController.text);
    final protein = _parseDouble(_proteinController.text);
    final carbs = _parseDouble(_carbsController.text);
    final fat = _parseDouble(_fatController.text);
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
      weight: widget.item.weight ?? selectedProduct?.packageWeight,
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
        final nutrition = product.nutrition;
        setState(() {
          _selectedScannedProduct = product;
          _ocrProfile = null;
          _barcodeController.text = product.code;
          _kcalController.text = _formatDouble(nutrition?.per100Kcal);
          _proteinController.text = _formatDouble(nutrition?.per100Protein);
          _carbsController.text = _formatDouble(nutrition?.per100Carbs);
          _fatController.text = _formatDouble(nutrition?.per100Fat);
          _errorText = null;
        });
      case _ManualBarcodeScanResultKind.notFound:
        final scannedBarcode = result.scannedBarcode;
        if (scannedBarcode == null || scannedBarcode.isEmpty) {
          return;
        }
        setState(() {
          _selectedScannedProduct = null;
          _ocrProfile = null;
          _barcodeController.text = scannedBarcode;
          _kcalController.clear();
          _proteinController.clear();
          _carbsController.clear();
          _fatController.clear();
          _errorText = null;
        });
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
        final profile = result.profile!;
        setState(() {
          _ocrProfile = profile;
          _kcalController.text = _formatDouble(profile.per100Kcal);
          _proteinController.text = _formatDouble(profile.per100Protein);
          _carbsController.text = _formatDouble(profile.per100Carbs);
          _fatController.text = _formatDouble(profile.per100Fat);
        });
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

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

String? _normalizeText(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

double? _parseDouble(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return double.tryParse(trimmed.replaceAll(',', '.'));
}

String _formatDouble(double? value) {
  if (value == null) {
    return '';
  }
  if (value.truncateToDouble() == value) {
    return value.toStringAsFixed(0);
  }
  return value.toString();
}
