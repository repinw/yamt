import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart'
    as manual_product_models;
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_preview.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_search_shell.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form_details.dart';

/// Defines inventory receipt manual product form.
class InventoryReceiptManualProductForm extends StatelessWidget {
  /// The inventory receipt manual product form.
  const new({
    required this.canSave,
    required this.isRunningNutritionOcr,
    required this.nameText,
    required this.brandText,
    required this.barcodeText,
    required this.hasNoBarcode,
    required this.weightAmount,
    required this.selectedWeightUnit,
    required this.kcalText,
    required this.saturatedFatText,
    required this.polyunsaturatedFatText,
    required this.showPolyunsaturatedFatField,
    required this.fatText,
    required this.carbsText,
    required this.sugarText,
    required this.fiberText,
    required this.showFiberField,
    required this.proteinText,
    required this.saltText,
    required this.canAddOptionalNutrition,
    required this.isAddingOptionalNutrition,
    required this.optionalNutritionValueText,
    required this.optionalNutritionUnit,
    required this.optionalNutritionType,
    required this.availableOptionalNutritionTypes,
    required this.preview,
    required this.errorText,
    required this.showActionSelector,
    required this.selectedAction,
    required this.onScanBarcode,
    required this.onNameChanged,
    required this.onBrandChanged,
    required this.onBarcodeChanged,
    required this.onNoBarcodeChanged,
    required this.onWeightAmountChanged,
    required this.onWeightUnitChanged,
    required this.onKcalChanged,
    required this.onFatChanged,
    required this.onSaturatedFatChanged,
    required this.onCarbsChanged,
    required this.onSugarChanged,
    required this.onProteinChanged,
    required this.onSaltChanged,
    required this.onPolyunsaturatedFatChanged,
    required this.onFiberChanged,
    required this.onScanNutritionLabel,
    required this.onStartAddingOptionalNutrition,
    required this.onOptionalNutritionValueChanged,
    required this.onOptionalNutritionUnitChanged,
    required this.onOptionalNutritionTypeChanged,
    required this.onApplyOptionalNutrition,
    required this.onCancelOptionalNutrition,
    required this.onCancel,
    required this.onSave,
    super.key,
    this.nutritionOcrImageBytes,
    this.onActionChanged,
  });

  /// Whether save.
  final bool canSave;

  /// Whether running nutrition ocr.
  final bool isRunningNutritionOcr;

  /// Captured nutrition-label image shown while OCR runs.
  final Uint8List? nutritionOcrImageBytes;

  /// The name text.
  final String nameText;

  /// The brand text.
  final String brandText;

  /// The barcode text.
  final String barcodeText;

  /// Whether the product is marked as having no barcode.
  final bool hasNoBarcode;

  /// The weight amount text.
  final String weightAmount;

  /// The selected weight unit.
  final InventoryAmountUnit? selectedWeightUnit;

  /// The kcal text.
  final String kcalText;

  /// The saturated fat text.
  final String saturatedFatText;

  /// The polyunsaturated fat text.
  final String polyunsaturatedFatText;

  /// The show polyunsaturated fat field.
  final bool showPolyunsaturatedFatField;

  /// The fat text.
  final String fatText;

  /// The carbs text.
  final String carbsText;

  /// The sugar text.
  final String sugarText;

  /// The fiber text.
  final String fiberText;

  /// The show fiber field.
  final bool showFiberField;

  /// The protein text.
  final String proteinText;

  /// The salt text.
  final String saltText;

  /// Whether add optional nutrition.
  final bool canAddOptionalNutrition;

  /// Whether adding optional nutrition.
  final bool isAddingOptionalNutrition;

  /// The optional nutrition value text.
  final String optionalNutritionValueText;

  /// The optional nutrition unit.
  final InventoryAmountUnit optionalNutritionUnit;

  /// The optional nutrition type.
  final manual_product_models.InventoryReceiptOptionalNutritionType?
  optionalNutritionType;

  /// Documented member.
  final List<manual_product_models.InventoryReceiptOptionalNutritionType>
  availableOptionalNutritionTypes;

  /// The preview.
  final InventoryReceiptManualProductPreviewData? preview;

  /// The error text.
  final String? errorText;

  /// Whether action selector visible.
  final bool showActionSelector;

  /// The on scan barcode.
  final VoidCallback onScanBarcode;

  /// The on name changed.
  final ValueChanged<String> onNameChanged;

  /// The on brand changed.
  final ValueChanged<String> onBrandChanged;

  /// Called when the barcode text changes.
  final ValueChanged<String> onBarcodeChanged;

  /// Called when the "no barcode" mark changes.
  final ValueChanged<bool> onNoBarcodeChanged;

  /// The on weight amount changed.
  final ValueChanged<String> onWeightAmountChanged;

  /// The on weight unit changed.
  final ValueChanged<InventoryAmountUnit> onWeightUnitChanged;

