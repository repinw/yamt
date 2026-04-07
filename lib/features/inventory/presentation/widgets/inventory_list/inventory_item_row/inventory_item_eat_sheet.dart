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
part 'inventory_item_eat_sheet_logic.dart';

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
  late final TextEditingController _manualCalorieAmountController =
      TextEditingController();
  late final FocusNode _manualCalorieAmountFocusNode = FocusNode();
  late DateTime _selectedLoggedAt = DateTime.now();
  late MealType _selectedMealType = MealType.defaultForDateTime(
    _selectedLoggedAt,
  );
  var _selectedManualCalorieUnit = ConsumedUnit.grams;
  String? _inventoryAmountErrorText;
  String? _manualCalorieAmountErrorText;

  void _updateState(VoidCallback callback) {
    setState(callback);
  }

  bool get _requiresManualCaloriePortion {
    return inventoryItemRequiresManualCaloriePortion(widget.item);
  }

  int get _defaultInventoryAmount => 1;

  @override
  void initState() {
    super.initState();
    _inventoryAmountFocusNode.addListener(_selectAllInventoryAmount);
    _manualCalorieAmountFocusNode.addListener(_selectAllManualCalorieAmount);
  }

  @override
  void dispose() {
    _inventoryAmountFocusNode.removeListener(_selectAllInventoryAmount);
    _inventoryAmountFocusNode.dispose();
    _manualCalorieAmountFocusNode.removeListener(_selectAllManualCalorieAmount);
    _manualCalorieAmountFocusNode.dispose();
    _inventoryAmountController.dispose();
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
}
