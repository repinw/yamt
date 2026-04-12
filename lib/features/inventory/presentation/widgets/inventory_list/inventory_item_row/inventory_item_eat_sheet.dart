import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/consumed_unit_l10n.dart';
import 'package:yamt/features/calories/presentation/meal_type_l10n.dart';
import 'package:yamt/features/inventory/application/inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/data/'
    'global_food_serving_suggestion_repository.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_serving_suggestion.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_amount_unit_l10n.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_nutrition_strip.dart';
import 'package:yamt/l10n/app_localizations.dart';

part 'inventory_item_eat_sheet_components.dart';
part 'inventory_item_eat_sheet_display.dart';

Future<InventoryItemEatRequest?> showInventoryItemEatSheet({
  required BuildContext context,
  required InventoryItem item,
  required int maxAmount,
  required String invalidAmountMessage,
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
      );
    },
  );
}

class _InventoryItemEatSheet extends ConsumerStatefulWidget {
  const _InventoryItemEatSheet({
    required this.item,
    required this.maxAmount,
    required this.invalidAmountMessage,
  });

  final InventoryItem item;
  final int maxAmount;
  final String invalidAmountMessage;

  @override
  ConsumerState<_InventoryItemEatSheet> createState() =>
      _InventoryItemEatSheetState();
}

