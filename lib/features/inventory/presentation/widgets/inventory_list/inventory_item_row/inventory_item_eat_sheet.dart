import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/consumed_unit_l10n.dart';
import 'package:yamt/features/calories/presentation/meal_type_l10n.dart';
import 'package:yamt/features/inventory/application/inventory_item_eat_policy.dart';
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

class _InventoryItemEatSheet extends StatefulWidget {
  const _InventoryItemEatSheet({
    required this.item,
    required this.maxAmount,
    required this.invalidAmountMessage,
  });

  final InventoryItem item;
  final int maxAmount;
  final String invalidAmountMessage;

  @override
  State<_InventoryItemEatSheet> createState() => _InventoryItemEatSheetState();
}

class _InventoryItemEatSheetState extends State<_InventoryItemEatSheet> {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final material = MaterialLocalizations.of(context);
    final selectedAmount = int.tryParse(_inventoryAmountController.text.trim());
    final unitLabel = _inventoryUnitLabel(l10n);
    final quickOptions = _buildQuickOptions(l10n, unitLabel);
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
                            backgroundColor: AppInventoryEditorial.primary,
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
