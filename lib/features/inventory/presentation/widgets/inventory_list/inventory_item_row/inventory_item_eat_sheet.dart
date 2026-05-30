import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/consumed_unit_l10n.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_serving_suggestion_service.dart';
import 'package:yamt/features/inventory/application/serving_suggestion_resolver.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_serving_suggestion.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_item_eat_sheet_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_amount_unit_l10n.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_eat_sheet_models.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_eat_sheet_view.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_new_portion_dialog.dart';
import 'package:yamt/features/inventory/presentation/widgets/shared/'
    'inventory_nutrition_strip.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Show inventory item eat sheet.
Future<InventoryItemEatRequest?> showInventoryItemEatSheet({
  required BuildContext context,
  required InventoryItem item,
  required int maxAmount,
  required String invalidAmountMessage,
  int? initialInventoryAmount,
  DateTime? initialLoggedAt,
  MealType? initialMealType,
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
        initialLoggedAt: initialLoggedAt,
        initialMealType: initialMealType,
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
    this.initialLoggedAt,
    this.initialMealType,
  });

  final InventoryItem item;
  final int maxAmount;
  final String invalidAmountMessage;
  final int? initialInventoryAmount;
  final DateTime? initialLoggedAt;
  final MealType? initialMealType;

  @override
  ConsumerState<_InventoryItemEatSheet> createState() =>
      _InventoryItemEatSheetState();
}

