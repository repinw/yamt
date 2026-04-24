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
  late final TextEditingController _portionLabelController =
      TextEditingController();
  late final FocusNode _portionLabelFocusNode = FocusNode();
  late final TextEditingController _portionCountController =
      TextEditingController(text: '1');
  late final FocusNode _portionCountFocusNode = FocusNode();
  late final TextEditingController _portionAmountController =
      TextEditingController();
  late final FocusNode _portionAmountFocusNode = FocusNode();
  late DateTime _selectedLoggedAt = DateTime.now();
  late MealType _selectedMealType = MealType.defaultForDateTime(
    _selectedLoggedAt,
  );
  ConsumedUnit _selectedManualCalorieUnit = ConsumedUnit.grams;
  ConsumedUnit _selectedPortionUnit = ConsumedUnit.grams;
  String? _inventoryAmountErrorText;
  String? _inedibleAmountErrorText;
  String? _manualCalorieAmountErrorText;
  String? _portionAmountErrorText;
  String? _portionCountErrorText;
  var _didManuallyEditInventoryAmount = false;
  var _didManuallyEditManualCalorieAmount = false;
  var _didManuallyEditPortion = false;
  var _usesPortionMode = false;
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

  List<ConsumedUnit> get _availablePortionUnits {
    final fixedUnit = inventoryItemConsumedUnit(widget.item);
    if (fixedUnit != null) {
      return <ConsumedUnit>[fixedUnit];
    }
    return const <ConsumedUnit>[
      ConsumedUnit.grams,
      ConsumedUnit.milliliters,
    ];
  }

  bool get _canUsePortions {
    return widget.item.nutrition?.hasAnyNutritionValue == true;
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
    _selectedPortionUnit = _availablePortionUnits.first;
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
    _portionAmountFocusNode.addListener(_selectAllPortionAmount);
    _portionCountFocusNode.addListener(_selectAllPortionCount);
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
    _portionAmountFocusNode
      ..removeListener(_selectAllPortionAmount)
      ..dispose();
    _portionCountFocusNode
      ..removeListener(_selectAllPortionCount)
      ..dispose();
    _portionLabelFocusNode.dispose();
    _inventoryAmountController.dispose();
    _inedibleAmountController.dispose();
    _manualCalorieAmountController.dispose();
    _portionLabelController.dispose();
    _portionCountController.dispose();
    _portionAmountController.dispose();
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
    final portionSuggestions = servingResolution.portionSuggestions;
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
      portionSection: _canUsePortions
          ? _InventoryItemEatSheetPortionSectionData(
              title: l10n.inventoryItemEatSheetPortionModeTitle,
              usePortionsLabel: l10n.inventoryItemEatSheetUsePortionsToggle,
              isEnabled: _usesPortionMode,
              labelController: _portionLabelController,
              countController: _portionCountController,
              amountController: _portionAmountController,
              labelFocusNode: _portionLabelFocusNode,
              countFocusNode: _portionCountFocusNode,
              amountFocusNode: _portionAmountFocusNode,
              labelFieldLabel: l10n.inventoryItemEatSheetPortionLabelFieldLabel,
              countFieldLabel: l10n.inventoryItemEatSheetPortionCountFieldLabel,
              amountFieldLabel:
                  l10n.inventoryItemEatSheetPortionAmountFieldLabel,
              decrementTooltip:
                  l10n.inventoryItemEatSheetDecreasePortionCountAction,
              incrementTooltip:
                  l10n.inventoryItemEatSheetIncreasePortionCountAction,
              totalLabel: _portionTotalLabel(l10n),
              amountErrorText: _portionAmountErrorText,
              countErrorText: _portionCountErrorText,
              selectedUnit: _selectedPortionUnit,
              availableUnits: _availablePortionUnits,
              suggestions: portionSuggestions,
              onEnabledChanged: _setPortionModeEnabled,
              onLabelChanged: _onPortionLabelChanged,
              onCountChanged: _onPortionCountChanged,
              onAmountChanged: _onPortionAmountChanged,
              onUnitChanged: _selectPortionUnit,
              onCountStep: _stepPortionCount,
              onSubmitted: _dismissKeyboard,
              onSuggestionPressed: _applyPortionSuggestion,
            )
          : null,
      manualPortionSection: _requiresManualCaloriePortion && !_usesPortionMode
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
    if (!_didManuallyEditPortion && _canUsePortions) {
      final suggestion = resolution.portionDefaultSuggestion;
      if (suggestion != null) {
        _applyPortionDefault(suggestion);
      }
    }
    if (!_didManuallyEditInventoryAmount) {
      final value = resolution.inventoryDefaultAmount;
      if (value != null) {
        _applyInventoryDefault(value);
      }
    }
    if (!_usesPortionMode && !_didManuallyEditManualCalorieAmount) {
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

  void _applyManualDefault(
    ({double amount, ConsumedUnit unit, String? portionLabel}) suggestion,
  ) {
    _manualCalorieAmountController.text = formatInventoryNutritionValue(
      suggestion.amount,
    );
    _selectedManualCalorieUnit = suggestion.unit;
  }

  void _applyPortionDefault(
    ({double amount, ConsumedUnit unit, String? portionLabel}) suggestion,
  ) {
    _usesPortionMode = true;
    _portionAmountController.text = formatInventoryNutritionValue(
      suggestion.amount,
    );
    _selectedPortionUnit = _normalizePortionUnit(suggestion.unit);
    _applyPortionLabel(suggestion.portionLabel);
    if (_portionCountController.text.trim().isEmpty) {
      _portionCountController.text = '1';
    }
    _syncAmountsFromPortionInput();
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
          value:
              '${formatInventoryNutritionValue(
                nutrition!.per100Carbs! * factor,
              )}g',
        ),
      if (nutrition?.per100Protein != null)
        (
          label: l10n.caloriesProteinLabel,
          value:
              '${formatInventoryNutritionValue(
                nutrition!.per100Protein! * factor,
              )}g',
        ),
      if (nutrition?.per100Fat != null)
        (
          label: l10n.caloriesFatLabel,
          value:
              '${formatInventoryNutritionValue(
                nutrition!.per100Fat! * factor,
              )}g',
        ),
    ];
  }

  void _clearInventoryAmountError(String _) {
    _didManuallyEditInventoryAmount = true;
    if (_usesPortionMode) {
      _didManuallyEditPortion = true;
      _usesPortionMode = false;
    }
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

  void _onPortionLabelChanged(String _) {
    _didManuallyEditPortion = true;
  }

  void _onPortionCountChanged(String _) {
    _didManuallyEditPortion = true;
    _updateState(() {
      _portionCountErrorText = null;
      _inventoryAmountErrorText = null;
      _syncAmountsFromPortionInput();
    });
  }

  void _onPortionAmountChanged(String _) {
    _didManuallyEditPortion = true;
    _updateState(() {
      _portionAmountErrorText = null;
      _inventoryAmountErrorText = null;
      _manualCalorieAmountErrorText = null;
      _syncAmountsFromPortionInput();
    });
  }

  void _selectInventoryAmount(int amount) {
    _didManuallyEditInventoryAmount = true;
    if (_usesPortionMode) {
      _didManuallyEditPortion = true;
      _usesPortionMode = false;
    }
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
    if (_usesPortionMode) {
      _didManuallyEditPortion = true;
      _usesPortionMode = false;
    }
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

  void _setPortionModeEnabled(bool enabled) {
    _didManuallyEditPortion = true;
    _updateState(() {
      _usesPortionMode = enabled;
      _portionAmountErrorText = null;
      _portionCountErrorText = null;
      _manualCalorieAmountErrorText = null;
      if (enabled) {
        _ensurePortionDefaults();
        _syncAmountsFromPortionInput();
      }
    });
  }

  void _selectPortionUnit(ConsumedUnit unit) {
    _didManuallyEditPortion = true;
    _updateState(() {
      _selectedPortionUnit = _normalizePortionUnit(unit);
      _syncAmountsFromPortionInput();
    });
  }

  void _stepPortionCount(double delta) {
    _didManuallyEditPortion = true;
    final current = _parsePositiveAmount(_portionCountController.text) ?? 1;
    final next = current + delta;
    if (next <= 0) {
      return;
    }
    _updateState(() {
      _portionCountController.text = formatInventoryNutritionValue(next);
      _portionCountErrorText = null;
      _syncAmountsFromPortionInput();
    });
  }

  void _applyPortionSuggestion({
    required double amount,
    required ConsumedUnit unit,
    required String? portionLabel,
  }) {
    _didManuallyEditPortion = true;
    _updateState(() {
      _usesPortionMode = true;
      _portionAmountController.text = formatInventoryNutritionValue(amount);
      _selectedPortionUnit = _normalizePortionUnit(unit);
      _applyPortionLabel(portionLabel);
      _portionAmountErrorText = null;
      _portionCountErrorText = null;
      _syncAmountsFromPortionInput();
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

  void _ensurePortionDefaults() {
    if (_portionCountController.text.trim().isEmpty) {
      _portionCountController.text = '1';
    }
    if (_portionLabelController.text.trim().isEmpty) {
      _portionLabelController.text = AppLocalizations.of(
        context,
      )!.inventoryItemEatSheetDefaultPortionLabel;
    }
  }

  void _applyPortionLabel(String? label) {
    final normalized = label?.trim();
    if (normalized == null || normalized.isEmpty) {
      _portionLabelController.text = AppLocalizations.of(
        context,
      )!.inventoryItemEatSheetDefaultPortionLabel;
      return;
    }
    _portionLabelController.text = normalized;
  }

  ConsumedUnit _normalizePortionUnit(ConsumedUnit unit) {
    final availableUnits = _availablePortionUnits;
    if (availableUnits.contains(unit)) {
      return unit;
    }
    return availableUnits.first;
  }

  void _syncAmountsFromPortionInput() {
    final portion = _parsePortionInput();
    if (portion == null) {
      return;
    }
    final inventoryAmount = _resolveInventoryAmountFromPortion(
      count: portion.count,
      totalAmount: portion.totalAmount,
      unit: portion.unit,
    );
    if (inventoryAmount == null) {
      return;
    }

    _inventoryAmountController.text = formatInventoryAmountValue(
      amount: inventoryAmount,
      unit: _inventoryAmountUnit,
      scale: _inventoryAmountScale,
    );
    if (_requiresManualCaloriePortion) {
      _manualCalorieAmountController.text = formatInventoryNutritionValue(
        portion.totalAmount,
      );
      _selectedManualCalorieUnit = portion.unit;
    }
  }

  ({double count, double baseAmount, double totalAmount, ConsumedUnit unit})?
  _parsePortionInput() {
    if (!_usesPortionMode) {
      return null;
    }
    final count = _parsePositiveAmount(_portionCountController.text);
    final baseAmount = _parsePositiveAmount(_portionAmountController.text);
    if (count == null || baseAmount == null) {
      return null;
    }
    return (
      count: count,
      baseAmount: baseAmount,
      totalAmount: count * baseAmount,
      unit: _selectedPortionUnit,
    );
  }

  int? _resolveInventoryAmountFromPortion({
    required double count,
    required double totalAmount,
    required ConsumedUnit unit,
  }) {
    final inventoryUnit = _inventoryUnitForConsumedUnit(unit);
    if (inventoryItemUsesFixedCalorieUnit(widget.item)) {
      if (inventoryUnit != _inventoryAmountUnit) {
        return null;
      }
      final rounded = totalAmount.round();
      if ((totalAmount - rounded).abs() > 0.001) {
        return null;
      }
      return rounded;
    }

    return parseInventoryAmountInput(
      rawValue: formatInventoryNutritionValue(count),
      unit: _inventoryAmountUnit,
      scale: _inventoryAmountScale,
    );
  }

  InventoryAmountUnit? _inventoryUnitForConsumedUnit(ConsumedUnit unit) {
    return switch (unit) {
      ConsumedUnit.grams => InventoryAmountUnit.gram,
      ConsumedUnit.milliliters => InventoryAmountUnit.milliliter,
    };
  }

  String? _portionTotalLabel(AppLocalizations l10n) {
    if (!_usesPortionMode) {
      return null;
    }
    final portion = _parsePortionInput();
    if (portion == null) {
      return null;
    }
    return l10n.inventoryItemEatSheetPortionTotalLabel(
      formatInventoryNutritionValue(portion.totalAmount),
      portion.unit.localizedName(l10n),
    );
  }

  String? _normalizedPortionLabel(AppLocalizations l10n) {
    final label = _portionLabelController.text.trim();
    if (label.isEmpty ||
        label == l10n.inventoryItemEatSheetDefaultPortionLabel) {
      return null;
    }
    return label;
  }

  void _selectMealType(MealType mealType) {
    _updateState(() {
      _selectedMealType = mealType;
    });
  }

  void _submit() {
    final rawInventoryAmount = parseInventoryAmountInput(
      rawValue: _inventoryAmountController.text,
      unit: _inventoryAmountUnit,
      scale: _inventoryAmountScale,
    );
    final portionCount = _usesPortionMode
        ? _parsePositiveAmount(_portionCountController.text)
        : null;
    final portionBaseAmount = _usesPortionMode
        ? _parsePositiveAmount(_portionAmountController.text)
        : null;
    final portionTotalAmount = portionCount != null && portionBaseAmount != null
        ? portionCount * portionBaseAmount
        : null;
    final portionInventoryAmount = portionTotalAmount == null
        ? null
        : _resolveInventoryAmountFromPortion(
            count: portionCount!,
            totalAmount: portionTotalAmount,
            unit: _selectedPortionUnit,
          );
    final inventoryAmount = _usesPortionMode
        ? portionInventoryAmount
        : rawInventoryAmount;
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
    final manualCalorieAmount = _usesPortionMode
        ? portionTotalAmount
        : _parsePositiveAmount(_manualCalorieAmountController.text);
    final needsManualCalorieAmount =
        _requiresManualCaloriePortion &&
        !_usesPortionMode &&
        manualCalorieAmount == null;
    final hasInvalidPortionCount = _usesPortionMode && portionCount == null;
    final hasInvalidPortionAmount =
        _usesPortionMode && portionBaseAmount == null;

    if (!isInventoryAmountValid ||
        needsManualCalorieAmount ||
        hasInvalidPortionCount ||
        hasInvalidPortionAmount ||
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
        if (hasInvalidPortionCount) {
          _portionCountErrorText = l10n.caloriesPositiveNumberValidation;
        }
        if (hasInvalidPortionAmount) {
          _portionAmountErrorText = l10n.caloriesPositiveNumberValidation;
        }
      });
      return;
    }

    final confirmedInventoryAmount = inventoryAmount;
    final fixedUnitCalorieAmount = _resolveFixedUnitCalorieAmount(
      inventoryAmount: confirmedInventoryAmount,
      inedibleAmount: inedibleAmount,
    );
    Navigator.of(context).pop(
      InventoryItemEatRequest(
        inventoryAmount: confirmedInventoryAmount,
        loggedAt: _selectedLoggedAt,
        mealType: _selectedMealType,
        calorieAmount: _requiresManualCaloriePortion
            ? manualCalorieAmount
            : fixedUnitCalorieAmount,
        calorieUnit: _requiresManualCaloriePortion
            ? _usesPortionMode
                  ? _selectedPortionUnit
                  : _selectedManualCalorieUnit
            : fixedUnitCalorieAmount == null
            ? null
            : inventoryItemConsumedUnit(widget.item),
        portionBaseAmount: _usesPortionMode ? portionBaseAmount! : null,
        portionBaseUnit: _usesPortionMode ? _selectedPortionUnit : null,
        portionCount: _usesPortionMode ? portionCount! : null,
        portionLabel: _usesPortionMode
            ? _normalizedPortionLabel(AppLocalizations.of(context)!)
            : null,
      ),
    );
  }

  double? _resolvedNutritionAmount() {
    if (_usesPortionMode) {
      final portion = _parsePortionInput();
      if (portion == null) {
        return null;
      }
      if (_supportsInedibleAmountAdjustment) {
        final rawInedibleAmount = _inedibleAmountController.text.trim();
        final inedibleAmount = _parseNonNegativeAmount(rawInedibleAmount);
        if (rawInedibleAmount.isNotEmpty && inedibleAmount == null) {
          return null;
        }
        final consumedAmount = portion.totalAmount - (inedibleAmount ?? 0);
        return consumedAmount <= 0 ? null : consumedAmount;
      }
      return portion.totalAmount;
    }

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

  void _selectAllPortionAmount() {
    _selectAllText(
      controller: _portionAmountController,
      focusNode: _portionAmountFocusNode,
    );
  }

  void _selectAllPortionCount() {
    _selectAllText(
      controller: _portionCountController,
      focusNode: _portionCountFocusNode,
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
