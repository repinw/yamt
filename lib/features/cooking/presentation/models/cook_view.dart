import 'package:meta/meta.dart';
import 'package:yamt/features/cooking/domain/cook_recipe.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// One item of a line's takes, ready to show: the item and its amount.
typedef CookTakeView = ({InventoryItem item, int amount});

/// One Vorrat item a line can take: what it still holds besides the other
/// lines, and what the line needs of it in its unit (`null` when its unit
/// cannot supply the line).
typedef CookOffer = ({InventoryItem item, int available, int? needed});

/// One recipe line as the cooking page shows it.
@immutable
class CookLineView {
  /// Creates the line view.
  const new({
    required this.line,
    required this.label,
    required this.food,
    required this.clarification,
    required this.offers,
    required this.moreOffers,
    required this.suggestion,
    required this.takes,
    required this.needed,
    required this.unit,
    this.scale = 1,
  });

  /// The recipe line.
  final RecipeLine line;

  /// The line sized for the portions cooked, such as "500 g Hack".
  final String label;

  /// The food the line names, such as "Hack".
  final String food;

  /// How the cook settled it.
  final LineClarification clarification;

  /// The Vorrat items whose name fits, best first.
  final List<CookOffer> offers;

  /// The other Vorrat items the line could take, behind "Alle anzeigen".
  final List<CookOffer> moreOffers;

  /// The suggested takes; empty when nothing fits.
  final List<CookTakeView> suggestion;

  /// The takes of an assigned line, else the suggestion.
  final List<CookTakeView> takes;

  /// What the line needs in [unit], `null` when no item fits its unit;
  /// 0 for a line without amount.
  final int? needed;

  /// The unit [needed] is counted in, `null` for pieces.
  final InventoryAmountUnit? unit;

  /// The scale [needed] is counted in, a thousand per piece for packs.
  final int scale;

  /// How much [takes] lack of [needed], 0 when they supply all of it.
  int get missing {
    final need = needed ?? 0;
    final have = takes.fold(0, (sum, take) => sum + take.amount);
    return need > have ? need - have : 0;
  }
}

/// The cooking page: the recipe, the cook's choices and every line.
@immutable
class CookView {
  /// Creates the view.
  const new({
    required this.recipe,
    required this.session,
    required this.portions,
    required this.lines,
  });

  /// The recipe being cooked.
  final CookRecipe recipe;

  /// The cook's choices.
  final CookSession session;

  /// The portions cooked.
  final int portions;

  /// The lines in recipe order.
  final List<CookLineView> lines;

  /// The lines the first page asks about: those with a suggestion, until
  /// the second page settles them.
  List<CookLineView> get foundLines => [
    for (final line in lines)
      if (_onFirstPage(line)) line,
  ];

  /// The lines the second page asks about: turned down on the first page,
  /// without a suggestion, or settled there.
  List<CookLineView> get openLines => [
    for (final line in lines)
      if (!_onFirstPage(line) || line.clarification is LineRejected) line,
  ];

  /// Whether every line is assigned or left out.
  bool get isSettled => lines.every(
    (line) =>
        line.clarification is LineAssigned || line.clarification is LineOmitted,
  );

  bool _onFirstPage(CookLineView line) =>
      !session.isOnSecondPage(line.line.id) &&
      (line.suggestion.isNotEmpty ||
          line.clarification is LineAssigned ||
          line.clarification is LineRejected);
}
