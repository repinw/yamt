import 'package:meta/meta.dart';

/// Part of one Vorrat item that supplies a line: `amount` in the unit the
/// item is kept in. A line that names no amount, such as "Salz", takes 0.
typedef ItemTake = ({String itemId, int amount});

/// How a line of a cooking is settled. Before "In Vorrat" every line is
/// [LineAssigned] or [LineOmitted].
sealed class LineClarification {
  const new();
}

/// The line is not settled yet.
final class LineOpen extends LineClarification {
  /// Creates an open line.
  const new();
}

/// The line was turned down on the first page and waits on the second.
final class LineRejected extends LineClarification {
  /// Creates a rejected line.
  const new();
}

/// The line comes from the Vorrat [takes], first item first.
final class LineAssigned extends LineClarification {
  /// Creates an assigned line.
  const new(this.takes);

  /// The items and amounts that supply the line.
  final List<ItemTake> takes;
}

/// The line is left out of this cooking.
final class LineOmitted extends LineClarification {
  /// Creates an omitted line.
  const new();
}

/// The steps of cooking a recipe, in order.
enum CookStep {
  /// The recipe with its portions.
  recipe,

  /// The Vorrat suggestions to confirm or turn down.
  found,

  /// The lines without an accepted suggestion.
  open,

  /// The pot question.
  pot,

  /// Weight, count and "In Vorrat".
  portion,
}

/// The pot a meal is cooked in, or none.
sealed class CookPot {
  const new();
}

/// A saved utensil with its empty weight in grams.
final class CookPotUtensil extends CookPot {
  /// Creates the pot choice.
  const new({required this.utensilId, required this.emptyWeight});

  /// The id of the saved utensil.
  final String utensilId;

  /// The empty weight in grams, copied when chosen.
  final int emptyWeight;
}

/// No pot: the meal is counted, not weighed.
final class CookPotNone extends CookPot {
  /// Creates the choice.
  const new();
}

/// One cooking of a recipe: the cook's choices, held while it runs.
@immutable
class CookSession {
  /// Creates a session.
  const new({
    this.portions,
    this.step = CookStep.recipe,
    this.lines = const {},
    this.secondPage = const {},
    this.pot,
  });

  /// The portions cooked, `null` for the recipe's own.
  final int? portions;

  /// The step the cook is on.
  final CookStep step;

  /// The settled lines by line id; a line not in it is open.
  final Map<String, LineClarification> lines;

  /// The lines that moved to the second page: turned down there or
  /// settled there, so they stay there.
  final Set<String> secondPage;

  /// The chosen pot, `null` until chosen.
  final CookPot? pot;

  /// How the line [lineId] is settled.
  LineClarification lineOf(String lineId) => lines[lineId] ?? const LineOpen();

  /// The session with the line [lineId] settled as [clarification], on the
  /// second page from now on when [onSecondPage].
  CookSession withLine(
    String lineId,
    LineClarification clarification, {
    bool onSecondPage = false,
  }) => _copy(
    lines: {...lines, lineId: clarification},
    secondPage: onSecondPage ? {...secondPage, lineId} : null,
  );

  /// The session at [step].
  CookSession at(CookStep step) => _copy(step: step);

  /// The session for [portions] portions. A new amount opens every line
  /// again, since its takes were sized for the old one.
  CookSession withPortions(int portions) =>
      CookSession(portions: portions, step: step, pot: pot);

  /// Whether the line [lineId] belongs on the second page.
  bool isOnSecondPage(String lineId) => secondPage.contains(lineId);

  /// The session with [pot] chosen.
  CookSession withPot(CookPot pot) => _copy(pot: pot);

  /// What every line takes from the item [itemId], except [exceptLineId].
  int takenFrom(String itemId, {String? exceptLineId}) {
    var sum = 0;
    for (final MapEntry(:key, :value) in lines.entries) {
      if (key != exceptLineId && value is LineAssigned) {
        for (final take in value.takes) {
          if (take.itemId == itemId) sum += take.amount;
        }
      }
    }
    return sum;
  }

  CookSession _copy({
    CookStep? step,
    Map<String, LineClarification>? lines,
    Set<String>? secondPage,
    CookPot? pot,
  }) => CookSession(
    portions: portions,
    step: step ?? this.step,
    lines: lines ?? this.lines,
    secondPage: secondPage ?? this.secondPage,
    pot: pot ?? this.pot,
  );
}

/// How the cooked meal goes into the Vorrat: its `name`, `count` portions
/// or pieces (`inPieces`), and the pot on the scale in grams
/// (`grossWeight`, `null` without a pot).
typedef CookPortioning = ({
  String name,
  int count,
  bool inPieces,
  int? grossWeight,
});
