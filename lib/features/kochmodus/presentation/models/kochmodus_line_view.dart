import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_group.dart';
import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/recipes/domain/cook_line_measure.dart';
import 'package:yamt/features/recipes/domain/cook_line_not_counted.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// What a line takes from one Vorrat item: `item` is `null` when the item
/// is no longer in the Vorrat ("Eintrag fehlt"). `amount` is in the item's
/// unit and scale.
typedef KochmodusTake = ({String itemId, InventoryItem? item, int amount});

/// A food that "Hab ich" brought to the line `lineId`, for the line above
/// the card of "Was hast du da?": `item` as it went into the Vorrat (a full
/// pack, the amount the cook typed, or an estimated food,
/// `InventoryItem.aiEstimated`) or, with `fromStock`, as the Vorrat had it.
typedef KochmodusNewFood = ({
  String lineId,
  InventoryItem item,
  bool fromStock,
});

/// One Vorrat item as the picker of a line offers it, in the item's unit
/// and scale: what it still has for the line (`available`), what other
/// runs and the run's other lines took (`reserved`, "verplant"), what the
/// line needs from it (`needed`, at most `available` for a guessed weight,
/// `null` when its unit cannot supply the line), what is missing when it
/// alone fills the line (`missing`, "fehlt"), and whether it has nothing left
/// for the line (`held`). A line without a need holds no item.
typedef KochmodusOffer = ({
  InventoryItem item,
  int available,
  int reserved,
  int? needed,
  int missing,
  bool held,
});

/// What the Vorrat picker of one line offers: the foods whose name resembles
/// the line, best first (`matches`, "Passt vielleicht"), and every other food
/// of the Vorrat (`rest`, "Alles im Vorrat").
typedef KochmodusPickerOffers = ({
  List<KochmodusOffer> matches,
  List<KochmodusOffer> rest,
});

/// One row of the list of the Vorrat picker.
@immutable
sealed class KochmodusPickerRow {
  /// Creates the row.
  const new();
}

/// A Vorrat item the cook can tap.
final class KochmodusPickerOfferRow extends KochmodusPickerRow {
  /// Creates the row of [offer].
  const new(this.offer);

  /// The item as the picker offers it.
  final KochmodusOffer offer;
}

/// The header of the items of one receipt ("Nach Beleg").
final class KochmodusPickerReceiptRow extends KochmodusPickerRow {
  /// Creates the header of [group].
  const new(this.group);

  /// The receipt.
  final InventoryReceiptGroup group;
}

/// One line of the cooking as the page shows it.
@immutable
class KochmodusLineView {
  /// Creates the view of [line].
  const new({
    required this.line,
    required this.text,
    required this.parsed,
    required this.need,
    required this.roughNeed,
    required this.shown,
    required this.amountUnit,
    required this.takes,
    required this.needFromItem,
    required this.taken,
    required this.onlyAvailable,
    required this.availableForLine,
    required this.stockLeft,
    required this.entryMissing,
    required this.nutritionMissing,
    required this.takesNothing,
    required this.canFollowWeight,
    required this.weighsInstead,
    required this.weight,
    required this.potId,
    required this.pictureItem,
    required this.itemCount,
    required this.restOnList,
    required this.uncounted,
    required this.shortBy,
    required this.recipeHasPart,
  });

  /// The stored line: its text as written, its own amount and weight, the
  /// added items, and its conversion.
  final CookRunLine line;

  /// The line for this cooking, such as "750 g Hack" for 6 of 4 portions,
  /// or with the cook's own amount.
  final String text;

  /// What the recipe says for the run's portions, `null` without amount.
  /// "Rezept: …" of the amount sheet shows it.
  final TemplateIngredientRequirement? parsed;

  /// What this cooking needs: the cook's own amount, else [parsed], else
  /// the recipe's rough weight of the line.
  final TemplateIngredientRequirement? need;

  /// Whether [need] is only the recipe's rough weight ("≈ 20 g").
  final bool roughNeed;

  /// [need] as the row says it: whole when the first item is counted whole
  /// and so gives whole pieces (`cookNeedShownFor`).
  final TemplateIngredientRequirement? shown;

  /// The unit the amount sheet counts in: that of [need], or on a line without
  /// amount that of its first item (`cookOwnAmountUnit`).
  final TemplateIngredientUnit amountUnit;

  /// What the line takes, in the order the cook picked the items.
  final List<KochmodusTake> takes;

  /// What the line needs from its first item that is still in the Vorrat,
  /// in that item's unit and scale, or what the cook weighed when the takes
  /// follow it (`cookWeighedTake`); `null` without such an item or when its
  /// unit cannot supply the line.
  final ({int amount, InventoryAmountUnit? unit})? needFromItem;

  /// What the takes in the unit of [needFromItem] add up to, for
  /// "250 von 400 g".
  final int taken;

  /// The item a take holds too little of and what it still has for the
  /// line ("nur N da"), in its unit and scale; `null` when nothing is short.
  final ({InventoryItem item, int available})? onlyAvailable;

  /// What the line's items still have for it in the line's unit
  /// ("Vorhandenes" of the amount sheet); `null` when none of them can
  /// supply it.
  final int? availableForLine;

  /// What the foods the line names still have for it, in the first one's
  /// unit and scale ("350 ml da", `cookLineStockLeft`); `null` without one.
  final ({InventoryItem item, int amount})? stockLeft;

  /// Whether a take's item is no longer in the Vorrat ("Eintrag fehlt").
  final bool entryMissing;

