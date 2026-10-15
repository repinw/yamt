import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/features/inventory/domain/eat_meal_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_combine_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_state.dart';
import 'package:yamt/features/inventory/presentation/inventory_amount_unit_l10n.dart';
import 'package:yamt/features/inventory/presentation/inventory_combine_pick_flow.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_result.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_combine_food_row.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_framed_box.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_inline_amount_field.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_l10n.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_text_field.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_text_link.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Hub section of a meal: [hubItem] logged together with other foods.
///
/// Shows one row per food with its amount and calories, and a link to add
/// more. The hub's item card picks the first foods. Tapping a row opens a
/// field and a ruler for its amount; tapping the amount opens them with the
/// field focused, to type it. The hub item's row drives the hub's own
/// amount. The hub item can leave the meal like any other food.
class EatCombineSection extends ConsumerStatefulWidget {
  /// Creates the section.
  const new({
    required this.hubItem,
    required this.onRemoveHubItem,
    this.includesHubItem = true,
    super.key,
  });

  /// Key of the hub item's remove button.
  static const removeHubItemKey = Key('eat_combine_remove_hub_item');

  /// Key of the link that adds a food.
  static const addKey = Key('eat_combine_add');

  /// Key of the tappable amount in the row of the food [itemId].
  static Key amountKey(String itemId) => Key('eat_combine_amount_$itemId');

  /// Key of the amount field in the row of the food [itemId].
  static Key amountFieldKey(String itemId) =>
      Key('eat_combine_amount_field_$itemId');

  /// The hub's item.
  final InventoryItem hubItem;

  /// Whether the hub's item is part of the meal.
  final bool includesHubItem;

  /// Called when the user takes the hub's item out of the meal.
  final VoidCallback onRemoveHubItem;

  @override
  ConsumerState<EatCombineSection> createState() => _EatCombineSectionState();
}

class _EatCombineSectionState extends ConsumerState<EatCombineSection> {
  // One row is open at a time, so the open row's field holds this text.
  final _amount = EatSheetTextField();
  String? _openId;
  // Whether the open food's field holds text that is no amount it can take.
  var _isTypedAmountInvalid = false;
  // The open food's amount before typing. Typing saves each number, so an
  // invalid entry goes back to it, not to the last valid prefix.
  int? _untypedAmount;
  var _isTyping = false;

  InventoryItem get hubItem => widget.hubItem;

  InventoryItemEatSheetControllerProvider get _hubProvider =>
      inventoryItemEatSheetControllerProvider(item: hubItem);

  InventoryItemCombineControllerProvider get _combineProvider =>
      inventoryItemCombineControllerProvider(hubItem.id);

  // A hub item that left the meal can come back as a picked food.
  bool get _isHubOpen => widget.includesHubItem && _openId == hubItem.id;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final picks = ref.watch(_combineProvider);
    // The open field follows its amount, also when the ruler moves it.
    ref
      ..listen(_hubProvider, (_, next) {
        if (_isHubOpen) _amount.sync(next.inventoryAmountText);
      })
      ..listen(_combineProvider, (_, next) => _syncPickAmount(next));

