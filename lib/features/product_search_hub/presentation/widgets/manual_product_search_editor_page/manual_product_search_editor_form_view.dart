import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_state.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_editor_page/'
    'manual_product_search_editor_support.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_preview.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_search_form.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Form view displaying product details and save actions.
class ManualProductSearchEditorFormView extends StatelessWidget {
  /// Creates the editor form view.
  const new({
    required this.state,
    required this.controller,
    required this.quickEatConfig,
    required this.selectedAction,
    required this.showActionSelector,
    required this.showEatImmediatelyOption,
    required this.preview,
    required this.canSave,
    required this.onScanBarcode,
    required this.onScanNutritionLabel,
    required this.onActionChanged,
    required this.onCancel,
    required this.onSave,
    super.key,
  });

  /// Current product search state.
  final InventoryReceiptManualProductState state;

  /// Product search controller.
  final InventoryReceiptManualProductController controller;

  /// Quick eat configuration.
  final InventoryManualAddQuickEatConfig quickEatConfig;

  /// Currently chosen save action.
  final InventoryReceiptManualProductAction selectedAction;

  /// Whether the action selector is visible.
  final bool showActionSelector;

  /// Whether the immediate eat action is supported.
  final bool showEatImmediatelyOption;

  /// Preview data for the selected product.
  final InventoryReceiptManualProductPreviewData? preview;

  /// Whether the product can currently be saved.
  final bool canSave;

  /// Barcode scanning callback.
  final VoidCallback onScanBarcode;

  /// Nutrition label scan callback.
  final VoidCallback? onScanNutritionLabel;

  /// Action change callback.
  final ValueChanged<InventoryReceiptManualProductAction> onActionChanged;

  /// Cancel callback.
  final VoidCallback onCancel;

  /// Save callback.
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: InventoryReceiptManualProductForm(
        preview: preview,
        canSave: canSave,
        isRunningNutritionOcr: state.isRunningNutritionOcr,
        nutritionOcrImageBytes: state.nutritionOcrImageBytes,
        nameText: state.nameText,
        brandText: state.brandText,
        barcodeText: state.barcode,
        weightAmount: state.weightAmount,
        selectedWeightUnit: state.selectedWeightUnit,
        kcalText: state.kcalText,
        saturatedFatText: state.saturatedFatText,
        polyunsaturatedFatText: state.polyunsaturatedFatText,
        showPolyunsaturatedFatField: state.showPolyunsaturatedFatField,
        fatText: state.fatText,
        carbsText: state.carbsText,
        sugarText: state.sugarText,
        fiberText: state.fiberText,
        showFiberField: state.showFiberField,
        proteinText: state.proteinText,
        saltText: state.saltText,
        canAddOptionalNutrition: state.canAddOptionalNutrition,
        isAddingOptionalNutrition: state.isAddingOptionalNutrition,
        optionalNutritionValueText: state.optionalNutritionValueText,
        optionalNutritionUnit: state.optionalNutritionUnit,
        optionalNutritionType: state.resolvedOptionalNutritionType,
        availableOptionalNutritionTypes: state.availableOptionalNutritionTypes,
        errorText: resolveManualProductErrorText(l10n, state.error),
        showActionSelector:
            showEatImmediatelyOption &&
            showActionSelector &&
            !quickEatConfig.quickEatOnly,
        selectedAction: selectedAction,
        onScanBarcode: onScanBarcode,
        onNameChanged: controller.updateNameText,
        onBrandChanged: controller.updateBrandText,
        onBarcodeChanged: controller.updateBarcode,
        onWeightAmountChanged: controller.updateWeightAmount,
        onWeightUnitChanged: controller.updateWeightUnit,
        onKcalChanged: controller.updateKcalText,
        onFatChanged: controller.updateFatText,
        onSaturatedFatChanged: controller.updateSaturatedFatText,
        onCarbsChanged: controller.updateCarbsText,
        onSugarChanged: controller.updateSugarText,
        onProteinChanged: controller.updateProteinText,
        onSaltChanged: controller.updateSaltText,
        onPolyunsaturatedFatChanged: controller.updatePolyunsaturatedFatText,
        onFiberChanged: controller.updateFiberText,
        onScanNutritionLabel: onScanNutritionLabel,
        onStartAddingOptionalNutrition: controller.startAddingOptionalNutrition,
        onOptionalNutritionValueChanged:
            controller.updateOptionalNutritionValueText,
        onOptionalNutritionUnitChanged: controller.updateOptionalNutritionUnit,
        onOptionalNutritionTypeChanged: controller.updateOptionalNutritionType,
        onApplyOptionalNutrition: controller.applyOptionalNutrition,
        onCancelOptionalNutrition: controller.cancelAddingOptionalNutrition,
        onActionChanged: onActionChanged,
        onCancel: onCancel,
        onSave: onSave,
      ),
    );
  }
}