  /// Whether a take's item lacks energy or a macro ("Nährwerte fehlen").
  final bool nutritionMissing;

  /// Whether the line names an amount but takes nothing, which holds
  /// "In Vorrat" back until it is weighed, takes another food, or is removed.
  final bool takesNothing;

  /// Whether the takes can follow a weight: all its items are still there
  /// and kept in grams or ml (`cookLineCanFollowWeight`).
  final bool canFollowWeight;

  /// Whether only a weight says what the line takes, so the amount opens the
  /// keypad: it can follow a weight, and its takes follow one now or the first
  /// item cannot supply its amount, such as "1 Möhre" from an item kept in
  /// grams.
  final bool weighsInstead;

  /// What the line brings into the pot: weighed, exact, estimated
  /// ("≈ geschätzt"), missing ("Gewicht fehlt") or not counted.
  final CookLineWeight weight;

  /// The pot the line goes into (a `CookPot.id` or `countedMealPotId`);
  /// `null` for an ignored line or before the pots are chosen.
  final String? potId;

  /// The item the line shows by image and name, `null` for the letter tile:
  /// the first item of [takes] that is still in the Vorrat and takes something,
  /// or just the first when none does (`cookNamedItems`).
  final InventoryItem? pictureItem;

  /// How many items of [takes] the line names ("Reis A + 1 weitere"): those
  /// still in the Vorrat that take something, at least [pictureItem].
  final int itemCount;

  /// Whether what the line lacks waits on the shopping list as its own line
  /// ("Rest steht auf der Einkaufsliste", `cookRestLineId`).
  final bool restOnList;

  /// A food the cook added for the line that takes nothing, because its unit
  /// cannot supply the line, such as a pack without its weight on "250 g
  /// Mehl" ("Mehl zählt noch nicht mit: Gewicht fehlt"); `null` when there is
  /// none.
  final InventoryItem? uncounted;

  /// The line's id.
  String get id => line.id;

  /// Where the line comes from: the recipe, "+ Zutat", or cooking.
  CookLineOrigin get origin => line.origin;

  /// How the line is settled.
  LineSettlement get settlement => line.settlement;

  /// What the line's items lack for what it needs, in the line's unit, while
  /// the cook has not answered it ("Zu wenig da", "Es fehlen N"); `null` when
  /// they hold enough, when the line is not assigned, follows a weight, needs
  /// only the recipe's rough weight or a part of a unit (but a guessed weight,
  /// `cookTakeGuessed`, with nothing left), misses an item, or its items
  /// cannot supply it, and for a guessed weight while its foods have some
  /// left. "Nur N nehmen" and "N kaufen" set the line's own amount to what is
  /// there.
  final int? shortBy;

  /// Whether the cook takes less than the recipe says ("Nur 300 ml"): the
  /// line's own amount, for the run's portions, is below the recipe's.
  bool get takesLess {
    final needed = need?.amount;
    final recipe = parsed?.amount;
    return line.amount != null &&
        needed != null &&
        recipe != null &&
        needed < recipe;
  }

  /// Whether weighing cannot help the line, because it takes nothing and
  /// cannot follow a weight: only another food or removing it does.
  bool get needsOtherFood => takesNothing && !canFollowWeight;

  /// Whether the line takes nothing until the cook weighs it while cooking
  /// ("Gewicht fehlt: beim Kochen wiegen"), such as "1 Möhre" from a food
  /// kept in grams without a piece weight.
  bool get weighWhileCooking => takesNothing && canFollowWeight;

  /// Whether a row puts "≈" before [text]: the line needs only a rough weight
  /// and its text names no measure of its own ("≈ 20 g Butter zum Braten",
  /// but "1 Prise Salz").
  bool get approxText => roughNeed && !cookTextStartsWithMeasure(line.text);

  /// Whether the line does not count in the nutrition by its text, such as a
  /// pinch of salt (`cookLineNotCounted`); left out, it says "zählt nicht mit"
  /// instead of "weggelassen".
  bool get notCounted => cookLineNotCounted(line.text);

  /// Whether the line takes something of the Vorrat item [itemId], or holds
  /// it without needing an amount, which takes nothing of any food.
  bool takesFrom(String itemId) => takes.any(
    (take) => take.itemId == itemId && (take.amount > 0 || need == null),
  );

  /// Whether the line under the card says what "Hab ich" brought ([food]):
  /// while the line takes something of it; while it only holds a new food,
  /// so its "Ändern" can give the amount or weight that the line cannot take
  /// from yet; and while it holds a Vorrat food it waits to weigh that still
  /// has something left for it.
  bool confirms(KochmodusNewFood food) =>
      takesFrom(food.item.id) ||
      ((!food.fromStock || (canFollowWeight && (stockLeft?.amount ?? 0) > 0)) &&
          takes.any((take) => take.itemId == food.item.id));

  /// Whether the line came in while cooking ("neu", dashed).
  bool get isNew => line.origin == CookLineOrigin.cooking;

  /// Whether the recipe's amount holds a part of a unit, as the row can say
  /// it ("1/2 Zitrone"), so no whole number the cook types is the recipe's. An
  /// item counted whole shows and takes the whole number: that one is.
  final bool recipeHasPart;

  /// The cook's own amount for [amount] from the amount sheet: `null` for
  /// the recipe's amount, so the line keeps scaling with the portions. A whole
  /// number that a part rounds to is the cook's: "1" on "1/4 Zwiebel" is a
  /// whole onion.
  int? ownAmountFor(int amount) =>
      amount == parsed?.amount && !recipeHasPart ? null : amount;
}
