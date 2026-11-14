import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The shown name of [shelf].
String shoppingShelfLabel(AppLocalizations l10n, ShoppingShelf shelf) =>
    switch (shelf) {
      ShoppingShelf.produce => l10n.shoppingShelfProduce,
      ShoppingShelf.bakery => l10n.shoppingShelfBakery,
      ShoppingShelf.meatFish => l10n.shoppingShelfMeatFish,
      ShoppingShelf.chilled => l10n.shoppingShelfChilled,
      ShoppingShelf.frozen => l10n.shoppingShelfFrozen,
      ShoppingShelf.pantry => l10n.shoppingShelfPantry,
      ShoppingShelf.drinks => l10n.shoppingShelfDrinks,
      ShoppingShelf.sweets => l10n.shoppingShelfSweets,
      ShoppingShelf.drugstore => l10n.shoppingShelfDrugstore,
      ShoppingShelf.household => l10n.shoppingShelfHousehold,
      ShoppingShelf.other => l10n.shoppingShelfOther,
    };

/// The Material icon that draws [icon].
IconData shoppingItemIconData(ShoppingItemIcon icon) => switch (icon) {
  ShoppingItemIcon.fruit => Icons.yard_outlined,
  ShoppingItemIcon.vegetable => Icons.eco_outlined,
  ShoppingItemIcon.herb => Icons.grass_rounded,
  ShoppingItemIcon.bread => Icons.bakery_dining_outlined,
  ShoppingItemIcon.pastry => Icons.breakfast_dining_outlined,
  ShoppingItemIcon.cake => Icons.cake_outlined,
  ShoppingItemIcon.meat => Icons.kebab_dining_outlined,
  ShoppingItemIcon.fish => Icons.set_meal_outlined,
  ShoppingItemIcon.milk => Icons.local_drink_outlined,
  ShoppingItemIcon.egg => Icons.egg_outlined,
  ShoppingItemIcon.dairy => Icons.egg_alt_outlined,
  ShoppingItemIcon.frozen => Icons.ac_unit_rounded,
  ShoppingItemIcon.iceCream => Icons.icecream_outlined,
  ShoppingItemIcon.pizza => Icons.local_pizza_outlined,
  ShoppingItemIcon.pasta => Icons.ramen_dining_outlined,
  ShoppingItemIcon.grain => Icons.rice_bowl_outlined,
  ShoppingItemIcon.can => Icons.kitchen_outlined,
  ShoppingItemIcon.spice => Icons.soup_kitchen_outlined,
  ShoppingItemIcon.coffee => Icons.coffee_outlined,
  ShoppingItemIcon.tea => Icons.emoji_food_beverage_outlined,
  ShoppingItemIcon.water => Icons.water_drop_outlined,
  ShoppingItemIcon.juice => Icons.local_cafe_outlined,
  ShoppingItemIcon.beer => Icons.sports_bar_outlined,
  ShoppingItemIcon.wine => Icons.wine_bar_outlined,
  ShoppingItemIcon.sweets => Icons.cookie_outlined,
  ShoppingItemIcon.snack => Icons.fastfood_outlined,
  ShoppingItemIcon.care => Icons.spa_outlined,
  ShoppingItemIcon.medicine => Icons.medication_outlined,
  ShoppingItemIcon.baby => Icons.child_care_outlined,
  ShoppingItemIcon.cleaning => Icons.cleaning_services_outlined,
  ShoppingItemIcon.laundry => Icons.local_laundry_service_outlined,
  ShoppingItemIcon.pet => Icons.pets_rounded,
  ShoppingItemIcon.flower => Icons.local_florist_outlined,
  ShoppingItemIcon.other => Icons.sell_outlined,
};
