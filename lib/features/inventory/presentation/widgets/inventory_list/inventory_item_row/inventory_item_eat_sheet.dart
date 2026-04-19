import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/consumed_unit_l10n.dart';
import 'package:yamt/features/calories/presentation/meal_type_l10n.dart';
import 'package:yamt/features/inventory/application/'
    'global_food_serving_suggestion_repository.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/application/serving_suggestion_resolver.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_serving_suggestion.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/constants/'
    'inventory_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/inventory_amount_unit_l10n.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_nutrition_strip.dart';
import 'package:yamt/l10n/app_localizations.dart';

part 'inventory_item_eat_sheet_components.dart';
part 'inventory_item_eat_sheet_display.dart';
part 'inventory_item_eat_sheet_hero.dart';
part 'inventory_item_eat_sheet_input_sections.dart';
part 'inventory_item_eat_sheet_models.dart';
part 'inventory_item_eat_sheet_view.dart';

/// Show inventory item eat sheet.
Future<InventoryItemEatRequest?> showInventoryItemEatSheet({
  required BuildContext context,
  required InventoryItem item,
  required int maxAmount,
  required String invalidAmountMessage,
  int? initialInventoryAmount,
}) {
  return showModalBottomSheet<InventoryItemEatRequest>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _InventoryItemEatSheet(
        item: item,
        maxAmount: maxAmount,
        invalidAmountMessage: invalidAmountMessage,
        initialInventoryAmount: initialInventoryAmount,
      );
    },
  );
}

class _InventoryItemEatSheet extends ConsumerStatefulWidget {
  const _InventoryItemEatSheet({
    required this.item,
    required this.maxAmount,
    required this.invalidAmountMessage,
    this.initialInventoryAmount,
  });

  final InventoryItem item;
  final int maxAmount;
  final String invalidAmountMessage;
  final int? initialInventoryAmount;

  @override
  ConsumerState<_InventoryItemEatSheet> createState() =>
      _InventoryItemEatSheetState();
}

