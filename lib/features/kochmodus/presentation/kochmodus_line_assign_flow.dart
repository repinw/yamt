import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/kochmodus/application/cook_line_parse.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_controller.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_picker_offers.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_food_search_flow.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_take_flow.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_change_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_item_picker_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_picker_parts.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Hab ich", "Kaufen" or "Weglassen" of one line. "Hab ich" never takes a
/// food by itself: the cook picks it in the Vorrat picker, or in the product
/// search with the line's food when the Vorrat is empty or from the picker's
/// "Etwas anderes suchen" (`KochmodusFoodSearchFlow`). When the one food he
/// picked holds a bit more than the line needs, he is asked how much he takes
/// (`KochmodusTakeFlow`).
abstract final class KochmodusLineAssignFlow {
  const new _();

  /// "Ändern" of [line] of the cooking of [target]: asks what it does ("Zutat
  /// ändern", or "Was hast du da?" while it is open) and stores the answer.
  /// Free cooking has no shopping list, and without [canShop] it is not
  /// offered either: from "Portion" a shopping line would lock "Kochen" and
  /// "Portion". Returns whether the answer was stored; `false` when the cook
  /// backed out, the line is gone or the write failed.
  static Future<bool> assign({
    required BuildContext context,
    required KochmodusTarget target,
    required KochmodusLineView line,
    bool canShop = true,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final view = _viewOf(context, target);
    if (view == null || view.lines.every((other) => other.id != line.id)) {
      return false;
    }
    final answer = await KochmodusChangeSheet.show(
      context,
      title: line.settlement is LineOpen
          ? l10n.kochmodusAssignTitle
          : l10n.kochmodusChangeTitle,
      line: line.text,
      answers: [
        KochmodusChange.have,
        // A line that came in while cooking is cleared on "Portion", which
        // has no pause for the shopping.
        if (canShop &&
            !view.isFree &&
            !line.isNew &&
            line.settlement is! LineShopping)
          KochmodusChange.shop,
        if (line.settlement is! LineIgnored) KochmodusChange.ignore,
      ],
    );
    if (answer == null || !context.mounted) return false;
    return await store(
      context: context,
      target: target,
      line: line,
      answer: answer,
    );
  }

  /// Stores [answer] for [line] of the cooking of [target]: "Hab ich" picks
  /// or finds a food ([have]), "Kaufen" and "Weglassen" settle the line.
  /// [onFood] hears of a food that "Hab ich" brought once it is stored.
  /// Returns whether it was stored; `false` when the cook backed out, the line
  /// is gone or the write failed.
  static Future<bool> store({
    required BuildContext context,
    required KochmodusTarget target,
    required KochmodusLineView line,
    required KochmodusChange answer,
    ValueChanged<KochmodusNewFood>? onFood,
  }) async {
    final choice = switch (answer) {
      KochmodusChange.have => await have(
        context: context,
        target: target,
        line: line,
        onFood: onFood,
      ),
      KochmodusChange.shop => _settled(line.id, const LineShopping()),
      KochmodusChange.ignore => _settled(line.id, const LineIgnored()),
    };
    if (choice == null || !context.mounted) return false;
    return await KochmodusActionFlow.run(context, target, choice);
  }

  /// "Zweite Packung" of [line]: the Vorrat picker with the line's items
  /// picked, so another item fills what they lack; [onFood] as for [store].
  /// Returns whether the pick was stored.
  static Future<bool> pickMore({
    required BuildContext context,
    required KochmodusTarget target,
    required KochmodusLineView line,
    ValueChanged<KochmodusNewFood>? onFood,
  }) async {
    final choice = await _pick(context, target, line, onFood, keep: true);
    if (choice == null || !context.mounted) return false;
    return await KochmodusActionFlow.run(context, target, choice);
  }

  // [lineId] goes on the shopping list or is left out ([settlement]).
  static KochmodusLineChoice _settled(
    String lineId,
    LineSettlement settlement,
  ) =>
      (controller) => controller.settle(lineId, settlement);

  // [lineId] takes [itemIds] in that order, after [own] in the same change.
  static KochmodusLineChoice _assigned(
    String lineId,
    List<String> itemIds, [
    KochmodusTakeAmount? own,
  ]) =>
      (controller) => controller.assignItems(lineId, itemIds, own: own);

  /// "Hab ich" of [line] of the cooking of [target], without storing it: the
  /// Vorrat picker ("Welches nimmst du?") whenever the Vorrat holds a food,
  /// where the food the cook taps replaces the line's foods ("Anderes
  /// nehmen"), else the product search with the line's food, where the found
  /// food replaces them too (`KochmodusFoodSearchFlow`); [onFood] hears of the
  /// food picked or brought by the search once it is stored. `null` when the
  /// cook backed out, the line is gone or a found food could not be saved.
  /// A found food is already in the Vorrat then, and leaves it again when the
  /// choice fails to store.
  static Future<KochmodusLineChoice?> have({
    required BuildContext context,
    required KochmodusTarget target,
    required KochmodusLineView line,
    ValueChanged<KochmodusNewFood>? onFood,
  }) async {
    final view = _viewOf(context, target);
    if (view == null || view.lines.every((other) => other.id != line.id)) {
      return null;
    }
    return kochmodusOffers(view, line.id).isEmpty
        ? await KochmodusFoodSearchFlow.find(
            context,
            target: target,
            line: line,
            onFood: onFood,
            keep: false,
          )
        : await _pick(context, target, line, onFood);
  }

  static KochmodusView? _viewOf(BuildContext context, KochmodusTarget target) =>
      ProviderScope.containerOf(
        context,
        listen: false,
      ).read(kochmodusControllerProvider(target)).value;

  // The picker of [line], with its foods tapped already to [keep] them
  // ("Zweite Packung"); "Etwas anderes suchen" goes on to the search, where a
  // found food replaces the line's foods unless they are kept.
  static Future<KochmodusLineChoice?> _pick(
    BuildContext context,
    KochmodusTarget target,
    KochmodusLineView line,
    ValueChanged<KochmodusNewFood>? onFood, {
    bool keep = false,
  }) async {
    final view = _viewOf(context, target);
    if (view == null || view.lines.every((other) => other.id != line.id)) {
      return null;
    }
    final lineId = line.id;
    final offers = kochmodusPickerOffers(
      view,
      lineId,
      localeCode: Localizations.localeOf(context).languageCode,
    );
    final result = await KochmodusItemPickerSheet.show(
      context,
      title: line.text,
      need: line.need,
      offers: offers,
      picked: [
        if (keep)
          for (final take in line.takes) take.itemId,
      ],
      holders: view.holders,
    );
    if (result == null || !context.mounted) return null;
    final itemIds = result.ids;
    if (itemIds.isEmpty) {
      return await KochmodusFoodSearchFlow.find(
        context,
        target: target,
        line: line,
        onFood: onFood,
        keep: keep,
      );
    }
    final picked = [for (final id in itemIds) ?view.items[id]];
    if (picked.isEmpty) return _assigned(lineId, itemIds);
    final need = line.need;
    if (need != null && result.short != KochmodusPickerShort.keep) {
      // "Nur N nehmen" / "N kaufen": what the tapped foods hold becomes the
      // line's amount, and for "N kaufen" the rest goes on the list.
      final offered = {
        for (final offer in [...offers.matches, ...offers.rest])
          offer.item.id: offer,
      };
      final missing = kochmodusPickerStillMissing([
        for (final id in itemIds) ?offered[id],
      ], need);
      final rest = TemplateIngredientRequirement(
        amount: missing,
        unit: need.unit,
        name: need.name,
        countMeasureLabel: need.countMeasureLabel,
      );
      return KochmodusTakeFlow.told(
        (controller) => controller.assignItems(
          lineId,
          itemIds,
          own: (
            amount: line.ownAmountFor(need.amount - missing),
            unit: line.parsed == null ? line.amountUnit : null,
          ),
          rest: result.short == KochmodusPickerShort.buyRest
              ? cookLineLabel(line.line, rest)
              : null,
        ),
        onFood,
        (lineId: lineId, item: picked.first, fromStock: true),
      );
    }
    return await KochmodusTakeFlow.taken(
      context,
      view: view,
      line: line,
      items: picked,
      choice: (own) => KochmodusTakeFlow.told(
        _assigned(lineId, itemIds, own),
        onFood,
        (lineId: lineId, item: picked.first, fromStock: true),
      ),
    );
  }
}
