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
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_list/inventory_item_row/inventory_item_eat_sheet.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page.dart';
import 'package:yamt/features/product_search/provider/'
    'manual_product_search_controller.dart';
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

    var itemToSave = result.item;
    if (result.action == InventoryReceiptManualProductAction.eatNow) {
      final resolvedEatItem = await _resolveEatItem(result.item);
      if (!mounted || resolvedEatItem == null) {
        return;
      }
      itemToSave = resolvedEatItem;
    }

    final barcode = itemToSave.normalizedBarcode;
    if (barcode == null) {
      _showSnackBar(AppLocalizations.of(context)!.inventoryManualAddSaveFailed);
      return;
    }

    final savedItem = await _persistProduct(
      item: itemToSave,
      barcode: barcode,
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
      await _openImmediateEatFlow(
        savedItem,
        initialEatWeight: savedItem.weight,
      );
      if (!mounted) {
        return;
      }
    }
  }

  Future<InventoryItem?> _resolveEatItem(InventoryItem item) async {
    if (!_requiresEatAmountPrompt(item)) {
      return item;
    }

    final eatAmount = await _showEatAmountDialog(item);
    if (!mounted || eatAmount == null) {
      return null;
    }

    final weight = '${eatAmount.amount} ${_weightUnitCode(eatAmount.unit)}';
    return item
        .copyWith(weight: weight)
        .withDerivedAmount(
          weight: weight,
          quantity: item.quantity,
          fallbackUnit: eatAmount.unit,
        );
  }

  bool _requiresEatAmountPrompt(InventoryItem item) {
    return item.weight == null ||
        item.amountUnit == null ||
        item.initialAmount < 1;
  }

  Future<_ManualEatAmountDialogResult?> _showEatAmountDialog(
    InventoryItem item,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<_ManualEatAmountDialogResult>(
      context: context,
      builder: (dialogContext) {
        return _ManualEatAmountDialog(
          title: l10n.inventoryBarcodePortionDialogTitle,
          confirmLabel: l10n.inventoryBarcodePortionDialogConfirmAction,
          cancelLabel: l10n.inventoryReceiptReviewCancelAction,
          amountLabel: l10n.inventoryItemEatSheetAmountLabel,
          invalidAmountMessage: l10n.inventoryReceiptReviewInvalidNumber,
          initialUnit: _defaultEatAmountUnit(item),
        );
      },
    );
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
    required String barcode,
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

  String _weightUnitCode(InventoryAmountUnit unit) {
    return switch (unit) {
      InventoryAmountUnit.gram => 'g',
      InventoryAmountUnit.milliliter => 'ml',
      InventoryAmountUnit.piece => 'Stk',
    };
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

class _ManualEatAmountDialogResult {
  const _ManualEatAmountDialogResult({
    required this.amount,
    required this.unit,
  });

  final int amount;
  final InventoryAmountUnit unit;
}

class _ManualEatAmountDialog extends StatefulWidget {
  const _ManualEatAmountDialog({
    required this.title,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.amountLabel,
    required this.invalidAmountMessage,
    required this.initialUnit,
  });

  final String title;
  final String confirmLabel;
  final String cancelLabel;
  final String amountLabel;
  final String invalidAmountMessage;
  final InventoryAmountUnit initialUnit;

  @override
  State<_ManualEatAmountDialog> createState() => _ManualEatAmountDialogState();
}

class _ManualEatAmountDialogState extends State<_ManualEatAmountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final FocusNode _amountFocusNode;
  late InventoryAmountUnit _selectedUnit;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _amountFocusNode = FocusNode()..addListener(_handleFocusChanged);
    _selectedUnit = widget.initialUnit;
  }

  @override
  void dispose() {
    _amountFocusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('inventory_manual_add_eat_amount_field'),
                controller: _amountController,
                focusNode: _amountFocusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: widget.amountLabel),
                validator: _validateAmount,
                onFieldSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 112,
              child: DropdownButtonFormField<InventoryAmountUnit>(
                key: const Key('inventory_manual_add_eat_unit_field'),
                initialValue: _selectedUnit,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<InventoryAmountUnit>(
                    value: InventoryAmountUnit.gram,
                    child: Text(l10n.inventoryUnitGram),
                  ),
                  DropdownMenuItem<InventoryAmountUnit>(
                    value: InventoryAmountUnit.milliliter,
                    child: Text(l10n.inventoryUnitMilliliter),
                  ),
                  DropdownMenuItem<InventoryAmountUnit>(
                    value: InventoryAmountUnit.piece,
                    child: Text(l10n.inventoryUnitPiece),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedUnit = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('inventory_manual_add_eat_cancel_button'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          key: const Key('inventory_manual_add_eat_confirm_button'),
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }

  String? _validateAmount(String? value) {
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null || parsed < 1) {
      return widget.invalidAmountMessage;
    }
    return null;
  }

  void _submit() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final parsed = int.tryParse(_amountController.text.trim());
    if (parsed == null) {
      return;
    }

    Navigator.of(context).pop(
      _ManualEatAmountDialogResult(amount: parsed, unit: _selectedUnit),
    );
  }

  void _handleFocusChanged() {
    if (!_amountFocusNode.hasFocus) {
      return;
    }
    _amountController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _amountController.text.length,
    );
  }
}
