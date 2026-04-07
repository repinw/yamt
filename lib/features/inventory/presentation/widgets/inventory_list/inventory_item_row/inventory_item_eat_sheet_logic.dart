part of 'inventory_item_eat_sheet.dart';

extension _InventoryItemEatSheetStateLogic on _InventoryItemEatSheetState {
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

  List<({String label, String value})> _buildNutritionMetrics(
    AppLocalizations l10n,
  ) {
    final nutrition = widget.item.nutrition;
    final parsedAmount = int.tryParse(_inventoryAmountController.text.trim());
    if (!inventoryItemUsesFixedCalorieUnit(widget.item) ||
        nutrition?.hasAnyNutritionValue != true ||
        parsedAmount == null ||
        parsedAmount < 1) {
      return const <({String label, String value})>[];
    }

    final factor = parsedAmount / 100;
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
    if (_inventoryAmountErrorText == null) {
      return;
    }
    _updateState(() {
      _inventoryAmountErrorText = null;
    });
  }

  void _clearManualCalorieAmountError(String _) {
    if (_manualCalorieAmountErrorText == null) {
      return;
    }
    _updateState(() {
      _manualCalorieAmountErrorText = null;
    });
  }

  void _selectInventoryAmount(int amount) {
    _updateState(() {
      _inventoryAmountController.text = amount.toString();
      _inventoryAmountErrorText = null;
    });
  }

  void _clearInventoryAmountAndFocus() {
    _updateState(() {
      _inventoryAmountController.clear();
      _inventoryAmountErrorText = null;
    });
    _inventoryAmountFocusNode.requestFocus();
  }

  void _selectManualCalorieUnit(ConsumedUnit unit) {
    _updateState(() {
      _selectedManualCalorieUnit = unit;
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
    final manualCalorieAmount = _parsePositiveAmount(
      _manualCalorieAmountController.text,
    );
    final needsManualCalorieAmount =
        _requiresManualCaloriePortion && manualCalorieAmount == null;

    if (!isInventoryAmountValid || needsManualCalorieAmount) {
      _updateState(() {
        if (!isInventoryAmountValid) {
          _inventoryAmountErrorText = widget.invalidAmountMessage;
        }
        if (needsManualCalorieAmount) {
          _manualCalorieAmountErrorText = AppLocalizations.of(
            context,
          )!.caloriesPositiveNumberValidation;
        }
      });
      return;
    }

    Navigator.of(context).pop(
      InventoryItemEatRequest(
        inventoryAmount: inventoryAmount,
        loggedAt: _selectedLoggedAt,
        mealType: _selectedMealType,
        calorieAmount: manualCalorieAmount,
        calorieUnit: _requiresManualCaloriePortion
            ? _selectedManualCalorieUnit
            : null,
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

  void _selectAllInventoryAmount() {
    _selectAllText(
      controller: _inventoryAmountController,
      focusNode: _inventoryAmountFocusNode,
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
