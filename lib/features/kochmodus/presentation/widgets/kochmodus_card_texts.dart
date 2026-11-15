import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_text.dart';
import 'package:yamt/features/recipes/domain/cook_line_measure.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One calm line on the card of a line; `warn` for what is missing.
typedef KochmodusCardHint = ({String text, bool warn});

/// What the card of [line] says large: the amount ("250 g", "3", "≈ 20 g",
/// "1 Prise", what was weighed) and the food under it ("Mehl", "Butter zum
/// Braten", "Salz"). A text with a measure of its own that cannot be split
/// safely stays whole as the name, without an amount.
({String? amount, String name}) kochmodusCardTitle(
  AppLocalizations l10n,
  KochmodusLineView line,
) {
  final need = line.shown;
  final text = line.line.text.trim();
  final weighed = line.weighsInstead ? line.line.weighed : null;
  if (weighed != null) {
    return (amount: l10n.cookAmountGrams('$weighed'), name: need?.name ?? text);
  }
  // A rough weight adds nothing to a text with its own measure.
  if (need != null && !(line.roughNeed && cookTextStartsWithMeasure(text))) {
    final amount = kochmodusNeedText(l10n, need);
    return (
      amount: line.roughNeed ? l10n.eatPageApprox(amount) : amount,
      name: need.name,
    );
  }
  final measure = cookTextMeasure(text);
  return measure == null
      ? (amount: null, name: line.text)
      : (amount: measure.measure, name: measure.food);
}

/// What the card of [line] asks or says in small capitals, before they are
/// made capitals.
String kochmodusCardLabel(AppLocalizations l10n, KochmodusLineView line) =>
    switch (line.settlement) {
      LineOpen() => l10n.kochmodusCardAsk,
      LineAssigned() when line.shortBy != null => l10n.kochmodusRowShort,
      LineAssigned() when line.needsOtherFood => l10n.kochmodusRowUnclear,
      LineAssigned() => l10n.kochmodusCardReady,
      LineShopping() => l10n.kochmodusRowShopping,
      LineIgnored() when line.notCounted => l10n.kochmodusRowNotCounted,
      LineIgnored() => l10n.kochmodusRowIgnored,
    };

/// The state of [line] in its row of "Alle Zutaten" in a word or two: what
/// is there in the unit its food is kept in ("500 g da", "350 ml da" on "5 EL
/// Öl", [kochmodusThereText]), "im Einkauf", "weggelassen", "zählt nicht mit",
/// "zu wenig da", "Menge unklar", "Gewicht fehlt" for a line that is weighed
/// while cooking, and for an open line "jetzt" while it is on the card
/// ([onCard]), else "offen".
String kochmodusRowWord(
  AppLocalizations l10n,
  KochmodusLineView line, {
  required bool onCard,
}) => switch (line.settlement) {
  LineOpen() => onCard ? l10n.kochmodusRowNow : l10n.kochmodusRowOpen,
  LineAssigned() when line.shortBy != null => l10n.kochmodusRowShort,
  LineAssigned() when line.needsOtherFood => l10n.kochmodusRowUnclear,
  LineAssigned() when line.weighWhileCooking => l10n.kochmodusWeightMissing,
  LineAssigned() => switch (kochmodusThereText(l10n, line)) {
    final amount? => l10n.kochmodusRowThere(amount),
    null => l10n.kochmodusRowReady,
  },
  LineShopping() => l10n.kochmodusRowShopping,
  LineIgnored() when line.notCounted => l10n.kochmodusRowNotCounted,
  LineIgnored() => l10n.kochmodusRowIgnored,
};

/// The calm lines on the card of [line]. An open line has none: the cook
/// picks the food, so the card never says what the Vorrat might hold; only a
/// line that does not count says so. A line taken from the Vorrat names its
/// foods with what is there, the notes ("Nur 300 ml", "Rest steht auf der
/// Einkaufsliste", "≈ 180 g") and, as warnings, what is missing.
List<KochmodusCardHint> kochmodusCardHints(
  AppLocalizations l10n,
  KochmodusLineView line,
) {
  KochmodusCardHint calm(String text) => (text: text, warn: false);
  KochmodusCardHint warn(String text) => (text: text, warn: true);
  return switch (line.settlement) {
    LineOpen() when line.notCounted => [calm(l10n.kochmodusCardNotCounted)],
    LineOpen() => const [],
    LineAssigned() => [
      if (_items(l10n, line) case final items?) calm(items),
      if (line.need case final need? when line.takesLess)
        calm(l10n.kochmodusReadyOnly(kochmodusNeedText(l10n, need))),
      if (line.restOnList) calm(l10n.kochmodusReadyRestOnList),
      if (line.weight case CookWeightEstimated(:final grams))
        calm(
          l10n.eatPageApprox(
            kochmodusWeightText(l10n, grams, line.pictureItem),
          ),
        ),
      ..._problems(l10n, line).map(warn),
    ],
    LineShopping() => const [],
    LineIgnored() => [
      calm(
        line.notCounted
            ? l10n.kochmodusCardNotCounted
            : l10n.kochmodusChangeIgnoreSub,
      ),
    ],
  };
}

// The items a line takes: the first by name, then how many more, with what
// they have for the line in the first one's unit ("Mehl 405 · 500 g da").
String? _items(AppLocalizations l10n, KochmodusLineView line) {
  final first = line.pictureItem;
  if (first == null) return null;
  final items = l10n.kochmodusAssignItems(first.name, line.itemCount - 1);
  return switch (kochmodusThereText(l10n, line)) {
    final amount? => l10n.kochmodusAssignItemThere(items, amount),
    null => items,
  };
}

// What keeps a line from going into the pot as it is, in the order the cook
// fixes them. What is missing of a line with too little says it once.
List<String> _problems(AppLocalizations l10n, KochmodusLineView line) => [
  if (line.entryMissing) l10n.kochmodusEntryMissing,
  if (line.shortBy case final missing?)
    if (line.need case final need?)
      l10n.kochmodusAmountMissing(
        kochmodusAmountText(l10n, missing, need.unit, need.countMeasureLabel),
      ),
  if (line.shortBy == null)
    if (line.onlyAvailable case (item: final short, :final available)?)
      l10n.kochmodusOnlyAvailable(
        kochmodusItemAmountText(l10n, available, short.amountUnit, short),
      ),
  if (line.uncounted case final food?)
    l10n.kochmodusUncounted(food.name)
  else if (line.needsOtherFood)
    l10n.kochmodusTakesNothing
  else if (line.weighWhileCooking)
    l10n.kochmodusCardWeighWhileCooking,
  if (line.nutritionMissing) l10n.kochmodusNutritionMissing,
];
