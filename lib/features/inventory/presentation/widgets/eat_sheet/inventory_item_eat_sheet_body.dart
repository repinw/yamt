import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/product_missing_values.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_state.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_submission.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_eat_sheet_result.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_missing_values_hint.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_scaffold.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_text_field.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_when_menu.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/inventory_item_eat_amount_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/inventory_item_eat_label_section.dart';

/// Amount and log time chosen on the eat page so far.
typedef InventoryItemEatSelection = ({
  int? inventoryAmount,
  DateTime loggedAt,
  MealType mealType,
});

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
    this.footer,
    this.onSubmitted,
    this.confirmLabel,
    this.canPlan = true,
    this.mealKcal,
    this.secondaryIntent = InventoryItemEatSheetIntent.addMore,
    this.onSecondary,
    this.headerBrand,
    this.headerCaption,
    this.headerImageBytes,
    this.onSelectionChanged,
    this.header,
    this.showAmount = true,
    this.onCompleteValues,
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

  /// Content below the amount, such as the item hub's action card.
  final Widget? footer;

  /// Called with the entered result. Pops the page with it when null.
  final ValueChanged<InventoryItemEatSheetResult>? onSubmitted;

  /// Text of the confirm button. Defaults to "Log".
  final String? confirmLabel;

  /// Whether the page offers to plan; off where the result drops the plan.
  final bool canPlan;

  /// Calories of the whole meal, shown on the button in place of the
  /// item's own when other foods are picked.
  final double? mealKcal;

  /// Intent of the second button.
  final InventoryItemEatSheetIntent secondaryIntent;

  /// Runs in place of submitting [secondaryIntent].
  final VoidCallback? onSecondary;

  /// Line above the name in place of the item's brand.
  final String? headerBrand;

  /// Line under the name in place of the stock.
  final String? headerCaption;

  /// Local image in place of the item's image.
  final Uint8List? headerImageBytes;

  /// Called when the amount, the day, or the meal changes.
  final ValueChanged<InventoryItemEatSelection>? onSelectionChanged;

  /// Head in place of the item's header and nutrition label.
  final Widget? header;

  /// Whether the page shows its amount ruler.
  final bool showAmount;

  /// Opens the editor from the line that names the item's missing values.
  /// The line is hidden when null. A stock item also checks its package
  /// size; a newly picked product does not, since eating needs no package.
  final VoidCallback? onCompleteValues;

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
    ref.listen(_provider, (_, next) {
      _syncText(next);
      widget.onSelectionChanged?.call((
        inventoryAmount: next.enteredInventoryAmount,
        loggedAt: next.loggedAt,
        mealType: next.mealType,
      ));
    });
    final state = ref.watch(_provider);
    final item = widget.item;
    final nutrition = state.nutrition;
    final addMoreText = widget.addMoreActionText;
    final amountField = state.usesPortionMode ? _pieceCount : _inventoryAmount;
    final footer = widget.footer;

    return EatPageScaffold(
      whenControl: EatWhenMenu(
        loggedAt: state.loggedAt,
        today: state.today,
        mealType: state.mealType,
        onDayPicked: _controller.setLoggedDay,
        onMealTypeChanged: _controller.setMealType,
        allowsPlanDays: _canPlan,
      ),
      isPlan: state.isPlan,
      kcal: widget.mealKcal ?? nutrition?.eaten.kcal,
      confirmLabel: widget.confirmLabel,
      confirmButtonKey: const Key(
        'inventory_item_amount_dialog_confirm_button',
      ),
      onConfirm: () => _submit(widget.confirmIntent),
      onPlan: _canPlan ? _plan : null,
      cancelButtonKey: const Key('inventory_item_amount_dialog_cancel_button'),
      secondaryLabel: addMoreText,
      secondaryButtonKey: const Key(
        'inventory_item_amount_dialog_add_more_button',
      ),
      onSecondary: addMoreText == null
          ? null
          : widget.onSecondary ?? () => _submit(widget.secondaryIntent),
      children: [
        widget.header ??
            InventoryItemEatLabelSection(
              item: item,
              state: state,
              brand: widget.headerBrand,
              caption: widget.headerCaption,
              imageBytes: widget.headerImageBytes,
            ),
        if (_missingValues case final missing? when missing.isNotEmpty)
          EatMissingValuesHint(
            missing: missing,
            onPressed: widget.onCompleteValues!,
          ),
        if (widget.showAmount)
          InventoryItemEatAmountSection(
            state: state,
            controller: _controller,
            amountField: amountField,
            pieceWeight: _pieceWeight,
            inedibleAmount: _inedibleAmount,
            onToggleInedible: _toggleInedible,
          ),
        ?footer,
      ],
    );
  }

  // A page with its own confirm, such as adding to a meal, plans nothing.
  bool get _canPlan => widget.canPlan && widget.confirmLabel == null;
  List<ProductMissingValue>? get _missingValues {
    if (widget.onCompleteValues == null || widget.header != null) {
      return null;
    }
    return missingItemValues(
      widget.item,
      checkPackageSize: !widget.hasOpenStock,
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

  Future<void> _plan() async {
    final state = ref.read(_provider);
    final day = await showEatPlanDayPicker(
      context,
      today: state.today,
      loggedAt: state.loggedAt,
    );
    if (day == null || !mounted) return;
    _controller.setLoggedDay(day);
    _submit(widget.confirmIntent, asPlan: true);
  }

  void _submit(InventoryItemEatSheetIntent intent, {bool asPlan = false}) {
    switch (_controller.submit(intent, asPlan: asPlan)) {
      case InventoryItemEatSubmitted(:final result):
        FocusManager.instance.primaryFocus?.unfocus();
        final onSubmitted = widget.onSubmitted;
        if (onSubmitted != null) {
          onSubmitted(result);
          return;
        }
        Navigator.of(context).pop(result);
      case InventoryItemEatRejected():
        return;
    }
  }
}
