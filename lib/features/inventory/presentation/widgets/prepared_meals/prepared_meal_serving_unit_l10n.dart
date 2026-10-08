import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Unit of one serving of [meal]: "Stk" for a meal served in pieces,
/// "Port." otherwise.
String preparedMealServingUnit(AppLocalizations l10n, PreparedMeal meal) {
  return meal.isServedInPieces
      ? l10n.inventoryUnitPiece
      : l10n.eatPagePortionsUnit;
}
