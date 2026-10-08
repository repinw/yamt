import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_eat_calculator.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_portions.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meal_eat_sheet_state.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_l10n.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/prepared_meal_serving_unit_l10n.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Texts of the prepared meal eat page.
extension PreparedMealEatSheetTexts on PreparedMealEatSheetState {
  /// Unit after the amount.
  String amountUnit(AppLocalizations l10n) {
    // In the pot the meal is one portion: the whole pot.
    if (calculator.meal.isInPot) {
      return l10n.eatPagePotUnit;
    }
    return switch (mode) {
      PreparedMealEatAmountMode.portions => preparedMealServingUnit(
        l10n,
        calculator.meal,
      ),
      PreparedMealEatAmountMode.grams => l10n.inventoryUnitGram,
    };
  }

  /// Portions left, such as "3½ Port.".
  String stockLabel(AppLocalizations l10n) {
    return l10n.inventoryEatSheetAmountWithUnit(
      _portions(calculator.meal.remainingPortions),
      preparedMealServingUnit(l10n, calculator.meal),
    );
  }

  /// Text of the ruler mark at [index] with [value]. The first mark is
  /// everything left.
  String markLabel(AppLocalizations l10n, int index, num value) {
    if (index == 0) {
      return l10n.eatPageAll;
    }
    return switch (mode) {
      PreparedMealEatAmountMode.portions => _portions(value),
      PreparedMealEatAmountMode.grams => _grams(l10n, value),
    };
  }

  /// Note beside the amount: the same amount in the other unit.
  String? amountHint(AppLocalizations l10n) {
    final entered = amount;
    if (entered == null || !calculator.canUseGrams) {
      return null;
    }
    final other = calculator.convertAmount(
      entered,
      from: mode,
      to: mode == PreparedMealEatAmountMode.portions
          ? PreparedMealEatAmountMode.grams
          : PreparedMealEatAmountMode.portions,
    );
    if (other == null) {
      return null;
    }
    return l10n.eatPageApprox(
      mode == PreparedMealEatAmountMode.portions
          ? _grams(l10n, other)
          : l10n.inventoryEatSheetAmountWithUnit(
              _portions(other),
              preparedMealServingUnit(l10n, calculator.meal),
            ),
    );
  }

  /// Header of the nutrition table: the eaten portions.
  String portionsHeader(AppLocalizations l10n) {
    final portions = portionsOrOne;
    return calculator.meal.isServedInPieces
        ? l10n.inventoryEatSheetPiecesHeader(portions, _portions(portions))
        : l10n.inventoryEatSheetPortionsHeader(portions, _portions(portions));
  }

  String _portions(num value) {
    return formatQuickChipAmount(
      value,
      (number) => formatPreparedMealPortions(number, localeName: localeName),
    );
  }

  String _grams(AppLocalizations l10n, num grams) {
    return l10n.inventoryEatSheetAmountWithUnit(
      formatInventoryAmountValue(
        amount: grams.round(),
        unit: InventoryAmountUnit.gram,
      ),
      l10n.inventoryUnitGram,
    );
  }
}
