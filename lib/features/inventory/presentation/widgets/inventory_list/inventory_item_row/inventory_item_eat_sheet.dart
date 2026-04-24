import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/core/widgets/nutrition_metrics_strip.dart';
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
  static const _inventoryAmountModeId = 'inventory';
  static const _newPortionAmountModeId = 'new_portion';

  late final TextEditingController _inventoryAmountController;
  late final FocusNode _inventoryAmountFocusNode = FocusNode();
  late final TextEditingController _inedibleAmountController =
      TextEditingController();
  late final FocusNode _inedibleAmountFocusNode = FocusNode();
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
  ConsumedUnit _selectedPortionUnit = ConsumedUnit.grams;
  String? _inventoryAmountErrorText;
  String? _inedibleAmountErrorText;
  String? _portionAmountErrorText;
  String? _portionCountErrorText;
  var _didManuallyEditInventoryAmount = false;
  var _didManuallyEditPortion = false;
  var _usesPortionMode = false;
  var _isInedibleAmountExpanded = false;
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

  TextEditingController get _activeAmountController {
    return _usesPortionMode
        ? _portionCountController
        : _inventoryAmountController;
  }

  FocusNode get _activeAmountFocusNode {
    return _usesPortionMode
        ? _portionCountFocusNode
        : _inventoryAmountFocusNode;
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
    _portionAmountFocusNode
      ..removeListener(_selectAllPortionAmount)
      ..dispose();
    _portionCountFocusNode
      ..removeListener(_selectAllPortionCount)
      ..dispose();
    _portionLabelFocusNode.dispose();
    _inventoryAmountController.dispose();
    _inedibleAmountController.dispose();
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
    final unitLabel = _inventoryUnitLabel(l10n);
    final servingResolution = _resolveServingResolution();
    final portionSuggestions = servingResolution.portionSuggestions;
    final amountModeOptions = _buildAmountModeOptions(
      l10n,
      portionSuggestions,
    );
    final selectedAmountModeId = _selectedAmountModeId(
      l10n,
      amountModeOptions,
    );
    final quickOptions = _usesPortionMode
        ? _buildPortionCountQuickOptions(l10n)
        : _buildQuickOptions(
            l10n,
            unitLabel,
            servingResolution.inventoryServingOptions,
          );
    final selectedAmount = _selectedQuickAmount();
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
        clearTooltip: l10n.inventoryItemEatSheetClearAmountAction,
        controller: _activeAmountController,
        focusNode: _activeAmountFocusNode,
        modeOptions: amountModeOptions,
        selectedModeId: selectedAmountModeId,
        totalLabel: _amountTotalLabel(l10n),
        errorText: _usesPortionMode
            ? _portionCountErrorText ?? _portionAmountErrorText
            : _inventoryAmountErrorText,
        selectedAmount: selectedAmount,
        allowFractionalInput:
            _usesPortionMode || _allowsFractionalInventoryAmount,
        quickOptions: quickOptions,
        onChanged: _usesPortionMode
            ? _onPortionCountChanged
            : _clearInventoryAmountError,
        onClearAndFocus: _clearActiveAmountAndFocus,
        onSubmitted: _dismissKeyboard,
        onQuickOptionSelected: _selectQuickAmount,
        onModeSelected: _selectAmountMode,
      ),
      manualPortionSection: null,
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
              summaryText: _inedibleAmountSummary(l10n),
              isExpanded: _isInedibleAmountExpanded,
              onChanged: _clearInedibleAmountError,
              onSubmitted: _dismissKeyboard,
              onToggleExpanded: _toggleInedibleAmountExpanded,
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

  List<({String label, int value})> _buildPortionCountQuickOptions(
    AppLocalizations l10n,
  ) {
    final label = _portionLabelForDisplay(l10n);
    return [
      for (final value in const [1, 2, 3])
        (label: '$value $label', value: value),
    ];
  }

  int? _selectedQuickAmount() {
    if (_usesPortionMode) {
      final count = _parsePositiveAmount(_portionCountController.text);
      if (count == null || !_isWholeNumber(count)) {
        return null;
      }
      return count.round();
    }
    return parseInventoryAmountInput(
      rawValue: _inventoryAmountController.text,
      unit: _inventoryAmountUnit,
      scale: _inventoryAmountScale,
    );
  }

  List<_InventoryItemEatAmountModeOption> _buildAmountModeOptions(
    AppLocalizations l10n,
    List<
      ({String label, double amount, ConsumedUnit unit, String? portionLabel})
    >
    portionSuggestions,
  ) {
    final options = <_InventoryItemEatAmountModeOption>[
      _InventoryItemEatAmountModeOption(
        id: _inventoryAmountModeId,
        label: _inventoryAmountModeLabel(l10n),
      ),
    ];
    final seenIds = <String>{_inventoryAmountModeId};
    for (final suggestion in portionSuggestions) {
      final option = _portionModeOption(
        l10n: l10n,
        amount: suggestion.amount,
        unit: suggestion.unit,
        portionLabel: suggestion.portionLabel,
      );
      if (seenIds.add(option.id)) {
        options.add(option);
      }
    }

    final currentOption = _currentPortionModeOption(l10n);
    if (currentOption != null && seenIds.add(currentOption.id)) {
      options.add(currentOption);
    }

    if (_canUsePortions) {
      options.add(
        _InventoryItemEatAmountModeOption(
          id: _newPortionAmountModeId,
          label: l10n.inventoryItemEatSheetNewPortionAction,
          isNewPortion: true,
        ),
      );
    }
    return options;
  }

  _InventoryItemEatAmountModeOption? _currentPortionModeOption(
    AppLocalizations l10n,
  ) {
    if (!_usesPortionMode) {
      return null;
    }
    final amount = _parsePositiveAmount(_portionAmountController.text);
    if (amount == null) {
      return null;
    }
    return _portionModeOption(
      l10n: l10n,
      amount: amount,
      unit: _selectedPortionUnit,
      portionLabel: _normalizedPortionLabel(l10n),
    );
  }

  _InventoryItemEatAmountModeOption _portionModeOption({
    required AppLocalizations l10n,
    required double amount,
    required ConsumedUnit unit,
    required String? portionLabel,
  }) {
    final normalizedLabel = portionLabel?.trim();
    final displayLabel = normalizedLabel == null || normalizedLabel.isEmpty
        ? _defaultPortionLabel(l10n)
        : normalizedLabel;
    final amountLabel = formatInventoryNutritionValue(amount);
    return _InventoryItemEatAmountModeOption(
      id: _portionModeId(
        amount: amount,
        unit: unit,
        portionLabel: normalizedLabel,
      ),
      label: '$displayLabel ($amountLabel${unit.jsonValue})',
      amount: amount,
      unit: unit,
      portionLabel: normalizedLabel,
    );
  }

  String _selectedAmountModeId(
    AppLocalizations l10n,
    List<_InventoryItemEatAmountModeOption> options,
  ) {
    if (!_usesPortionMode) {
      return _inventoryAmountModeId;
    }
    final currentOption = _currentPortionModeOption(l10n);
    if (currentOption == null) {
      return _inventoryAmountModeId;
    }
    if (options.any((option) => option.id == currentOption.id)) {
      return currentOption.id;
    }
    return _inventoryAmountModeId;
  }

  String _portionModeId({
    required double amount,
    required ConsumedUnit unit,
    required String? portionLabel,
  }) {
    final labelKey = portionLabel?.trim().toLowerCase() ?? '';
    final amountKey = buildServingSuggestionAmountKey(amount);
    return 'portion:${unit.jsonValue}:$amountKey:$labelKey';
  }

  String _inventoryAmountModeLabel(AppLocalizations l10n) {
    return switch (_inventoryAmountUnit) {
      InventoryAmountUnit.gram => l10n.inventoryItemEatSheetUnitGram,
      InventoryAmountUnit.milliliter =>
        l10n.inventoryItemEatSheetUnitMilliliter,
      InventoryAmountUnit.piece => l10n.inventoryItemEatSheetUnitPiece,
    };
  }

  String _portionLabelForDisplay(AppLocalizations l10n) {
    final label = _portionLabelController.text.trim();
    if (label.isEmpty) {
      return _defaultPortionLabel(l10n);
    }
    return label;
  }

  String _defaultPortionLabel(AppLocalizations l10n) {
    if (_requiresManualCaloriePortion &&
        _inventoryAmountUnit == InventoryAmountUnit.piece) {
      return l10n.inventoryItemEatSheetUnitPiece;
    }
    return l10n.inventoryItemEatSheetDefaultPortionLabel;
  }

  bool _isWholeNumber(double value) {
    return (value - value.roundToDouble()).abs() < 0.001;
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
    if (!_didManuallyEditPortion &&
        _canUsePortions &&
        _requiresManualCaloriePortion) {
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
  }

  void _applyInventoryDefault(int value) {
    _inventoryAmountController.text = formatInventoryAmountValue(
      amount: value,
      unit: _inventoryAmountUnit,
      scale: _inventoryAmountScale,
    );
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
    _updateState(() {
      _inedibleAmountErrorText = null;
    });
  }

  void _onPortionCountChanged(String _) {
    _didManuallyEditPortion = true;
    _updateState(() {
      _portionCountErrorText = null;
      _inventoryAmountErrorText = null;
      _syncAmountsFromPortionInput();
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

  void _selectQuickAmount(int amount) {
    if (_usesPortionMode) {
      _didManuallyEditPortion = true;
      _updateState(() {
        _portionCountController.text = amount.toString();
        _portionCountErrorText = null;
        _inventoryAmountErrorText = null;
        _syncAmountsFromPortionInput();
      });
      return;
    }
    _selectInventoryAmount(amount);
  }

  void _clearActiveAmountAndFocus() {
    if (_usesPortionMode) {
      _didManuallyEditPortion = true;
      _updateState(() {
        _portionCountController.clear();
        _portionCountErrorText = null;
        _inventoryAmountErrorText = null;
      });
      _portionCountFocusNode.requestFocus();
      return;
    }
    _clearInventoryAmountAndFocus();
  }

  void _clearInventoryAmountAndFocus() {
    _didManuallyEditInventoryAmount = true;
    _updateState(() {
      _inventoryAmountController.clear();
      _inventoryAmountErrorText = null;
    });
    _inventoryAmountFocusNode.requestFocus();
  }

  void _selectAmountMode(String optionId) {
    if (optionId == _newPortionAmountModeId) {
      unawaited(_showNewPortionDialog());
      return;
    }
    if (optionId == _inventoryAmountModeId) {
      _selectInventoryAmountMode();
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final option =
        _buildAmountModeOptions(
          l10n,
          _resolveServingResolution().portionSuggestions,
        ).cast<_InventoryItemEatAmountModeOption?>().firstWhere(
          (candidate) => candidate?.id == optionId,
          orElse: () => null,
        );
    if (option == null || !option.isPortion) {
      return;
    }
    _applyPortionSuggestion(
      amount: option.amount!,
      unit: option.unit!,
      portionLabel: option.portionLabel,
    );
  }

  void _selectInventoryAmountMode() {
    _didManuallyEditPortion = true;
    _updateState(() {
      if (_usesPortionMode) {
        _syncAmountsFromPortionInput();
      }
      _usesPortionMode = false;
      _inventoryAmountErrorText = null;
      _portionAmountErrorText = null;
      _portionCountErrorText = null;
    });
  }

  Future<void> _showNewPortionDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<_NewPortionDialogResult>(
      context: context,
      builder: (_) => _NewPortionDialog(
        initialLabel: _portionLabelForDisplay(l10n),
        initialAmount: _portionAmountController.text.trim(),
        initialUnit: _selectedPortionUnit,
        availableUnits: _availablePortionUnits,
      ),
    );
    if (!mounted || result == null) {
      return;
    }

    _applyPortionSuggestion(
      amount: result.amount,
      unit: result.unit,
      portionLabel: result.label,
    );
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
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

  void _applyPortionLabel(String? label) {
    final normalized = label?.trim();
    if (normalized == null || normalized.isEmpty) {
      _portionLabelController.text = _defaultPortionLabel(
        AppLocalizations.of(context)!,
      );
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

  String? _amountTotalLabel(AppLocalizations l10n) {
    if (_usesPortionMode) {
      return _portionTotalLabel(l10n);
    }
    final amount = parseInventoryAmountInput(
      rawValue: _inventoryAmountController.text,
      unit: _inventoryAmountUnit,
      scale: _inventoryAmountScale,
    );
    if (amount == null) {
      return null;
    }
    return l10n.inventoryItemEatSheetPortionTotalLabel(
      formatInventoryAmountValue(
        amount: amount,
        unit: _inventoryAmountUnit,
        scale: _inventoryAmountScale,
      ),
      _inventoryAmountUnit.code,
    );
  }

  String _inedibleAmountSummary(AppLocalizations l10n) {
    final rawAmount = _inedibleAmountController.text.trim();
    final parsedAmount = _parseNonNegativeAmount(rawAmount);
    final amountLabel = formatInventoryNutritionValue(parsedAmount ?? 0);
    return '${l10n.inventoryItemEatSheetInedibleAmountHint} '
        '($amountLabel${_inventoryAmountUnit.code})';
  }

  String? _normalizedPortionLabel(AppLocalizations l10n) {
    final label = _portionLabelController.text.trim();
    if (label.isEmpty ||
        label == _defaultPortionLabel(l10n) ||
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

  void _toggleInedibleAmountExpanded() {
    final shouldExpand = !_isInedibleAmountExpanded;
    _updateState(() {
      _isInedibleAmountExpanded = shouldExpand;
    });
    if (!shouldExpand) {
      _inedibleAmountFocusNode.unfocus();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _inedibleAmountFocusNode.requestFocus();
    });
  }

  Future<void> _promptForPortionFromInventoryInput() async {
    final inventoryAmount = parseInventoryAmountInput(
      rawValue: _inventoryAmountController.text,
      unit: _inventoryAmountUnit,
      scale: _inventoryAmountScale,
    );
    if (inventoryAmount == null ||
        inventoryAmount < 1 ||
        inventoryAmount > widget.maxAmount) {
      _updateState(() {
        _inventoryAmountErrorText = widget.invalidAmountMessage;
      });
      return;
    }

    _didManuallyEditPortion = true;
    _updateState(() {
      _portionCountController.text = formatInventoryAmountValue(
        amount: inventoryAmount,
        unit: _inventoryAmountUnit,
        scale: _inventoryAmountScale,
      );
      _portionCountErrorText = null;
      _portionAmountErrorText = null;
    });
    await _showNewPortionDialog();
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
    final needsManualCalorieAmount =
        _requiresManualCaloriePortion && !_usesPortionMode;
    final hasInvalidPortionCount = _usesPortionMode && portionCount == null;
    final hasInvalidPortionAmount =
        _usesPortionMode && portionBaseAmount == null;

    if (!isInventoryAmountValid ||
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
        if (hasInvalidInedibleAmount || hasTooLargeInedibleAmount) {
          _isInedibleAmountExpanded = true;
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

    if (needsManualCalorieAmount) {
      unawaited(_promptForPortionFromInventoryInput());
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
            ? portionTotalAmount!
            : fixedUnitCalorieAmount,
        calorieUnit: _requiresManualCaloriePortion
            ? _selectedPortionUnit
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
      return null;
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

class _NewPortionDialog extends StatefulWidget {
  const _NewPortionDialog({
    required this.initialLabel,
    required this.initialAmount,
    required this.initialUnit,
    required this.availableUnits,
  });

  final String initialLabel;
  final String initialAmount;
  final ConsumedUnit initialUnit;
  final List<ConsumedUnit> availableUnits;

  @override
  State<_NewPortionDialog> createState() => _NewPortionDialogState();
}

class _NewPortionDialogState extends State<_NewPortionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _amountController;
  late ConsumedUnit _selectedUnit;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialLabel);
    _amountController = TextEditingController(text: widget.initialAmount);
    _selectedUnit = widget.availableUnits.contains(widget.initialUnit)
        ? widget.initialUnit
        : widget.availableUnits.first;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.inventoryItemEatSheetNewPortionTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('inventory_item_portion_label_field'),
              controller: _labelController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.inventoryItemEatSheetPortionLabelFieldLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              key: const Key('inventory_item_portion_amount_field'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.inventoryItemEatSheetPortionAmountFieldLabel,
              ),
              validator: (value) {
                final amount = _parsePositiveAmount(value ?? '');
                if (amount == null) {
                  return l10n.caloriesPositiveNumberValidation;
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(l10n),
            ),
            if (widget.availableUnits.length > 1) ...[
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<ConsumedUnit>(
                key: const Key('inventory_item_portion_unit_field'),
                initialValue: _selectedUnit,
                items: [
                  for (final unit in widget.availableUnits)
                    DropdownMenuItem<ConsumedUnit>(
                      value: unit,
                      child: Text(unit.localizedName(l10n)),
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
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.inventoryReceiptReviewCancelAction),
        ),
        FilledButton(
          onPressed: () => _submit(l10n),
          child: Text(l10n.inventoryItemEatSheetSavePortionAction),
        ),
      ],
    );
  }

  void _submit(AppLocalizations l10n) {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final amount = _parsePositiveAmount(_amountController.text);
    if (amount == null) {
      return;
    }

    final label = _labelController.text.trim();
    final defaultLabel = l10n.inventoryItemEatSheetDefaultPortionLabel;
    Navigator.of(context).pop(
      _NewPortionDialogResult(
        amount: amount,
        unit: _selectedUnit,
        label: label.isEmpty || label == defaultLabel ? null : label,
      ),
    );
  }

  double? _parsePositiveAmount(String rawValue) {
    final normalized = rawValue.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }
}

class _NewPortionDialogResult {
  const _NewPortionDialogResult({
    required this.amount,
    required this.unit,
    required this.label,
  });

  final double amount;
  final ConsumedUnit unit;
  final String? label;
}
