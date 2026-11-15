import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/application/cook_take_ask.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_controller.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_text.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_take_sheet.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The line's own amount for this cooking that the cook answered to "Wie
/// viel nimmst du?": `amount`, `null` for the recipe's; in `unit` when the
/// line's text names none.
typedef KochmodusTakeAmount = ({int? amount, TemplateIngredientUnit? unit});

/// What the cook chose for a line, not stored yet: it stores the choice
/// through the controller and returns `false` when the write failed. A food
/// found for it leaves the Vorrat again when the write fails.
typedef KochmodusLineChoice = Future<bool> Function(
  KochmodusController controller,
);

/// "Wie viel nimmst du?" after the cook picked one Vorrat food for a line.
abstract final class KochmodusTakeFlow {
  const new _();

  /// What [choice] stores, which takes [items] from the Vorrat for [line] of
  /// [view]: when that is one food, with the line's own amount the cook
  /// answers to "Wie viel nimmst du?", in the same change; with `null` (the
  /// line keeps its amount) for several foods, when nothing is asked, and when
  /// he keeps the line's amount.
  static Future<KochmodusLineChoice> taken(
    BuildContext context, {
    required KochmodusView view,
    required KochmodusLineView line,
    required List<InventoryItem> items,
    required KochmodusLineChoice Function(KochmodusTakeAmount? own) choice,
  }) async {
    if (items.length != 1) return choice(null);
    final own = await _ask(context, view: view, line: line, item: items.single);
    return choice(
      own == null
          ? null
          : (
              amount: own.own,
              unit: line.parsed == null ? line.amountUnit : null,
            ),
    );
  }

  /// [choice], which tells [onFood] of [food] once it is stored.
  static KochmodusLineChoice told(
    KochmodusLineChoice choice,
    ValueChanged<KochmodusNewFood>? onFood,
    KochmodusNewFood food,
  ) => (controller) async {
    final stored = await choice(controller);
    if (stored) onFood?.call(food);
    return stored;
  };

  // Asks how much of [item] the cook takes for [line] of [view] when it
  // holds a bit more than the recipe's amount, or the line's when its text
  // names none (`cookTakeAsk`); "Andere Menge" opens the amount sheet.
  // Returns the line's own amount for this cooking, `(own: null)` for the
  // recipe's ("400 g · wie im Rezept", also over an own amount), or `null`
  // to keep the line's amount: when nothing is asked, for the first answer
  // of a line whose text names no amount, and when the cook closes the
  // question or the amount sheet.
  static Future<KochmodusAmountChoice?> _ask(
    BuildContext context, {
    required KochmodusView view,
    required KochmodusLineView line,
    required InventoryItem item,
  }) async {
    final food = view.items[item.id] ?? item;
    final there = view.stockLeftOf(line, food);
    final recipe = line.parsed;
    final ask = cookTakeAsk(
      line: line.line,
      need: recipe ?? line.need,
      rough: line.roughNeed,
      item: food,
      there: there,
    );
    if (ask == null) return null;
    final l10n = AppLocalizations.of(context)!;
    String amount(int value) =>
        kochmodusItemAmountText(l10n, value, food.amountUnit, food);
    final answer = await KochmodusTakeSheet.show(
      context,
      line: line.text,
      food: l10n.kochmodusAssignItemThere(food.name, amount(there)),
      keep: amount(ask.needed),
      fromRecipe: recipe != null,
      all: amount(there),
    );
    if (!context.mounted) return null;
    return switch (answer) {
      null => null,
      KochmodusTakeAnswer.recipe =>
        recipe == null || line.line.amount == null ? null : (own: null),
      KochmodusTakeAnswer.all => (own: line.ownAmountFor(ask.all)),
      KochmodusTakeAnswer.other => await KochmodusAmountSheet.show(
        context,
        line: line,
        portions: view.run.portions,
      ),
    };
  }
}
