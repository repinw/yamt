import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/widgets/nutrition_facts_rows.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_state.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_submission.dart';
import 'package:yamt/features/inventory/presentation/formatters/inventory_nutrition_format.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_eat_sheet_result.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_amount_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_chip.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_inedible_line.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_inline_amount_field.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_label_table.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_header.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_scaffold.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_remember_portion.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_l10n.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_text_field.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_when_menu.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Eat page content for an inventory item.
class InventoryItemEatSheetBody extends ConsumerStatefulWidget {
  /// Creates the item eat page content.
  const new({
    required this.item,
    required this.confirmIntent,
    this.initialInventoryAmount,
    this.initialLoggedAt,
    this.initialMealType,
    this.addMoreActionText,
    this.hasOpenStock = false,
    super.key,
  });

  /// Key of the piece weight field.
  static const pieceWeightKey = Key('inventory_item_portion_amount_field');

  /// Key of the piece weight unit button.
  static const pieceWeightUnitKey = Key('inventory_item_portion_unit_button');

  /// Item to eat.
  final InventoryItem item;

  /// Intent of the confirm button.
  final InventoryItemEatSheetIntent confirmIntent;

  /// Inventory amount to start with.
  final int? initialInventoryAmount;

  /// Preselected log time.
  final DateTime? initialLoggedAt;

  /// Preselected meal.
  final MealType? initialMealType;

  /// Text of the "add more" button. The button is hidden when null.
  final String? addMoreActionText;

  /// Whether the stock does not limit the amount, as for a newly picked
  /// product.
  final bool hasOpenStock;

  @override
  ConsumerState<InventoryItemEatSheetBody> createState() =>
      _InventoryItemEatSheetBodyState();
}

