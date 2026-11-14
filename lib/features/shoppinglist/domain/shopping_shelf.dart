/// A part of the shop. The order is the usual way through a supermarket, so
/// the list follows it.
enum ShoppingShelf {
  /// Fruit and vegetables.
  produce,

  /// Bread and baked goods.
  bakery,

  /// Meat, sausage and fish.
  meatFish,

  /// Dairy, eggs and other chilled food.
  chilled,

  /// Frozen food.
  frozen,

  /// Pasta, rice, cans, spices and baking needs.
  pantry,

  /// Drinks.
  drinks,

  /// Sweets and snacks.
  sweets,

  /// Body care and medicine.
  drugstore,

  /// Cleaning and other household goods.
  household,

  /// Not assigned yet.
  other,
}

/// The picture of a product on the list.
enum ShoppingItemIcon {
  /// Fruit.
  fruit,

  /// Vegetables.
  vegetable,

  /// Herbs and salad.
  herb,

  /// Bread.
  bread,

  /// Breakfast pastry.
  pastry,

  /// Cake.
  cake,

  /// Meat and sausage.
  meat,

  /// Fish.
  fish,

  /// Milk and other drinks from the chilled shelf.
  milk,

  /// Eggs.
  egg,

  /// Cheese, yogurt and butter.
  dairy,

  /// Frozen food.
  frozen,

  /// Ice cream.
  iceCream,

  /// Pizza.
  pizza,

  /// Pasta and noodles.
  pasta,

  /// Rice and grains.
  grain,

  /// Cans and jars.
  can,

  /// Spices, oil and sauces.
  spice,

  /// Coffee.
  coffee,

  /// Tea.
  tea,

  /// Water.
  water,

  /// Juice and soft drinks.
  juice,

  /// Beer.
  beer,

  /// Wine and spirits.
  wine,

  /// Sweets.
  sweets,

  /// Biscuits and snacks.
  snack,

  /// Body care.
  care,

  /// Medicine.
  medicine,

  /// Baby needs.
  baby,

  /// Cleaning.
  cleaning,

  /// Laundry.
  laundry,

  /// Pet food.
  pet,

  /// Flowers and plants.
  flower,

  /// Anything else.
  other,
}

/// The default picture of [shelf], for a product the catalog does not know
/// more about.
ShoppingItemIcon shoppingShelfIcon(ShoppingShelf shelf) => switch (shelf) {
  ShoppingShelf.produce => ShoppingItemIcon.vegetable,
  ShoppingShelf.bakery => ShoppingItemIcon.bread,
  ShoppingShelf.meatFish => ShoppingItemIcon.meat,
  ShoppingShelf.chilled => ShoppingItemIcon.dairy,
  ShoppingShelf.frozen => ShoppingItemIcon.frozen,
  ShoppingShelf.pantry => ShoppingItemIcon.can,
  ShoppingShelf.drinks => ShoppingItemIcon.juice,
  ShoppingShelf.sweets => ShoppingItemIcon.sweets,
  ShoppingShelf.drugstore => ShoppingItemIcon.care,
  ShoppingShelf.household => ShoppingItemIcon.cleaning,
  ShoppingShelf.other => ShoppingItemIcon.other,
};
