import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_prepared_meal_eat_request.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_eat_sheet_result.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/inventory_item_eat_sheet_body.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/prepared_meal_eat_sheet_body.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the eat sheet for [item] and returns the entered request.
Future<InventoryItemEatRequest?> showInventoryItemEatSheet({
  required BuildContext context,
  required InventoryItem item,
  int? initialInventoryAmount,
  DateTime? initialLoggedAt,
  MealType? initialMealType,
}) async {
  final result = await showInventoryItemEatSheetResult(
    context: context,
    item: item,
    initialInventoryAmount: initialInventoryAmount,
    initialLoggedAt: initialLoggedAt,
    initialMealType: initialMealType,
  );
  return result?.request;
}

/// Opens the eat sheet for [item] and also returns the chosen intent.
Future<InventoryItemEatSheetResult?> showInventoryItemEatSheetResult({
  required BuildContext context,
  required InventoryItem item,
  InventoryItemEatSheetIntent confirmIntent =
      InventoryItemEatSheetIntent.logOnly,
  int? initialInventoryAmount,
  DateTime? initialLoggedAt,
  MealType? initialMealType,
  String? addMoreActionText,
  bool hasOpenStock = false,
}) {
  return _showEatSheet(
    context,
    InventoryItemEatSheetBody(
      item: item,
      confirmIntent: confirmIntent,
      initialInventoryAmount: initialInventoryAmount,
      initialLoggedAt: initialLoggedAt,
      initialMealType: initialMealType,
      addMoreActionText: addMoreActionText,
      hasOpenStock: hasOpenStock,
    ),
  );
}

/// Opens the eat sheet for [meal] and returns the entered request.
Future<InventoryPreparedMealEatRequest?> showPreparedMealEatSheet(
  BuildContext context,
  PreparedMeal meal, {
  DateTime? initialLoggedAt,
  MealType? initialMealType,
}) {
  return _showEatSheet(
    context,
    PreparedMealEatSheetBody(
      meal: meal,
      localeName: AppLocalizations.of(context)!.localeName,
      initialLoggedAt: initialLoggedAt,
      initialMealType: initialMealType,
    ),
  );
}

Future<T?> _showEatSheet<T>(BuildContext context, Widget body) {
  return Navigator.of(
    context,
    rootNavigator: true,
  ).push<T>(MaterialPageRoute<T>(fullscreenDialog: true, builder: (_) => body));
}