  /// The on kcal changed.
  final ValueChanged<String> onKcalChanged;

  /// The on fat changed.
  final ValueChanged<String> onFatChanged;

  /// The on saturated fat changed.
  final ValueChanged<String> onSaturatedFatChanged;

  /// The on carbs changed.
  final ValueChanged<String> onCarbsChanged;

  /// The on sugar changed.
  final ValueChanged<String> onSugarChanged;

  /// The on protein changed.
  final ValueChanged<String> onProteinChanged;

  /// The on salt changed.
  final ValueChanged<String> onSaltChanged;

  /// The on polyunsaturated fat changed.
  final ValueChanged<String> onPolyunsaturatedFatChanged;

  /// The on fiber changed.
  final ValueChanged<String> onFiberChanged;

  /// The on scan nutrition label.
  final VoidCallback? onScanNutritionLabel;

  /// The on start adding optional nutrition.
  final VoidCallback onStartAddingOptionalNutrition;

  /// The on optional nutrition value changed.
  final ValueChanged<String> onOptionalNutritionValueChanged;

  /// The on optional nutrition unit changed.
  final ValueChanged<InventoryAmountUnit> onOptionalNutritionUnitChanged;

  /// Documented member.
  final ValueChanged<
    manual_product_models.InventoryReceiptOptionalNutritionType
  >
  onOptionalNutritionTypeChanged;

  /// The on apply optional nutrition.
  final VoidCallback onApplyOptionalNutrition;

  /// The on cancel optional nutrition.
  final VoidCallback onCancelOptionalNutrition;

  /// The selected action.
  final manual_product_models.InventoryReceiptManualProductAction
  selectedAction;

  /// The on action changed.
  final ValueChanged<manual_product_models.InventoryReceiptManualProductAction>?
  onActionChanged;

  /// The on cancel.
  final VoidCallback onCancel;

  /// The on save.
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ManualProductSearchShell(
      onClose: onCancel,
      body: ManualProductDetailsForm(
        preview: preview,
        nameText: nameText,
        brandText: brandText,
        barcodeText: barcodeText,
        hasNoBarcode: hasNoBarcode,
        weightAmount: weightAmount,
        selectedWeightUnit: selectedWeightUnit,
        kcalText: kcalText,
        saturatedFatText: saturatedFatText,
        polyunsaturatedFatText: polyunsaturatedFatText,
        showPolyunsaturatedFatField: showPolyunsaturatedFatField,
        fatText: fatText,
        carbsText: carbsText,
        sugarText: sugarText,
        fiberText: fiberText,
        showFiberField: showFiberField,
        proteinText: proteinText,
        saltText: saltText,
        canAddOptionalNutrition: canAddOptionalNutrition,
        isAddingOptionalNutrition: isAddingOptionalNutrition,
        optionalNutritionValueText: optionalNutritionValueText,
        optionalNutritionUnit: optionalNutritionUnit,
        optionalNutritionType: optionalNutritionType,
        availableOptionalNutritionTypes: availableOptionalNutritionTypes,
        errorText: errorText,
        showActionSelector: showActionSelector,
        selectedAction: selectedAction,
        canSave: canSave,
        isRunningNutritionOcr: isRunningNutritionOcr,
        nutritionOcrImageBytes: nutritionOcrImageBytes,
        onNameChanged: onNameChanged,
        onBrandChanged: onBrandChanged,
        onBarcodeChanged: onBarcodeChanged,
        onNoBarcodeChanged: onNoBarcodeChanged,
        onScanBarcode: onScanBarcode,
        onWeightAmountChanged: onWeightAmountChanged,
        onWeightUnitChanged: onWeightUnitChanged,
        onScanNutritionLabel: onScanNutritionLabel,
        onKcalChanged: onKcalChanged,
        onFatChanged: onFatChanged,
        onSaturatedFatChanged: onSaturatedFatChanged,
        onCarbsChanged: onCarbsChanged,
        onSugarChanged: onSugarChanged,
        onProteinChanged: onProteinChanged,
        onSaltChanged: onSaltChanged,
        onPolyunsaturatedFatChanged: onPolyunsaturatedFatChanged,
        onFiberChanged: onFiberChanged,
        onStartAddingOptionalNutrition: onStartAddingOptionalNutrition,
        onOptionalNutritionValueChanged: onOptionalNutritionValueChanged,
        onOptionalNutritionUnitChanged: onOptionalNutritionUnitChanged,
        onOptionalNutritionTypeChanged: onOptionalNutritionTypeChanged,
        onApplyOptionalNutrition: onApplyOptionalNutrition,
        onCancelOptionalNutrition: onCancelOptionalNutrition,
        onActionChanged: onActionChanged,
        onCancel: onCancel,
        onSave: onSave,
      ),
    );
  }
}