class _InventoryItemEatSheetState
    extends ConsumerState<_InventoryItemEatSheet> {
  static const _servingResolver = ServingSuggestionResolver();
  static const _inventoryAmountModeId = 'inventory';
  static const _newPortionAmountModeId = 'new_portion';

  late final InventoryItemEatSheetController _eatController;
  late final TextEditingController _inventoryAmountController;
  late final FocusNode _inventoryAmountFocusNode = FocusNode();
  late final TextEditingController _inedibleAmountController =
      TextEditingController();
  late final FocusNode _inedibleAmountFocusNode = FocusNode();
  late final TextEditingController _portionCountController =
      TextEditingController(text: '1');
  late final FocusNode _portionCountFocusNode = FocusNode();
  late final TextEditingController _portionAmountController =
      TextEditingController();
  late final FocusNode _portionAmountFocusNode = FocusNode();
  late DateTime _selectedLoggedAt;
  late MealType _selectedMealType;
  ConsumedUnit _selectedPortionUnit = ConsumedUnit.grams;
  String? _inventoryAmountErrorText;
  String? _inedibleAmountErrorText;
  String? _portionAmountErrorText;
  String? _portionCountErrorText;
  String? _currentPortionLabel;
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
    return _eatController.requiresManualCaloriePortion;
  }

  bool get _supportsInedibleAmountAdjustment {
    return _eatController.supportsInedibleAmountAdjustment;
  }

  List<ConsumedUnit> get _availablePortionUnits {
    return _eatController.availablePortionUnits;
  }

  bool get _canUsePortions {
    return _eatController.canUsePortions;
  }

  InventoryAmountUnit get _inventoryAmountUnit {
    return _eatController.inventoryAmountUnit;
  }

  int get _inventoryAmountScale {
    return _eatController.inventoryAmountScale;
  }

  bool get _allowsFractionalInventoryAmount {
    return _eatController.allowsFractionalInventoryAmount;
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
    return _eatController.defaultInventoryAmount(
      widget.initialInventoryAmount,
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedLoggedAt = widget.initialLoggedAt ?? DateTime.now();
    _selectedMealType =
        widget.initialMealType ??
        MealType.defaultForDateTime(
          _selectedLoggedAt,
        );
    _eatController = InventoryItemEatSheetController(
      item: widget.item,
      maxAmount: widget.maxAmount,
    );
    _selectedPortionUnit = _availablePortionUnits.first;
    _inventoryAmountController = TextEditingController(
      text: _eatController.formatInventoryAmount(_defaultInventoryAmount),
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
    _inventoryAmountController.dispose();
    _inedibleAmountController.dispose();
    _portionCountController.dispose();
    _portionAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadServingSuggestions() async {
    final service = ref.read(inventoryServingSuggestionServiceProvider);
    final suggestions = await service.readSuggestions(widget.item);
    if (!mounted) {
      return;
    }

    _updateState(() {
      _learnedServingSuggestions = suggestions;
    });
    _applyLearnedDefaults();
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

    final viewData = InventoryItemEatSheetViewData(
      viewInsetsBottom: MediaQuery.viewInsetsOf(context).bottom,
      hero: InventoryItemEatSheetHeroData(
        itemName: widget.item.name,
        imageUrl: widget.item.imageUrl,
        eyebrow: l10n.inventoryItemEatSheetEyebrow,
      ),
      amountSection: InventoryItemEatSheetAmountSectionData(
        clearTooltip: l10n.inventoryItemEatSheetClearAmountAction,
        controller: _activeAmountController,
        focusNode: _activeAmountFocusNode,
        modeOptions: amountModeOptions,
        selectedModeId: selectedAmountModeId,
        availableAmountLabel: _availableInventoryAmountLabel(l10n),
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
      whenSection: InventoryItemEatSheetWhenSectionData(
        isToday: isLoggedAtToday,
        label: loggedAtLabel,
        selectedMealType: _selectedMealType,
        onPickLoggedAt: _pickLoggedAt,
        onMealTypeSelected: _selectMealType,
      ),
      inedibleSection: _supportsInedibleAmountAdjustment
          ? InventoryItemEatSheetInedibleSectionData(
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
      footer: InventoryItemEatSheetFooterData(
        confirmActionText: l10n.inventoryItemEatSheetConfirmAction,
        onConfirm: _submit,
      ),
    );

    return InventoryItemEatSheetView(data: viewData);
  }

  String _availableInventoryAmountLabel(AppLocalizations l10n) {
    return l10n.inventoryItemEatSheetAvailableAmount(
      _eatController.formatInventoryAmount(widget.maxAmount),
      _inventoryAmountUnit.localizedName(l10n),
    );
  }

  String? _inventoryUnitLabel(AppLocalizations l10n) {
    if (!widget.item.usesAmountProgress || widget.item.amountUnit == null) {
      return null;
    }
    return widget.item.amountUnit!.localizedName(l10n);
  }

  List<InventoryServingOption> _buildQuickOptions(
    AppLocalizations l10n,
    String? unitLabel,
    List<InventoryServingOption> servingOptions,
  ) {
    final values = <int>{widget.maxAmount};
    final options = <InventoryServingOption>[
      InventoryServingOption(
        label: l10n.inventoryItemEatSheetAllAction,
        value: widget.maxAmount,
      ),
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
          options.add(InventoryServingOption(label: label, value: value));
        }
        return options;
      }
      for (final value in const [50, 100, 250]) {
        if (value >= widget.maxAmount || !values.add(value)) {
          continue;
        }
        options.add(
          InventoryServingOption(
            label: '$value${unitLabel ?? ''}',
            value: value,
          ),
        );
      }
      return options;
    }

    for (final value in const [1, 2, 3]) {
      if (value >= widget.maxAmount || !values.add(value)) {
        continue;
      }
      options.add(InventoryServingOption(label: '$value', value: value));
    }
    return options;
  }

  List<InventoryServingOption> _buildPortionCountQuickOptions(
    AppLocalizations l10n,
  ) {
    final label = _portionLabelForDisplay(l10n);
    return [
      for (final value in const [1, 2, 3])
        InventoryServingOption(label: '$value $label', value: value),
    ];
  }

  int? _selectedQuickAmount() {
    return _eatController.selectedQuickAmount(
      usesPortionMode: _usesPortionMode,
      inventoryAmountText: _inventoryAmountController.text,
      portionCountText: _portionCountController.text,
    );
  }

  List<InventoryItemEatAmountModeOption> _buildAmountModeOptions(
    AppLocalizations l10n,
    List<PortionSuggestion> portionSuggestions,
  ) {
    final options = <InventoryItemEatAmountModeOption>[
      InventoryItemEatAmountModeOption(
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
        InventoryItemEatAmountModeOption(
          id: _newPortionAmountModeId,
          label: l10n.inventoryItemEatSheetNewPortionAction,
          isNewPortion: true,
        ),
      );
    }
    return options;
  }

  InventoryItemEatAmountModeOption? _currentPortionModeOption(
    AppLocalizations l10n,
  ) {
    if (!_usesPortionMode) {
      return null;
    }
    final amount = _eatController.parsePositiveAmount(
      _portionAmountController.text,
    );
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

  InventoryItemEatAmountModeOption _portionModeOption({
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
    return InventoryItemEatAmountModeOption(
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
    List<InventoryItemEatAmountModeOption> options,
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
    return _eatController.inventoryAmountModeLabel(l10n);
  }

  String _portionLabelForDisplay(AppLocalizations l10n) {
    return _eatController.portionLabelForDisplay(
      l10n: l10n,
      rawLabel: _currentPortionLabel ?? '',
    );
  }

  String _defaultPortionLabel(AppLocalizations l10n) {
    return _eatController.defaultPortionLabel(l10n);
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

  void _applyPortionDefault(PortionSuggestion suggestion) {
    _applyPortionLabel(suggestion.portionLabel);
    _updateState(() {
      _usesPortionMode = true;
      _portionAmountController.text = formatInventoryNutritionValue(
        suggestion.amount,
      );
      _selectedPortionUnit = _normalizePortionUnit(suggestion.unit);
      if (_portionCountController.text.trim().isEmpty) {
        _portionCountController.text = '1';
      }
      _syncAmountsFromPortionInput();
    });
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
      _inventoryAmountController.text = _eatController.formatInventoryAmount(
        amount,
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
        ).cast<InventoryItemEatAmountModeOption?>().firstWhere(
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
    final result = await showDialog<NewPortionDialogResult>(
      context: context,
      builder: (_) => NewPortionDialog(
        initialLabel: _portionLabelForDisplay(l10n),
        initialAmount: _portionAmountController.text.trim(),
        initialUnit: _selectedPortionUnit,
        availableUnits: _availablePortionUnits,
      ),
    );
    if (!mounted || result == null) {
      return;
    }

    final service = ProviderScope.containerOf(context, listen: false).read(
      inventoryServingSuggestionServiceProvider,
    );
    await service.recordCreatedPortion(
      item: widget.item,
      amount: result.amount,
      unit: result.unit,
      label: result.label,
      selectedAt: DateTime.now(),
    );
    if (!mounted) {
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
    _applyPortionLabel(portionLabel);
    _updateState(() {
      _usesPortionMode = true;
      _portionAmountController.text = formatInventoryNutritionValue(amount);
      _selectedPortionUnit = _normalizePortionUnit(unit);
      _portionAmountErrorText = null;
      _portionCountErrorText = null;
      _syncAmountsFromPortionInput();
    });
  }

  void _applyPortionLabel(String? label) {
    final normalized = label?.trim();
    _updateState(() {
      _currentPortionLabel = normalized == null || normalized.isEmpty
          ? null
          : normalized;
    });
  }

  ConsumedUnit _normalizePortionUnit(ConsumedUnit unit) {
    return _eatController.normalizePortionUnit(unit);
  }

  void _syncAmountsFromPortionInput() {
    final inventoryAmount = _eatController.inventoryAmountFromPortionInput(
      usesPortionMode: _usesPortionMode,
      countText: _portionCountController.text,
      amountText: _portionAmountController.text,
      unit: _selectedPortionUnit,
    );
    if (inventoryAmount == null) {
      return;
    }

    _inventoryAmountController.text = _eatController.formatInventoryAmount(
      inventoryAmount,
    );
  }

  InventoryItemEatPortionInput? _parsePortionInput() {
    return _eatController.parsePortionInput(
      usesPortionMode: _usesPortionMode,
      countText: _portionCountController.text,
      amountText: _portionAmountController.text,
      unit: _selectedPortionUnit,
    );
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
    final amount = _eatController.parseInventoryAmount(
      _inventoryAmountController.text,
    );
    if (amount == null) {
      return null;
    }
    return l10n.inventoryItemEatSheetPortionTotalLabel(
      _eatController.formatInventoryAmount(amount),
      _inventoryAmountUnit.code,
    );
  }

  String _inedibleAmountSummary(AppLocalizations l10n) {
    final rawAmount = _inedibleAmountController.text.trim();
    final parsedAmount = _eatController.parseNonNegativeAmount(rawAmount);
    final amountLabel = formatInventoryNutritionValue(parsedAmount ?? 0);
    return '${l10n.inventoryItemEatSheetInedibleAmountHint} '
        '($amountLabel${_inventoryAmountUnit.code})';
  }

  String? _normalizedPortionLabel(AppLocalizations l10n) {
    return _eatController.normalizedPortionLabel(
      l10n: l10n,
      rawLabel: _currentPortionLabel ?? '',
    );
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
    final inventoryAmount = _eatController.parseInventoryAmount(
      _inventoryAmountController.text,
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
      _portionCountController.text = _eatController.formatInventoryAmount(
        inventoryAmount,
      );
      _portionCountErrorText = null;
      _portionAmountErrorText = null;
    });
    await _showNewPortionDialog();
  }

  void _submit() {
    final draft = _eatController.buildSubmissionDraft(
      usesPortionMode: _usesPortionMode,
      inventoryAmountText: _inventoryAmountController.text,
      portionCountText: _portionCountController.text,
      portionAmountText: _portionAmountController.text,
      portionUnit: _selectedPortionUnit,
      inedibleAmountText: _inedibleAmountController.text,
    );

    if (draft.hasValidationErrors) {
      _applySubmitValidationErrors(draft);
      return;
    }

    if (draft.needsManualCalorieAmount) {
      unawaited(_promptForPortionFromInventoryInput());
      return;
    }

    final confirmedInventoryAmount = draft.inventoryAmount!;
    Navigator.of(context).pop(
      InventoryItemEatRequest(
        inventoryAmount: confirmedInventoryAmount,
        loggedAt: _selectedLoggedAt,
        mealType: _selectedMealType,
        calorieAmount: _requiresManualCaloriePortion
            ? draft.portionTotalAmount!
            : draft.fixedUnitCalorieAmount,
        calorieUnit: _requiresManualCaloriePortion
            ? _selectedPortionUnit
            : draft.fixedUnitCalorieAmount == null
            ? null
            : _eatController.fixedCalorieUnit,
        portionBaseAmount: _usesPortionMode ? draft.portionBaseAmount! : null,
        portionBaseUnit: _usesPortionMode ? _selectedPortionUnit : null,
        portionCount: _usesPortionMode ? draft.portionCount! : null,
        portionLabel: _usesPortionMode
            ? _normalizedPortionLabel(AppLocalizations.of(context)!)
            : null,
      ),
    );
  }

  void _applySubmitValidationErrors(
    InventoryItemEatSubmissionDraft draft,
  ) {
    final l10n = AppLocalizations.of(context)!;
    _updateState(() {
      if (draft.hasInvalidInventoryAmount) {
        _inventoryAmountErrorText = widget.invalidAmountMessage;
      }
      if (draft.hasInvalidInedibleAmount) {
        _inedibleAmountErrorText = l10n.caloriesNonNegativeNumberValidation;
      } else if (draft.hasTooLargeInedibleAmount) {
        _inedibleAmountErrorText =
            l10n.inventoryItemEatSheetInedibleAmountError;
      }
      if (draft.hasInvalidInedibleAmount || draft.hasTooLargeInedibleAmount) {
        _isInedibleAmountExpanded = true;
      }
      if (draft.hasInvalidPortionCount) {
        _portionCountErrorText = l10n.caloriesPositiveNumberValidation;
      }
      if (draft.hasInvalidPortionAmount) {
        _portionAmountErrorText = l10n.caloriesPositiveNumberValidation;
      }
    });
  }

  double? _resolvedNutritionAmount() {
    return _eatController.resolvedNutritionAmount(
      usesPortionMode: _usesPortionMode,
      portionCountText: _portionCountController.text,
      portionAmountText: _portionAmountController.text,
      portionUnit: _selectedPortionUnit,
      inventoryAmountText: _inventoryAmountController.text,
      inedibleAmountText: _inedibleAmountController.text,
    );
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