class _InventoryItemEatSheetState
    extends ConsumerState<_InventoryItemEatSheet> {
  static const _servingResolver = ServingSuggestionResolver();

  late final TextEditingController _inventoryAmountController;
  late final FocusNode _inventoryAmountFocusNode = FocusNode();
  late final TextEditingController _inedibleAmountController =
      TextEditingController();
  late final FocusNode _inedibleAmountFocusNode = FocusNode();
  late final TextEditingController _manualCalorieAmountController =
      TextEditingController();
  late final FocusNode _manualCalorieAmountFocusNode = FocusNode();
  late DateTime _selectedLoggedAt = DateTime.now();
  late MealType _selectedMealType = MealType.defaultForDateTime(
    _selectedLoggedAt,
  );
  ConsumedUnit _selectedManualCalorieUnit = ConsumedUnit.grams;
  String? _inventoryAmountErrorText;
  String? _inedibleAmountErrorText;
  String? _manualCalorieAmountErrorText;
  var _didManuallyEditInventoryAmount = false;
  var _didManuallyEditManualCalorieAmount = false;
  GlobalFoodServingSuggestionSet _learnedServingSuggestions =
      const GlobalFoodServingSuggestionSet.empty();

  void _updateState(VoidCallback callback) {
    setState(callback);
  }

  bool get _requiresManualCaloriePortion {
    return inventoryItemRequiresManualCaloriePortion(widget.item);
  }

  bool get _supportsInedibleAmountAdjustment {
    return inventoryItemUsesFixedCalorieUnit(widget.item);
  }

  InventoryAmountUnit get _inventoryAmountUnit {
    if (widget.item.usesAmountProgress && widget.item.amountUnit != null) {
      return widget.item.amountUnit!;
    }
    return InventoryAmountUnit.piece;
  }

  int get _inventoryAmountScale {
    if (widget.item.usesAmountProgress) {
      return widget.item.amountScale;
    }
    return 1;
  }

  bool get _allowsFractionalInventoryAmount {
    return inventoryAmountAllowsFractionalInput(
      unit: _inventoryAmountUnit,
      scale: _inventoryAmountScale,
    );
  }

  int get _defaultInventoryAmount {
    final defaultAmount = _allowsFractionalInventoryAmount
        ? _inventoryAmountScale
        : 1;
    final amount = widget.initialInventoryAmount;
    if (amount == null || amount < 1) {
      if (defaultAmount > widget.maxAmount) {
        return widget.maxAmount;
      }
      return defaultAmount;
    }
    if (amount > widget.maxAmount) {
      return widget.maxAmount;
    }
    return amount;
  }

  @override
  void initState() {
    super.initState();
    _inventoryAmountController = TextEditingController(
      text: formatInventoryAmountValue(
        amount: _defaultInventoryAmount,
        unit: _inventoryAmountUnit,
        scale: _inventoryAmountScale,
      ),
    );
    _inventoryAmountFocusNode.addListener(_selectAllInventoryAmount);
    _inedibleAmountFocusNode.addListener(_selectAllInedibleAmount);
    _manualCalorieAmountFocusNode.addListener(_selectAllManualCalorieAmount);
    unawaited(_loadServingSuggestions());
  }

  @override
  void dispose() {
    _inventoryAmountFocusNode
      ..removeListener(_selectAllInventoryAmount)
      ..dispose();
    _inedibleAmountFocusNode
      ..removeListener(_selectAllInedibleAmount)
      ..dispose();
    _manualCalorieAmountFocusNode
      ..removeListener(_selectAllManualCalorieAmount)
      ..dispose();
    _inventoryAmountController.dispose();
    _inedibleAmountController.dispose();
    _manualCalorieAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadServingSuggestions() async {
    final suggestions = await ref
        .read(globalFoodServingSuggestionRepositoryProvider)
        .readSuggestions(
          foodFingerprint: widget.item.resolvedFoodFingerprint,
          globalFoodItemId: widget.item.globalFoodItemId,
        );
    if (!mounted) {
      return;
    }

    _updateState(() {
      _learnedServingSuggestions = suggestions;
      _applyLearnedDefaults();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);
    final selectedAmount = parseInventoryAmountInput(
      rawValue: _inventoryAmountController.text,
      unit: _inventoryAmountUnit,
      scale: _inventoryAmountScale,
    );
    final unitLabel = _inventoryUnitLabel(l10n);
    final servingResolution = _resolveServingResolution();
    final quickOptions = _buildQuickOptions(
      l10n,
      unitLabel,
      servingResolution.inventoryServingOptions,
    );
    final manualServingSuggestions = servingResolution.manualServingSuggestions;
    final nutritionMetrics = _buildNutritionMetrics(l10n);
    final isLoggedAtToday = _isLoggedAtToday();
    final loggedAtLabel = isLoggedAtToday
        ? null
        : material.formatMediumDate(_selectedLoggedAt);

    final viewData = _InventoryItemEatSheetViewData(
      viewInsetsBottom: MediaQuery.viewInsetsOf(context).bottom,
      hero: _InventoryItemEatSheetHeroData(
        itemName: widget.item.name,
        imageUrl: widget.item.imageUrl,
        eyebrow: l10n.inventoryItemEatSheetEyebrow,
      ),
      amountSection: _InventoryItemEatSheetAmountSectionData(
        label: l10n.inventoryItemEatSheetAmountLabel,
        clearTooltip: l10n.inventoryItemEatSheetClearAmountAction,
        controller: _inventoryAmountController,
        focusNode: _inventoryAmountFocusNode,
        unitLabel: unitLabel,
        errorText: _inventoryAmountErrorText,
        selectedAmount: selectedAmount,
        allowFractionalInput: _allowsFractionalInventoryAmount,
        quickOptions: quickOptions,
        onChanged: _clearInventoryAmountError,
        onClearAndFocus: _clearInventoryAmountAndFocus,
        onSubmitted: _dismissKeyboard,
        onQuickOptionSelected: _selectInventoryAmount,
      ),
      manualPortionSection: _requiresManualCaloriePortion
          ? _InventoryItemEatSheetManualPortionSectionData(
              title: l10n.inventoryBarcodePortionDialogTitle,
              controller: _manualCalorieAmountController,
              focusNode: _manualCalorieAmountFocusNode,
              errorText: _manualCalorieAmountErrorText,
              selectedUnit: _selectedManualCalorieUnit,
              suggestions: manualServingSuggestions,
              onAmountChanged: _clearManualCalorieAmountError,
              onUnitChanged: _selectManualCalorieUnit,
              onSubmitted: _dismissKeyboard,
              onSuggestionPressed: _applyManualServingSuggestion,
            )
          : null,
      nutritionMetrics: nutritionMetrics,
      whenSection: _InventoryItemEatSheetWhenSectionData(
        isToday: isLoggedAtToday,
        label: loggedAtLabel,
        selectedMealType: _selectedMealType,
        onPickLoggedAt: _pickLoggedAt,
        onMealTypeSelected: _selectMealType,
      ),
      inedibleSection: _supportsInedibleAmountAdjustment
          ? _InventoryItemEatSheetInedibleSectionData(
              controller: _inedibleAmountController,
              focusNode: _inedibleAmountFocusNode,
              errorText: _inedibleAmountErrorText,
              unitLabel: unitLabel ?? '',
              onChanged: _clearInedibleAmountError,
              onSubmitted: _dismissKeyboard,
            )
          : null,
      footer: _InventoryItemEatSheetFooterData(
        confirmActionText: l10n.inventoryItemEatSheetConfirmAction,
        onConfirm: _submit,
      ),
    );

    return _InventoryItemEatSheetView(data: viewData);
  }

  String? _inventoryUnitLabel(AppLocalizations l10n) {
    if (!widget.item.usesAmountProgress || widget.item.amountUnit == null) {
      return null;
    }
    return widget.item.amountUnit!.localizedName(l10n);
  }

  List<({String label, int value})> _buildQuickOptions(
    AppLocalizations l10n,
    String? unitLabel,
    List<({String label, int value})> servingOptions,
  ) {
    final values = <int>{widget.maxAmount};
    final options = <({String label, int value})>[
      (label: l10n.inventoryItemEatSheetAllAction, value: widget.maxAmount),
    ];
    for (final suggestion in servingOptions) {
      if (values.add(suggestion.value)) {
        options.add(suggestion);
      }
    }

    if (widget.item.usesAmountProgress) {
      if (_allowsFractionalInventoryAmount) {
        for (final value in <int>[
          _inventoryAmountScale ~/ 4,
          _inventoryAmountScale ~/ 2,
          _inventoryAmountScale,
        ]) {
          if (value >= widget.maxAmount || value < 1 || !values.add(value)) {
            continue;
          }
          final label = unitLabel == null
              ? formatInventoryAmountValue(
                  amount: value,
                  unit: _inventoryAmountUnit,
                  scale: _inventoryAmountScale,
                )
              : '${formatInventoryAmountValue(
                  amount: value,
                  unit: _inventoryAmountUnit,
                  scale: _inventoryAmountScale,
                )} $unitLabel';
          options.add((label: label, value: value));
        }
        return options;
      }
      for (final value in const [50, 100, 250]) {
        if (value >= widget.maxAmount || !values.add(value)) {
          continue;
        }
        options.add((label: '$value${unitLabel ?? ''}', value: value));
      }
      return options;
    }

    for (final value in const [1, 2, 3]) {
      if (value >= widget.maxAmount || !values.add(value)) {
        continue;
      }
      options.add((label: '$value', value: value));
    }
    return options;
  }

  ServingSuggestionResolution _resolveServingResolution() {
    return _servingResolver.resolve(
      item: widget.item,
      learned: _learnedServingSuggestions,
      maxAmount: widget.maxAmount,
      requiresManualPortion: _requiresManualCaloriePortion,
    );
  }

  void _applyLearnedDefaults() {
    final resolution = _resolveServingResolution();
    if (!_didManuallyEditInventoryAmount) {
      final value = resolution.inventoryDefaultAmount;
      if (value != null) {
        _applyInventoryDefault(value);
      }
    }
    if (!_didManuallyEditManualCalorieAmount) {
      final suggestion = resolution.manualDefaultSuggestion;
      if (suggestion != null) {
        _applyManualDefault(suggestion);
      }
    }
  }

  void _applyInventoryDefault(int value) {
    _inventoryAmountController.text = formatInventoryAmountValue(
      amount: value,
      unit: _inventoryAmountUnit,
      scale: _inventoryAmountScale,
    );
  }

  void _applyManualDefault(({double amount, ConsumedUnit unit}) suggestion) {
    _manualCalorieAmountController.text = formatInventoryNutritionValue(
      suggestion.amount,
    );
    _selectedManualCalorieUnit = suggestion.unit;
  }

  List<({String label, String value})> _buildNutritionMetrics(
    AppLocalizations l10n,
  ) {
    final nutrition = widget.item.nutrition;
    final amountForNutrition = _resolvedNutritionAmount();
    if (nutrition?.hasAnyNutritionValue != true || amountForNutrition == null) {
      return const <({String label, String value})>[];
    }

    final factor = amountForNutrition / 100;
    return [
      if (nutrition?.per100Kcal != null)
        (
          label: l10n.inventoryNutritionCaloriesShortLabel,
          value: (nutrition!.per100Kcal! * factor).round().toString(),
        ),
      if (nutrition?.per100Carbs != null)
        (
          label: l10n.inventoryNutritionCarbsShortLabel,
          value: '${formatInventoryNutritionValue(
            nutrition!.per100Carbs! * factor,
          )}g',
        ),
      if (nutrition?.per100Protein != null)
        (
          label: l10n.caloriesProteinLabel,
          value: '${formatInventoryNutritionValue(
            nutrition!.per100Protein! * factor,
          )}g',
        ),
      if (nutrition?.per100Fat != null)
        (
          label: l10n.caloriesFatLabel,
          value: '${formatInventoryNutritionValue(
            nutrition!.per100Fat! * factor,
          )}g',
        ),
    ];
  }

  void _clearInventoryAmountError(String _) {
    _didManuallyEditInventoryAmount = true;
    if (_inventoryAmountErrorText == null) {
      return;
    }
    _updateState(() {
      _inventoryAmountErrorText = null;
    });
  }

  void _clearInedibleAmountError(String _) {
    if (_inedibleAmountErrorText == null) {
      return;
    }
    _updateState(() {
      _inedibleAmountErrorText = null;
    });
  }

  void _clearManualCalorieAmountError(String _) {
    _didManuallyEditManualCalorieAmount = true;
    if (_manualCalorieAmountErrorText == null) {
      return;
    }
    _updateState(() {
      _manualCalorieAmountErrorText = null;
    });
  }

  void _selectInventoryAmount(int amount) {
    _didManuallyEditInventoryAmount = true;
    _updateState(() {
      _inventoryAmountController.text = formatInventoryAmountValue(
        amount: amount,
        unit: _inventoryAmountUnit,
        scale: _inventoryAmountScale,
      );
      _inventoryAmountErrorText = null;
    });
  }

  void _clearInventoryAmountAndFocus() {
    _didManuallyEditInventoryAmount = true;
    _updateState(() {
      _inventoryAmountController.clear();
      _inventoryAmountErrorText = null;
    });
    _inventoryAmountFocusNode.requestFocus();
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _selectManualCalorieUnit(ConsumedUnit unit) {
    _didManuallyEditManualCalorieAmount = true;
    _updateState(() {
      _selectedManualCalorieUnit = unit;
    });
  }

  void _applyManualServingSuggestion({
    required double amount,
    required ConsumedUnit unit,
  }) {
    _didManuallyEditManualCalorieAmount = true;
    _updateState(() {
      _manualCalorieAmountController.text = formatInventoryNutritionValue(
        amount,
      );
      _selectedManualCalorieUnit = unit;
      _manualCalorieAmountErrorText = null;
    });
  }

  void _selectMealType(MealType mealType) {
    _updateState(() {
      _selectedMealType = mealType;
    });
  }

  void _submit() {
    final inventoryAmount = parseInventoryAmountInput(
      rawValue: _inventoryAmountController.text,
      unit: _inventoryAmountUnit,
      scale: _inventoryAmountScale,
    );
    final isInventoryAmountValid =
        inventoryAmount != null &&
        inventoryAmount >= 1 &&
        inventoryAmount <= widget.maxAmount;
    final rawInedibleAmount = _inedibleAmountController.text.trim();
    final inedibleAmount = _parseNonNegativeAmount(rawInedibleAmount);
    final hasInvalidInedibleAmount =
        rawInedibleAmount.isNotEmpty && inedibleAmount == null;
    final hasTooLargeInedibleAmount =
        inventoryAmount != null &&
        inedibleAmount != null &&
        inedibleAmount >= inventoryAmount;
    final manualCalorieAmount = _parsePositiveAmount(
      _manualCalorieAmountController.text,
    );
    final needsManualCalorieAmount =
        _requiresManualCaloriePortion && manualCalorieAmount == null;

    if (!isInventoryAmountValid ||
        needsManualCalorieAmount ||
        hasInvalidInedibleAmount ||
        hasTooLargeInedibleAmount) {
      final l10n = AppLocalizations.of(context)!;
      _updateState(() {
        if (!isInventoryAmountValid) {
          _inventoryAmountErrorText = widget.invalidAmountMessage;
        }
        if (hasInvalidInedibleAmount) {
          _inedibleAmountErrorText = l10n.caloriesNonNegativeNumberValidation;
        } else if (hasTooLargeInedibleAmount) {
          _inedibleAmountErrorText =
              l10n.inventoryItemEatSheetInedibleAmountError;
        }
        if (needsManualCalorieAmount) {
          _manualCalorieAmountErrorText = l10n.caloriesPositiveNumberValidation;
        }
      });
      return;
    }

    final fixedUnitCalorieAmount = _resolveFixedUnitCalorieAmount(
      inventoryAmount: inventoryAmount,
      inedibleAmount: inedibleAmount,
    );
    Navigator.of(context).pop(
      InventoryItemEatRequest(
        inventoryAmount: inventoryAmount,
        loggedAt: _selectedLoggedAt,
        mealType: _selectedMealType,
        calorieAmount: _requiresManualCaloriePortion
            ? manualCalorieAmount
            : fixedUnitCalorieAmount,
        calorieUnit: _requiresManualCaloriePortion
            ? _selectedManualCalorieUnit
            : fixedUnitCalorieAmount == null
            ? null
            : inventoryItemConsumedUnit(widget.item),
      ),
    );
  }

  double? _resolvedNutritionAmount() {
    if (_requiresManualCaloriePortion) {
      return _parsePositiveAmount(_manualCalorieAmountController.text);
    }

    final inventoryAmount = parseInventoryAmountInput(
      rawValue: _inventoryAmountController.text,
      unit: _inventoryAmountUnit,
      scale: _inventoryAmountScale,
    );
    if (inventoryAmount == null || inventoryAmount < 1) {
      return null;
    }

    final rawInedibleAmount = _inedibleAmountController.text.trim();
    final inedibleAmount = _parseNonNegativeAmount(rawInedibleAmount);
    if (rawInedibleAmount.isNotEmpty && inedibleAmount == null) {
      return null;
    }

    return _resolveConsumedAmount(
      inventoryAmount: inventoryAmount,
      inedibleAmount: inedibleAmount,
    );
  }

  double? _resolveFixedUnitCalorieAmount({
    required int inventoryAmount,
    required double? inedibleAmount,
  }) {
    if (inedibleAmount == null || inedibleAmount <= 0) {
      return null;
    }

    return _resolveConsumedAmount(
      inventoryAmount: inventoryAmount,
      inedibleAmount: inedibleAmount,
    );
  }

  double? _resolveConsumedAmount({
    required int inventoryAmount,
    required double? inedibleAmount,
  }) {
    final consumedAmount = inventoryAmount - (inedibleAmount ?? 0);
    if (consumedAmount <= 0) {
      return null;
    }
    return consumedAmount.toDouble();
  }

  double? _parsePositiveAmount(String rawValue) {
    final normalized = rawValue.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  double? _parseNonNegativeAmount(String rawValue) {
    final normalized = rawValue.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed < 0) {
      return null;
    }
    return parsed;
  }

  void _selectAllInventoryAmount() {
    _selectAllText(
      controller: _inventoryAmountController,
      focusNode: _inventoryAmountFocusNode,
    );
  }

  void _selectAllInedibleAmount() {
    _selectAllText(
      controller: _inedibleAmountController,
      focusNode: _inedibleAmountFocusNode,
    );
  }

  void _selectAllManualCalorieAmount() {
    _selectAllText(
      controller: _manualCalorieAmountController,
      focusNode: _manualCalorieAmountFocusNode,
    );
  }

  void _selectAllText({
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    if (!focusNode.hasFocus) {
      return;
    }

    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  bool _isLoggedAtToday() {
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedDay = DateUtils.dateOnly(_selectedLoggedAt);
    return selectedDay == today;
  }

  Future<void> _pickLoggedAt() async {
    final initialDate = DateUtils.dateOnly(_selectedLoggedAt);
    final lastDate = DateUtils.dateOnly(DateTime.now());
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: DateTime(2000),
      lastDate: lastDate,
    );
    if (!mounted || pickedDate == null) {
      return;
    }

    final now = DateTime.now();
    _updateState(() {
      _selectedLoggedAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        now.hour,
        now.minute,
      );
    });
  }
}
