import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/manual_product_photo_state.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_state.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_form_field.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_editor_page/'
    'manual_product_search_editor_support.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form_details.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Editor page for the product in [state], wired to [controller].
class ManualProductSearchEditorFormView extends StatelessWidget {
  /// Creates the editor view.
  const new({
    required this.state,
    required this.controller,
    required this.quickEatConfig,
    required this.selectedAction,
    required this.showActionSelector,
    required this.showEatImmediatelyOption,
    required this.imageUrl,
    required this.photoState,
    required this.canSave,
    required this.onScanBarcode,
    required this.onTakeFrontPhoto,
    required this.onTakeNutritionTablePhoto,
    required this.onNoBarcodeChanged,
    required this.onActionChanged,
    required this.onSave,
    this.confirmLabel,
    super.key,
  });

  /// Word of the save button; the create word when null.
  final String? confirmLabel;

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

  /// Product image address.
  final String? imageUrl;

  /// The package photos.
  final ManualProductPhotoState photoState;

  /// Whether the product can currently be saved.
  final bool canSave;

  /// Barcode scanning callback.
  final VoidCallback onScanBarcode;

  /// Takes a photo of the package front.
  final VoidCallback onTakeFrontPhoto;

  /// Takes a photo of the nutrition table.
  final VoidCallback onTakeNutritionTablePhoto;

  /// Called when the "no barcode" mark changes.
  final ValueChanged<bool> onNoBarcodeChanged;

  /// Action change callback.
  final ValueChanged<InventoryReceiptManualProductAction> onActionChanged;

  /// Save callback.
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ManualProductDetailsForm(
      state: state,
      imageUrl: imageUrl,
      photoState: photoState,
      canSave: canSave,
      errorText: resolveManualProductErrorText(l10n, state.error),
      showActionSelector:
          showEatImmediatelyOption &&
          showActionSelector &&
          !quickEatConfig.quickEatOnly,
      selectedAction: selectedAction,
      onFieldChanged: _updateField,
      onWeightUnitChanged: controller.updateWeightUnit,
      onNoBarcodeChanged: onNoBarcodeChanged,
      onScanBarcode: onScanBarcode,
      onTakeFrontPhoto: onTakeFrontPhoto,
      onTakeNutritionTablePhoto: onTakeNutritionTablePhoto,
      onAddOptionalNutrition: controller.showOptionalNutrition,
      onActionChanged: onActionChanged,
      onSave: onSave,
      confirmLabel: confirmLabel,
    );
  }

  void _updateField(ManualProductFormField field, String text) {
    final update = switch (field) {
      ManualProductFormField.brand => controller.updateBrandText,
      ManualProductFormField.name => controller.updateNameText,
      ManualProductFormField.weightAmount => controller.updateWeightAmount,
      ManualProductFormField.pieceWeight => controller.updatePieceWeightText,
      ManualProductFormField.barcode => controller.updateBarcode,
      ManualProductFormField.kcal => controller.updateKcalText,
      ManualProductFormField.fat => controller.updateFatText,
      ManualProductFormField.saturatedFat => controller.updateSaturatedFatText,
      ManualProductFormField.polyunsaturatedFat =>
        controller.updatePolyunsaturatedFatText,
      ManualProductFormField.carbs => controller.updateCarbsText,
      ManualProductFormField.sugar => controller.updateSugarText,
      ManualProductFormField.fiber => controller.updateFiberText,
      ManualProductFormField.protein => controller.updateProteinText,
      ManualProductFormField.salt => controller.updateSaltText,
    };
    update(text);
  }
}