    return EatFramedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.includesHubItem) _hubRow(ref.watch(_hubProvider), l10n),
          for (final pick in picks) _pickRow(pick, l10n),
          EatTextLink(
            buttonKey: EatCombineSection.addKey,
            label: l10n.eatPageCombineAdd,
            onPressed: _add,
          ),
        ],
      ),
    );
  }

  /// Row of the hub's item. Its amount is the page's own and is checked
  /// like there: an invalid amount shows its error once the page confirms.
  EatCombineFoodRow _hubRow(
    InventoryItemEatSheetState hubState,
    AppLocalizations l10n,
  ) {
    final id = hubItem.id;
    final kcal = hubState.nutrition?.eaten.kcal;
    final hasRuler = inventoryItemUsesFixedCalorieUnit(hubItem);
    return EatCombineFoodRow(
      name: hubItem.name,
      amount: hubState.enteredAmountLabel(l10n),
      kcal: kcal == null ? null : l10n.eatPageKcal(kcal.round()),
      isOpen: _isHubOpen,
      onTap: () => _toggle(id),
      removeKey: EatCombineSection.removeHubItemKey,
      onRemove: widget.onRemoveHubItem,
      // The page's own ruler is hidden in a meal, so its error shows here.
      errorText: hubState.amountError(l10n),
      amountKey: EatCombineSection.amountKey(id),
      onAmountTap: hasRuler ? () => _typeAmount(id) : null,
      amountField: hasRuler
          ? _amountField(
              id,
              hubState.amountUnit(l10n),
              (text) => ref.read(_hubProvider.notifier).setAmountText(text),
            )
          : null,
      ruler: hasRuler
          ? EatRuler(
              value: hubState.amountValue,
              max: hubState.amountMax,
              step: hubState.amountStep,
              marks: const <EatRulerMark>[],
              onChanged: (value) =>
                  ref.read(_hubProvider.notifier).pickAmount(value),
            )
          : null,
    );
  }

  /// Row of a picked food. A typed amount the food cannot take shows its
  /// error at once and leaves the amount as it was.
  EatCombineFoodRow _pickRow(InventoryCombinePick pick, AppLocalizations l10n) {
    final id = pick.item.id;
    // Only foods counted in grams or milliliters take an amount here.
    final unit = defaultMealFoodAmount(pick.item) == null
        ? null
        : pick.item.amountUnit;
    final isOpen = _openId == id;
    return EatCombineFoodRow(
      key: ValueKey<String>(id),
      name: pick.item.name,
      amount: pick.component.amountLabel,
      kcal: l10n.eatPageKcal(pick.component.totalKcal.round()),
      isOpen: isOpen,
      onTap: () => _toggle(id),
      onRemove: () => ref.read(_combineProvider.notifier).remove(id),
      errorText: isOpen && _isTypedAmountInvalid
          ? l10n.inventoryReceiptReviewInvalidNumber
          : null,
      amountKey: EatCombineSection.amountKey(id),
      onAmountTap: unit == null ? null : () => _typeAmount(id),
      amountField: unit == null
          ? null
          : _amountField(
              id,
              unit.localizedName(l10n),
              (text) => _typePickAmount(id, text),
            ),
      ruler: unit == null
          ? null
          : EatRuler(
              value: pick.request.inventoryAmount.toDouble(),
              max: mealFoodMaxAmount(
                pick.item,
                hasOpenStock: pick.searchResult != null,
              ).toDouble(),
              step: AppFoodLabel.mealRulerStep,
              marks: const <EatRulerMark>[],
              onChanged: (value) => ref
                  .read(_combineProvider.notifier)
                  .setAmount(id, value.round()),
            ),
    );
  }

  EatInlineAmountField _amountField(
    String id,
    String unitLabel,
    ValueChanged<String> onChanged,
  ) {
    return EatInlineAmountField(
      fieldKey: EatCombineSection.amountFieldKey(id),
      label: AppLocalizations.of(context)!.eatPageCombineAmount,
      unitLabel: unitLabel,
      controller: _amount.controller,
      focusNode: _amount.focusNode,
      onChanged: onChanged,
    );
  }

  void _toggle(String id) => _open(_openId == id ? null : id);

  /// Opens the row of [id] with its field focused, so typing replaces the
  /// amount.
  void _typeAmount(String id) {
    if (_openId != id) {
      _open(id);
    }
    // The field is built with the open row in the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _amount.focusNode.requestFocus();
      }
    });
  }

  /// Opens the row of [id], or closes all rows for null, and shows the
  /// open row's amount in the field.
  void _open(String? id) {
    _amount.focusNode.unfocus();
    setState(() {
      _openId = id;
      _isTypedAmountInvalid = false;
    });
    if (_isHubOpen) {
      _amount.sync(ref.read(_hubProvider).inventoryAmountText);
      return;
    }
    for (final pick in ref.read(_combineProvider)) {
      if (pick.item.id == id) {
        _untypedAmount = pick.request.inventoryAmount;
        _amount.sync('$_untypedAmount');
      }
    }
  }

  void _typePickAmount(String id, String text) {
    final notifier = ref.read(_combineProvider.notifier);
    _isTyping = true;
    final taken = notifier.setAmountText(id, text);
    // A cleared field waits for the next number.
    final isInvalid = !taken && text.trim().isNotEmpty;
    final untyped = _untypedAmount;
    if (isInvalid && untyped != null) notifier.setAmount(id, untyped);
    _isTyping = false;
    setState(() => _isTypedAmountInvalid = isInvalid);
  }

  /// Shows the open food's amount in its field, unless the typed text
  /// already gives it, so a typed "37,5" stays while the food takes 38 g.
  void _syncPickAmount(List<InventoryCombinePick> picks) {
    final pick = picks.where((pick) => pick.item.id == _openId).firstOrNull;
    // Typed text stays in the field, also when it is invalid.
    if (pick == null || _isTyping) {
      return;
    }
    _untypedAmount = pick.request.inventoryAmount;
    _amount.syncValue(
      '${pick.request.inventoryAmount}',
      (text) => typedMealFoodAmount(
        pick.item,
        text,
        hasOpenStock: pick.searchResult != null,
      )?.toDouble(),
    );
    // The field holds an amount the food takes again.
    if (_isTypedAmountInvalid) {
      setState(() => _isTypedAmountInvalid = false);
    }
  }

  void _add() => InventoryCombinePickFlow.pick(
    context: context,
    ref: ref,
    hubItem: hubItem,
    includesHubItem: widget.includesHubItem,
  );
}
