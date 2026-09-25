import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/inventory/application/inventory_serving_suggestion_service.dart';
import 'package:yamt/features/inventory/application/serving_suggestion_resolver.dart';
import 'package:yamt/features/inventory/domain/global_food_serving_suggestion.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_calculator.dart';
import 'package:yamt/features/inventory/domain/inventory_item_open_eat_stock.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_options.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_state.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_submission.dart';
import 'package:yamt/features/inventory/presentation/formatters/inventory_nutrition_format.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_eat_sheet_result.dart';

part 'inventory_item_eat_sheet_controller.g.dart';

const _servingResolver = ServingSuggestionResolver();

/// Holds the input of the eat sheet for one inventory item.
@riverpod
class InventoryItemEatSheetController
    extends _$InventoryItemEatSheetController {
  var _learned = const GlobalFoodServingSuggestionSet.empty();

  @override
  InventoryItemEatSheetState build({
    required InventoryItem item,
    int? initialInventoryAmount,
    DateTime? initialLoggedAt,
    MealType? initialMealType,
    bool hasOpenStock = false,
  }) {
    final now = ref.watch(clockProvider)();
    final loggedAt = initialLoggedAt ?? now;
    final calculator = hasOpenStock
        ? openStockEatCalculator(item)
        : InventoryItemEatCalculator(
            item: item,
            maxAmount: consumableInventoryAmount(item) ?? 0,
          );
    final startAmount =
        initialInventoryAmount ??
        (hasOpenStock ? openStockDefaultAmount(calculator) : null);
    unawaited(Future.microtask(_loadServingSuggestions));
    return _derive(
      InventoryItemEatSheetState(
        calculator: calculator,
        inventoryAmountText: calculator.formatInventoryAmount(
          calculator.defaultInventoryAmount(startAmount),
        ),
        portionCountText: '1',
        portionAmountText: '',
        portionUnit: calculator.availablePortionUnits.first,
        portionLabel: null,
        inedibleAmountText: '',
        isInedibleExpanded: false,
        loggedAt: loggedAt,
        today: now,
        mealType: initialMealType ?? MealType.defaultForDateTime(loggedAt),
        markers: const [],
        rememberedPortions: const [],
        pieceSizes: const [],
        nutrition: null,
        errors: const {},
        didEditInventoryAmount: false,
        didEditPortion: false,
      ),
    );
  }

  /// Sets the amount field text.
  void setAmountText(String text) {
    if (state.usesPortionMode) {
      _update(
        withPortionAmounts(
          state.copyWith(
            portionCountText: text,
            didEditPortion: true,
            errors: _without(const {
              InventoryItemEatSheetError.invalidPortionCount,
              InventoryItemEatSheetError.invalidInventoryAmount,
            }),
          ),
        ),
      );
      return;
    }
    _update(
      state.copyWith(
        inventoryAmountText: text,
        didEditInventoryAmount: true,
        errors: _without(const {
          InventoryItemEatSheetError.invalidInventoryAmount,
        }),
      ),
    );
  }

  /// Sets the amount to [value] in the unit of the amount field, for
  /// example from the ruler.
  void pickAmount(double value) {
    setAmountText(
      state.usesPortionMode
          ? formatInventoryNutritionValue(value)
          : state.calculator.formatInventoryAmount(value.round()),
    );
  }

  /// Names the entered amount as a portion, or the entered piece weight as
  /// a piece size in portion mode. It is saved with the food.
  void rememberPortion(String? label) {
    final name = normalizePortionLabel(label);
    if (state.usesPortionMode) {
      final weight = parsePositiveDecimalInput(state.portionAmountText);
      if (weight == null) {
        return;
      }
      _update(
        state.copyWith(
          portionLabel: () => name,
          rememberedPortions: [
            ...state.rememberedPortions,
            InventoryItemEatPortion(
              amount: weight,
              unit: state.portionUnit,
              label: name,
            ),
          ],
        ),
      );
      return;
    }
    final amount = state.enteredInventoryAmount;
    final unit = state.calculator.fixedCalorieUnit;
    if (amount == null || amount < 1 || unit == null) {
      return;
    }
    _update(
      state.copyWith(
        rememberedPortions: [
          ...state.rememberedPortions,
          InventoryItemEatPortion(
            amount: amount.toDouble(),
            unit: unit,
            label: name,
          ),
        ],
      ),
    );
  }

  /// Uses [size] as the weight of one piece.
  void pickPieceSize(InventoryItemEatPortion size) {
    _update(
      withPortionAmounts(
        state.copyWith(
          portionAmountText: formatInventoryNutritionValue(size.amount),
          portionUnit: state.calculator.normalizePortionUnit(size.unit),
          portionLabel: () => size.label,
          didEditPortion: true,
          errors: _without(const {
            InventoryItemEatSheetError.invalidPortionAmount,
          }),
        ),
      ),
    );
  }

  /// Sets the weight of one piece. A typed weight has no size name.
  void setPortionAmountText(String text) {
    _update(
      withPortionAmounts(
        state.copyWith(
          portionAmountText: text,
          portionLabel: () => null,
          didEditPortion: true,
          errors: _without(const {
            InventoryItemEatSheetError.invalidPortionAmount,
          }),
        ),
      ),
    );
  }

  /// Switches the unit of the piece weight to the next available unit.
  void switchPortionUnit() {
    final units = state.calculator.availablePortionUnits;
    final next = units[(units.indexOf(state.portionUnit) + 1) % units.length];
    _update(
      withPortionAmounts(
        state.copyWith(portionUnit: next, didEditPortion: true),
      ),
    );
  }

  /// Sets the inedible amount field text.
  void setInedibleAmountText(String text) {
    _update(
      state.copyWith(
        inedibleAmountText: text,
        errors: _without(const {
          InventoryItemEatSheetError.invalidInedibleAmount,
          InventoryItemEatSheetError.inedibleTooLarge,
        }),
      ),
    );
  }

  /// Opens or closes the inedible section.
  void toggleInedible() {
    _update(state.copyWith(isInedibleExpanded: !state.isInedibleExpanded));
  }

  /// Logs the food on [day] at the current time of day.
  void setLoggedDay(DateTime day) {
    _update(
      state.copyWith(
        loggedAt: loggedAtOnDay(day, now: ref.read(clockProvider)()),
      ),
    );
  }

  /// Sets the meal the food is logged to.
  void setMealType(MealType mealType) {
    _update(state.copyWith(mealType: mealType));
  }

  /// Validates the input for [intent].
  InventoryItemEatSubmitOutcome submit(InventoryItemEatSheetIntent intent) {
    final draft = buildInventoryItemEatDraft(state);
    if (draft.hasValidationErrors) {
      _update(applyInventoryItemEatDraftErrors(state, draft));
      return const InventoryItemEatRejected();
    }
    return InventoryItemEatSubmitted(
      InventoryItemEatSheetResult(
        intent: intent,
        request: buildInventoryItemEatRequest(
          state,
          draft,
          namedPortions: namedPortions(state, _resolution(state)),
        ),
      ),
    );
  }

  Future<void> _loadServingSuggestions() async {
    if (!ref.mounted) {
      return;
    }
    final service = ref.read(inventoryServingSuggestionServiceProvider);
    final suggestions = await service.readSuggestions(state.calculator.item);
    if (!ref.mounted) {
      return;
    }
    _learned = suggestions;
    _update(withLearnedDefaults(state, _resolution(state)));
  }

  Set<InventoryItemEatSheetError> _without(
    Set<InventoryItemEatSheetError> removed,
  ) {
    return state.errors.difference(removed);
  }

  ServingSuggestionResolution _resolution(InventoryItemEatSheetState from) {
    return _servingResolver.resolve(
      item: from.calculator.item,
      learned: _learned,
      maxAmount: from.calculator.maxAmount,
      requiresManualPortion: from.calculator.requiresManualCaloriePortion,
    );
  }

  InventoryItemEatSheetState _derive(InventoryItemEatSheetState from) {
    return deriveInventoryItemEatSheetState(from, _resolution(from));
  }

  void _update(InventoryItemEatSheetState next) {
    state = _derive(next);
  }
}