class _InventoryItemEatSheetState
    extends ConsumerState<_InventoryItemEatSheet> {
  static const _servingAmountParser = InventoryAmountParser();

  late final TextEditingController _inventoryAmountController =
      TextEditingController(text: _defaultInventoryAmount.toString());
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
  var _selectedManualCalorieUnit = ConsumedUnit.grams;
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

  int get _defaultInventoryAmount => 1;

  @override
  void initState() {
    super.initState();
    _inventoryAmountFocusNode.addListener(_selectAllInventoryAmount);
    _inedibleAmountFocusNode.addListener(_selectAllInedibleAmount);
    _manualCalorieAmountFocusNode.addListener(_selectAllManualCalorieAmount);
    unawaited(_loadServingSuggestions());
  }

  @override
  void dispose() {
    _inventoryAmountFocusNode.removeListener(_selectAllInventoryAmount);
    _inventoryAmountFocusNode.dispose();
    _inedibleAmountFocusNode.removeListener(_selectAllInedibleAmount);
    _inedibleAmountFocusNode.dispose();
    _manualCalorieAmountFocusNode.removeListener(_selectAllManualCalorieAmount);
    _manualCalorieAmountFocusNode.dispose();
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
    final colors = Theme.of(context).colorScheme;
    final material = MaterialLocalizations.of(context);
    final selectedAmount = int.tryParse(_inventoryAmountController.text.trim());
    final unitLabel = _inventoryUnitLabel(l10n);
    final quickOptions = _buildQuickOptions(l10n, unitLabel);
    final manualServingSuggestions = _buildManualServingSuggestions();
    final nutritionMetrics = _buildNutritionMetrics(l10n);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxxl,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: DecoratedBox(
              decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
                colors,
                borderRadius: BorderRadius.circular(
                  AppInventoryEditorial.cardRadius,
                ),
              ),
              child: Padding(
                padding: AppInsets.card,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _InventoryItemEatSheetHeader(
                        title: l10n.inventoryItemEatSheetTitle(
                          widget.item.name,
                        ),
                        eyebrow: l10n.inventoryItemEatSheetEyebrow,
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      _InventoryItemEatSectionLabel(
                        text: l10n.inventoryItemEatSheetAmountLabel,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _InventoryItemEatAmountCard(
                        controller: _inventoryAmountController,
                        focusNode: _inventoryAmountFocusNode,
                        unitLabel: unitLabel,
                        errorText: _inventoryAmountErrorText,
                        clearTooltip:
                            l10n.inventoryItemEatSheetClearAmountAction,
                        onChanged: _clearInventoryAmountError,
                        onClearAndFocus: _clearInventoryAmountAndFocus,
                        onSubmitted: _submit,
                      ),
                      if (quickOptions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxxl),
                        _InventoryItemEatSectionLabel(
                          text: l10n.inventoryItemEatSheetQuickSelectLabel,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final option in quickOptions)
                              _InventoryItemEatQuickChip(
                                label: option.label,
                                isSelected: selectedAmount == option.value,
                                onPressed: () =>
                                    _selectInventoryAmount(option.value),
                              ),
                          ],
                        ),
                      ],
                      if (_supportsInedibleAmountAdjustment) ...[
                        const SizedBox(height: AppSpacing.xxxl),
                        _InventoryItemEatSectionLabel(
                          text: l10n.inventoryItemEatSheetInedibleAmountLabel,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _InventoryItemEatInedibleAmountSection(
                          amountController: _inedibleAmountController,
                          amountFocusNode: _inedibleAmountFocusNode,
                          amountErrorText: _inedibleAmountErrorText,
                          unitLabel: unitLabel ?? '',
                          onAmountChanged: _clearInedibleAmountError,
                          onSubmitted: _submit,
                        ),
                      ],
                      if (_requiresManualCaloriePortion) ...[
                        const SizedBox(height: AppSpacing.xxxl),
                        _InventoryItemEatSectionLabel(
                          text: l10n.inventoryBarcodePortionDialogTitle,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _InventoryItemEatManualPortionSection(
                          amountController: _manualCalorieAmountController,
                          amountFocusNode: _manualCalorieAmountFocusNode,
                          amountErrorText: _manualCalorieAmountErrorText,
                          selectedUnit: _selectedManualCalorieUnit,
                          onAmountChanged: _clearManualCalorieAmountError,
                          onUnitChanged: _selectManualCalorieUnit,
                        ),
                        if (manualServingSuggestions.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _InventoryItemEatSectionLabel(
                            text: l10n.inventoryItemEatSheetQuickSelectLabel,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final suggestion in manualServingSuggestions)
                                _InventoryItemEatQuickChip(
                                  label: suggestion.label,
                                  isSelected:
                                      _selectedManualCalorieUnit ==
                                          suggestion.unit &&
                                      _manualCalorieAmountController.text
                                              .trim() ==
                                          formatInventoryNutritionValue(
                                            suggestion.amount,
                                          ),
                                  onPressed: () =>
                                      _applyManualServingSuggestion(
                                        amount: suggestion.amount,
                                        unit: suggestion.unit,
                                      ),
                                ),
                            ],
                          ),
                        ],
                      ],
                      const SizedBox(height: AppSpacing.xxxl),
                      _InventoryItemEatSectionLabel(
                        text: l10n.inventoryItemEatSheetWhenLabel,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _InventoryItemEatWhenCard(
                        label: _loggedAtLabel(material, l10n),
                        onPressed: _pickLoggedAt,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _InventoryItemEatMealTypeSelector(
                        selectedMealType: _selectedMealType,
                        onMealTypeSelected: _selectMealType,
                      ),
                      if (nutritionMetrics.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxxl),
                        _InventoryItemEatSectionLabel(
                          text: l10n.inventoryItemEatSheetNutritionLabel,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _InventoryItemEatNutritionMetricsRow(
                          metrics: nutritionMetrics,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xxxl),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const Key(
                            'inventory_item_amount_dialog_confirm_button',
                          ),
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xxl,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                            ),
                            backgroundColor: colors.primary,
                          ),
                          child: Text(
                            l10n.inventoryItemEatSheetConfirmAction,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: colors.onPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
  ) {
    final values = <int>{widget.maxAmount};
    final options = <({String label, int value})>[
      (label: l10n.inventoryItemEatSheetAllAction, value: widget.maxAmount),
    ];
    for (final suggestion in _buildInventoryServingQuickOptions()) {
      if (values.add(suggestion.value)) {
        options.add(suggestion);
      }
    }

    if (widget.item.usesAmountProgress) {
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

  List<({String label, int value})> _buildInventoryServingQuickOptions() {
    if (!widget.item.usesAmountProgress || widget.item.amountUnit == null) {
      return const <({String label, int value})>[];
    }

    final options = <({String label, int value})>[];
    final seenValues = <int>{};
    for (final suggestion in _inventoryServingSuggestions()) {
      if (suggestion.unit != widget.item.amountUnit ||
          !_isWholeNumber(suggestion.amount)) {
        continue;
      }

      final value = suggestion.amount.round();
      if (value < 1 || value > widget.maxAmount || !seenValues.add(value)) {
        continue;
      }
      options.add((label: suggestion.label, value: value));
    }
    return options;
  }

  List<({String label, double amount, ConsumedUnit unit})>
  _buildManualServingSuggestions() {
    if (!_requiresManualCaloriePortion) {
      return const <({String label, double amount, ConsumedUnit unit})>[];
    }

    final suggestions = <({String label, double amount, ConsumedUnit unit})>[];
    final seenKeys = <String>{};
    for (final suggestion in _manualServingSuggestions()) {
      final key = _manualSuggestionKey(
        amount: suggestion.amount,
        unit: suggestion.unit,
      );
      if (!seenKeys.add(key)) {
        continue;
      }
      suggestions.add(suggestion);
    }
    return suggestions;
  }

  ({String label, double amount, InventoryAmountUnit unit})?
  _resolvedServingSuggestion() {
    final structuredSuggestion = _suggestionFromStructuredServing();
    if (structuredSuggestion != null &&
        !_matchesPackageWeight(structuredSuggestion)) {
      return structuredSuggestion;
    }

    final servingSize = widget.item.servingSize;
    if (servingSize == null) {
      return null;
    }

    final parsed = _servingAmountParser.tryParse(
      rawWeight: servingSize,
      quantity: 1,
    );
    if (parsed == null || parsed.amount < 1) {
      return null;
    }

    final suggestion = (
      label: servingSize,
      amount: parsed.amount.toDouble(),
      unit: parsed.unit,
    );
    if (_matchesPackageWeight(suggestion)) {
      return null;
    }
    return suggestion;
  }

  List<({String label, double amount, InventoryAmountUnit unit})>
  _inventoryServingSuggestions() {
    final suggestions =
        <({String label, double amount, InventoryAmountUnit unit})>[];
    final seenKeys = <String>{};

    for (final suggestion in _buildLearnedInventoryServingSuggestions()) {
      final key = _inventorySuggestionKey(
        amount: suggestion.amount,
        unit: suggestion.unit,
      );
      if (seenKeys.add(key)) {
        suggestions.add(suggestion);
      }
    }

    if (_resolvedServingSuggestion() case final structured?) {
      final key = _inventorySuggestionKey(
        amount: structured.amount,
        unit: structured.unit,
      );
      if (seenKeys.add(key)) {
        suggestions.add(structured);
      }
    }

    return suggestions;
  }

  List<({String label, double amount, InventoryAmountUnit unit})>
  _buildLearnedInventoryServingSuggestions() {
    final suggestions =
        <({String label, double amount, InventoryAmountUnit unit})>[];
    final personal = _learnedServingSuggestions.personalSuggestion;
    if (personal != null) {
      final inventoryUnit = _inventoryUnitForConsumedUnit(personal.unit);
      if (inventoryUnit != null) {
        suggestions.add((
          label: _formatLearnedServingLabel(
            amount: personal.amount,
            unit: personal.unit,
          ),
          amount: personal.amount,
          unit: inventoryUnit,
        ));
      }
    }

    for (final suggestion in _learnedServingSuggestions.globalSuggestions) {
      final inventoryUnit = _inventoryUnitForConsumedUnit(suggestion.unit);
      if (inventoryUnit == null) {
        continue;
      }
      suggestions.add((
        label: _formatLearnedServingLabel(
          amount: suggestion.amount,
          unit: suggestion.unit,
        ),
        amount: suggestion.amount,
        unit: inventoryUnit,
      ));
    }
    return suggestions;
  }

  List<({String label, double amount, ConsumedUnit unit})>
  _manualServingSuggestions() {
    final suggestions = <({String label, double amount, ConsumedUnit unit})>[];
    final personal = _learnedServingSuggestions.personalSuggestion;
    if (personal != null) {
      suggestions.add((
        label: _formatLearnedServingLabel(
          amount: personal.amount,
          unit: personal.unit,
        ),
        amount: personal.amount,
        unit: personal.unit,
      ));
    }

    for (final suggestion in _learnedServingSuggestions.globalSuggestions) {
      suggestions.add((
        label: _formatLearnedServingLabel(
          amount: suggestion.amount,
          unit: suggestion.unit,
        ),
        amount: suggestion.amount,
        unit: suggestion.unit,
      ));
    }

    if (_resolvedServingSuggestion() case final structured?) {
      final consumedUnit = switch (structured.unit) {
        InventoryAmountUnit.gram => ConsumedUnit.grams,
        InventoryAmountUnit.milliliter => ConsumedUnit.milliliters,
        InventoryAmountUnit.piece => null,
      };
      if (consumedUnit != null) {
        suggestions.add((
          label: structured.label,
          amount: structured.amount,
          unit: consumedUnit,
        ));
      }
    }

    return suggestions.take(5).toList(growable: false);
  }

  ({String label, double amount, InventoryAmountUnit unit})?
  _suggestionFromStructuredServing() {
    final quantity = widget.item.servingQuantity;
    final unit = widget.item.servingQuantityUnit;
    if (quantity == null || unit == null || quantity <= 0) {
      return null;
    }

    final normalizedUnit = unit.trim().toLowerCase();
    final converted = switch (normalizedUnit) {
      'g' ||
      'gr' ||
      'gram' ||
      'grams' => (amount: quantity, unit: InventoryAmountUnit.gram),
      'kg' ||
      'kilogram' ||
      'kilograms' => (amount: quantity * 1000, unit: InventoryAmountUnit.gram),
      'mg' => (amount: quantity / 1000, unit: InventoryAmountUnit.gram),
      'ml' => (amount: quantity, unit: InventoryAmountUnit.milliliter),
      'cl' => (amount: quantity * 10, unit: InventoryAmountUnit.milliliter),
      'dl' => (amount: quantity * 100, unit: InventoryAmountUnit.milliliter),
      'l' || 'liter' || 'liters' || 'litre' || 'litres' => (
        amount: quantity * 1000,
        unit: InventoryAmountUnit.milliliter,
      ),
      'pc' ||
      'piece' ||
      'pieces' ||
      'st' ||
      'stk' => (amount: quantity, unit: InventoryAmountUnit.piece),
      _ => null,
    };
    if (converted == null || converted.amount <= 0) {
      return null;
    }

    return (
      label:
          widget.item.servingSize ??
          _formatServingLabel(converted.amount, converted.unit),
      amount: converted.amount,
      unit: converted.unit,
    );
  }

  bool _matchesPackageWeight(
    ({String label, double amount, InventoryAmountUnit unit}) suggestion,
  ) {
    final weight = widget.item.weight;
    if (weight == null) {
      return false;
    }

    final parsedWeight = _servingAmountParser.tryParse(
      rawWeight: weight,
      quantity: 1,
    );
    if (parsedWeight != null &&
        parsedWeight.unit == suggestion.unit &&
        parsedWeight.amount.toDouble() == suggestion.amount) {
      return true;
    }

    final normalizedWeight = _normalizeComparableAmountText(weight);
    final normalizedServing = _normalizeComparableAmountText(suggestion.label);
    return normalizedWeight.isNotEmpty && normalizedWeight == normalizedServing;
  }

  String _formatServingLabel(double amount, InventoryAmountUnit unit) {
    final code = unit.code;
    final value = formatInventoryNutritionValue(amount);
    return code.isEmpty ? value : '$value $code';
  }

  String _normalizeComparableAmountText(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  bool _isWholeNumber(double value) {
    return value == value.roundToDouble();
  }

  void _applyLearnedDefaults() {
    final defaultSuggestion = _learnedServingSuggestions.defaultSuggestion;
    if (defaultSuggestion == null) {
      return;
    }

    if (!_didManuallyEditInventoryAmount) {
      _applyInventoryDefault(defaultSuggestion);
    }
    if (!_didManuallyEditManualCalorieAmount) {
      _applyManualDefault(defaultSuggestion);
    }
  }

  void _applyInventoryDefault(ServingSizeSuggestion suggestion) {
    if (!widget.item.usesAmountProgress || widget.item.amountUnit == null) {
      return;
    }

    final inventoryUnit = _inventoryUnitForConsumedUnit(suggestion.unit);
    if (inventoryUnit != widget.item.amountUnit ||
        !_isWholeNumber(suggestion.amount)) {
      return;
    }

    final value = suggestion.amount.round();
    if (value < 1 || value > widget.maxAmount) {
      return;
    }

    _inventoryAmountController.text = value.toString();
  }

  void _applyManualDefault(ServingSizeSuggestion suggestion) {
    if (!_requiresManualCaloriePortion) {
      return;
    }

    _manualCalorieAmountController.text = formatInventoryNutritionValue(
      suggestion.amount,
    );
    _selectedManualCalorieUnit = suggestion.unit;
  }

  InventoryAmountUnit? _inventoryUnitForConsumedUnit(ConsumedUnit unit) {
    return switch (unit) {
      ConsumedUnit.grams => InventoryAmountUnit.gram,
      ConsumedUnit.milliliters => InventoryAmountUnit.milliliter,
    };
  }

  String _formatLearnedServingLabel({
    required double amount,
    required ConsumedUnit unit,
  }) {
    return '${formatInventoryNutritionValue(amount)} ${unit.jsonValue}';
  }

  String _inventorySuggestionKey({
    required double amount,
    required InventoryAmountUnit unit,
  }) {
    return '${unit.code}:${buildServingSuggestionAmountKey(amount)}';
  }

  String _manualSuggestionKey({
    required double amount,
    required ConsumedUnit unit,
  }) {
    return '${unit.jsonValue}:${buildServingSuggestionAmountKey(amount)}';
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
              '${formatInventoryNutritionValue(nutrition!.per100Carbs! * factor)}g',
        ),
      if (nutrition?.per100Protein != null)
        (
          label: l10n.caloriesProteinLabel,
          value:
              '${formatInventoryNutritionValue(nutrition!.per100Protein! * factor)}g',
        ),
      if (nutrition?.per100Fat != null)
        (
          label: l10n.caloriesFatLabel,
          value:
              '${formatInventoryNutritionValue(nutrition!.per100Fat! * factor)}g',
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
      _inventoryAmountController.text = amount.toString();
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
    final inventoryAmount = int.tryParse(
      _inventoryAmountController.text.trim(),
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

    final inventoryAmount = int.tryParse(
      _inventoryAmountController.text.trim(),
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

  String _loggedAtLabel(MaterialLocalizations material, AppLocalizations l10n) {
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedDay = DateUtils.dateOnly(_selectedLoggedAt);
    if (selectedDay == today) {
      return l10n.inventoryItemEatSheetNowValue;
    }
    return material.formatMediumDate(_selectedLoggedAt);
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
