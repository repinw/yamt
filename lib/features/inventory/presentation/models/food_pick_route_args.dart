import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/presentation/models/prepared_meal_food_source.dart';

/// What the food pick (`AppRoutes.homeFoodPick`) starts with: the search for
/// [query], the barcode scanner, or the AI ([source]), for a meal food or
/// for the recipe line [ingredient].
class FoodPickRouteArgs {
  /// Creates the args.
  const new({
    this.source = PreparedMealFoodSource.search,
    this.query,
    this.ingredient,
    this.pieceWeight,
    this.ingredientUnit,
    this.ingredientNeed,
    this.takesFromStock = false,
    this.heldItemIds = const {},
  });

  /// Where the pick starts.
  final PreparedMealFoodSource source;

  /// The text the search starts with.
  final String? query;

  /// The recipe ingredient the food is for, such as "250 g Mehl": its page
  /// then asks how much is at home.
  final String? ingredient;

  /// The grams or ml of one piece of [ingredient], for a food in pieces that
  /// has no piece weight.
  final int? pieceWeight;

  /// The unit [ingredient] is measured in; null for a line without one.
  final InventoryAmountUnit? ingredientUnit;

  /// What [ingredient] needs, in [ingredientUnit].
  final int? ingredientNeed;

  /// Whether the caller also takes a food that is already in the Vorrat.
  final bool takesFromStock;

  /// The Vorrat items that have nothing left for [ingredient].
  final Set<String> heldItemIds;
}