class _InventoryItemEatSheetBodyState
    extends ConsumerState<InventoryItemEatSheetBody> {
  late final InventoryItemEatSheetControllerProvider _provider =
      inventoryItemEatSheetControllerProvider(
        item: widget.item,
        initialInventoryAmount: widget.initialInventoryAmount,
        initialLoggedAt: widget.initialLoggedAt,
        initialMealType: widget.initialMealType,
        hasOpenStock: widget.hasOpenStock,
      );
  final _inventoryAmount = EatSheetTextField();
  final _pieceCount = EatSheetTextField();
  final _pieceWeight = EatSheetTextField();
  final _inedibleAmount = EatSheetTextField();

  InventoryItemEatSheetController get _controller =>
      ref.read(_provider.notifier);

  @override
  void initState() {
    super.initState();
    _syncText(ref.read(_provider));
  }

  @override
  void dispose() {
    for (final field in [
      _inventoryAmount,
      _pieceCount,
      _pieceWeight,
      _inedibleAmount,
    ]) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(_provider, (_, next) => _syncText(next));
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(_provider);
    final calculator = state.calculator;
    final item = widget.item;
    final nutrition = state.nutrition;
    final addMoreText = widget.addMoreActionText;
    final amountField = state.usesPortionMode ? _pieceCount : _inventoryAmount;
    final units = calculator.availablePortionUnits;
    final selectedSize = state.selectedPieceSize;

    return EatPageScaffold(
      whenControl: EatWhenMenu(
        loggedAt: state.loggedAt,
        today: state.today,
        mealType: state.mealType,
        onDayPicked: _controller.setLoggedDay,
        onMealTypeChanged: _controller.setMealType,
      ),
      kcal: nutrition?.eaten.kcal,
      confirmButtonKey: const Key(
        'inventory_item_amount_dialog_confirm_button',
      ),
      onConfirm: () => _submit(widget.confirmIntent),
      cancelButtonKey: const Key('inventory_item_amount_dialog_cancel_button'),
      secondaryLabel: addMoreText,
      secondaryButtonKey: const Key(
        'inventory_item_amount_dialog_add_more_button',
      ),
      onSecondary: addMoreText == null
          ? null
          : () => _submit(InventoryItemEatSheetIntent.addMore),
      children: [
        EatPageHeader(
          title: item.name,
          brand: item.brand,
          caption: calculator.hasOpenStock
              ? null
              : l10n.eatPageInStock(state.stockLabel(l10n)),
          imageUrl: item.imageUrl,
          fallbackKey: const Key('inventory_item_eat_sheet_hero_fallback'),
        ),
        if (nutrition != null)
          EatLabelTable(
            key: const Key('inventory_item_nutrition_table'),
            rows: nutritionFactsRows(
              context,
              eaten: nutrition.eaten,
              per100: nutrition.per100,
            ),
            per100Header: l10n.caloriesEntryPer100Label(
              state.nutritionUnit(l10n),
            ),
            eatenHeader: l10n.inventoryEatSheetAmountWithUnit(
              formatInventoryNutritionValue(nutrition.amount ?? 0),
              state.nutritionUnit(l10n),
            ),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EatAmountRuler(
              controller: amountField.controller,
              focusNode: amountField.focusNode,
              unitLabel: state.amountUnit(l10n),
              value: state.amountValue,
              max: state.amountMax,
              step: state.amountStep,
              marks: [
                for (final marker in state.markers)
                  EatRulerMark(
                    label: state.markLabel(l10n, marker),
                    value: marker.value,
                    isSelected: state.amountValue == marker.value,
                    onPressed: () => _controller.pickAmount(marker.value),
                  ),
              ],
              allowFractionalInput:
                  state.usesPortionMode ||
                  calculator.allowsFractionalInventoryAmount,
              hint: state.amountHint(l10n),
              errorText: state.amountError(l10n),
              onTextChanged: (text) => _controller.setAmountText(text),
              onSliderChanged: (value) => _controller.pickAmount(value),
            ),
            if (state.usesPortionMode) ...[
              EatInlineAmountField(
                fieldKey: InventoryItemEatSheetBody.pieceWeightKey,
                label: l10n.eatPagePieceWeight(state.defaultPortionLabel(l10n)),
                unitLabel: consumedUnitSymbol(l10n, state.portionUnit),
                controller: _pieceWeight.controller,
                focusNode: _pieceWeight.focusNode,
                errorText: state.portionAmountError(l10n),
                onChanged: _controller.setPortionAmountText,
                unitKey: InventoryItemEatSheetBody.pieceWeightUnitKey,
                onUnitPressed: units.length < 2
                    ? null
                    : _controller.switchPortionUnit,
              ),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final size in state.pieceSizes)
                    EatChip(
                      label: state.pieceSizeLabel(l10n, size),
                      isSelected: size == selectedSize,
                      onPressed: () => _controller.pickPieceSize(size),
                    ),
                ],
              ),
              if (state.pieceWeightLabel(l10n) case final weight?
                  when selectedSize?.label == null)
                EatRememberPortion(
                  amountLabel: weight,
                  linkLabel: l10n.eatPageRememberPieceSize,
                  nameHint: l10n.eatPagePieceSizeNameHint,
                  onSave: _controller.rememberPortion,
                ),
            ] else
              EatRememberPortion(
                amountLabel: state.enteredAmountLabel(l10n),
                onSave: _controller.rememberPortion,
              ),
            if (calculator.supportsInedibleAmountAdjustment)
              EatInedibleLine(
                controller: _inedibleAmount.controller,
                focusNode: _inedibleAmount.focusNode,
                errorText: state.inedibleError(l10n),
                unitLabel: state.amountUnit(l10n),
                summaryText: state.inedibleSummary(l10n),
                isExpanded: state.isInedibleExpanded,
                onChanged: (text) => _controller.setInedibleAmountText(text),
                onToggleExpanded: _toggleInedible,
              ),
          ],
        ),
      ],
    );
  }

  void _syncText(InventoryItemEatSheetState state) {
    _inventoryAmount.sync(state.inventoryAmountText);
    _pieceCount.sync(state.portionCountText);
    _pieceWeight.sync(state.portionAmountText);
    _inedibleAmount.sync(state.inedibleAmountText);
  }

  void _toggleInedible() {
    _controller.toggleInedible();
    if (!ref.read(_provider).isInedibleExpanded) {
      _inedibleAmount.focusNode.unfocus();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _inedibleAmount.focusNode.requestFocus();
      }
    });
  }

  void _submit(InventoryItemEatSheetIntent intent) {
    switch (_controller.submit(intent)) {
      case InventoryItemEatSubmitted(:final result):
        FocusManager.instance.primaryFocus?.unfocus();
        Navigator.of(context).pop(result);
      case InventoryItemEatRejected():
        return;
    }
  }
}
