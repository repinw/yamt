import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_page_scaffold.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_state.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_form_field.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_action_selector.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_editor_header.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form/manual_product_nutrition_editor.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'nutrition_label_scan_indicator/nutrition_label_scan_indicator.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Product editor drawn like the eat page: the product head, the nutrition
/// label with an input per value, and the confirm button.
class ManualProductDetailsForm extends StatefulWidget {
  /// Creates the editor for [state].
  const new({
    required this.state,
    required this.imageUrl,
    required this.canSave,
    required this.errorText,
    required this.showActionSelector,
    required this.selectedAction,
    required this.onFieldChanged,
    required this.onWeightUnitChanged,
    required this.onNoBarcodeChanged,
    required this.onScanBarcode,
    required this.onScanNutritionLabel,
    required this.onAddOptionalNutrition,
    required this.onActionChanged,
    required this.onSave,
    super.key,
  });

  /// Key of the confirm button.
  static const saveKey = Key('receipt_review_manual_save_button');

  /// Key of the button that scans a barcode.
  static const scanBarcodeKey = Key(
    'receipt_review_manual_barcode_scan_button',
  );

  /// The entered product.
  final InventoryReceiptManualProductState state;

  /// Product image address.
  final String? imageUrl;

  /// Whether the product can be saved.
  final bool canSave;

  /// Error of the last save, if any.
  final String? errorText;

  /// Whether the user chooses between Vorrat and eating.
  final bool showActionSelector;

  /// The chosen action.
  final InventoryReceiptManualProductAction selectedAction;

  /// Called when an input changes.
  final void Function(ManualProductFormField field, String text) onFieldChanged;

  /// Called with the chosen package unit.
  final ValueChanged<InventoryAmountUnit> onWeightUnitChanged;

  /// Called when the "no barcode" mark changes.
  final ValueChanged<bool> onNoBarcodeChanged;

  /// Scans a barcode.
  final VoidCallback onScanBarcode;

  /// Scans the nutrition label. The button is disabled when null.
  final VoidCallback? onScanNutritionLabel;

  /// Shows the row of an optional nutrient.
  final ValueChanged<InventoryReceiptOptionalNutritionType>
  onAddOptionalNutrition;

  /// Called with the chosen action.
  final ValueChanged<InventoryReceiptManualProductAction> onActionChanged;

  /// Saves the product.
  final VoidCallback onSave;

  @override
  State<ManualProductDetailsForm> createState() =>
      _ManualProductDetailsFormState();
}

class _ManualProductDetailsFormState extends State<ManualProductDetailsForm> {
  late final Map<ManualProductFormField, TextEditingController> _texts = {
    for (final field in ManualProductFormField.values)
      field: TextEditingController(text: field.textIn(widget.state)),
  };
  final Map<ManualProductFormField, FocusNode> _focusNodes = {
    for (final field in ManualProductFormField.values) field: FocusNode(),
  };

  @override
  void didUpdateWidget(ManualProductDetailsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A scan or a picked product changes the values from outside.
    for (final MapEntry(key: field, value: controller) in _texts.entries) {
      final text = field.textIn(widget.state);
      if (controller.text != text) controller.text = text;
    }
  }

  @override
  void dispose() {
    for (final controller in _texts.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  /// Moves to the next required input that is still empty, or closes the
  /// keyboard.
  void _focusNextRequired(ManualProductFormField current) {
    final next = ManualProductFormField.values
        .skip(current.index + 1)
        .where((field) => field.isRequired)
        .where((field) => _texts[field]!.text.trim().isEmpty)
        .firstOrNull;
    if (next == null) {
      _focusNodes[current]!.unfocus();
    } else {
      _focusNodes[next]!.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final state = widget.state;
    final scanImage = state.nutritionOcrImageBytes;
    final error = widget.errorText;

    return EatPageScaffold(
      // Snack bars of the editor come through the route's context.
      hasOwnMessenger: false,
      whenControl: IconButton(
        key: ManualProductDetailsForm.scanBarcodeKey,
        tooltip: l10n.inventoryManualAddScanBarcodeAction,
        onPressed: state.hasNoBarcode ? null : widget.onScanBarcode,
        color: colors.ink,
        icon: const Icon(Icons.qr_code_scanner_rounded),
      ),
      kcal: null,
      confirmButtonKey: ManualProductDetailsForm.saveKey,
      confirmLabel: l10n.inventoryReceiptReviewManualDataSaveAction,
      onConfirm: state.isRunningNutritionOcr || !widget.canSave
          ? null
          : widget.onSave,
      cancelButtonKey: const Key('receipt_review_manual_close_button'),
      children: [
        ManualProductEditorHeader(
          imageUrl: widget.imageUrl,
          texts: _texts,
          focusNodes: _focusNodes,
          weightUnit: state.selectedWeightUnit,
          hasNoBarcode: state.hasNoBarcode,
          onFieldChanged: widget.onFieldChanged,
          onFieldSubmitted: _focusNextRequired,
          onWeightUnitChanged: widget.onWeightUnitChanged,
          onNoBarcodeChanged: widget.onNoBarcodeChanged,
        ),
        if (state.isRunningNutritionOcr && scanImage != null)
          NutritionLabelScanIndicator(
            imageBytes: scanImage,
            statusLabel: l10n.caloriesOcrScanning,
            semanticLabel: l10n.caloriesOcrScanningSemantics,
          ),
        ManualProductNutritionEditor(
          texts: _texts,
          focusNodes: _focusNodes,
          per100Header: l10n.caloriesEntryPer100Label(
            state.selectedWeightUnit == InventoryAmountUnit.milliliter
                ? l10n.inventoryUnitMilliliter
                : l10n.caloriesUnitGram,
          ),
          showPolyunsaturatedFat: state.showPolyunsaturatedFatField,
          showFiber: state.showFiberField,
          onFieldChanged: widget.onFieldChanged,
          onFieldSubmitted: _focusNextRequired,
          onScanLabel: widget.onScanNutritionLabel,
          onAddOptionalNutrition: widget.onAddOptionalNutrition,
        ),
        if (!state.hasMandatoryNutrition)
          Text(
            l10n.productSearchHubMissingNutritionHint,
            style: textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
        if (widget.showActionSelector)
          ManualProductActionSelector(
            selectedAction: widget.selectedAction,
            onChanged: widget.onActionChanged,
          ),
        if (error != null)
          Text(
            error,
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
      ],
    );
  }
}
