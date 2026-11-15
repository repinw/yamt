import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/domain/cook_line_food.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'prepared_meal_food_source.dart';
import 'package:yamt/features/inventory/presentation/'
    'prepared_meal_pending_food_flow.dart';
import 'package:yamt/features/kochmodus/application/cook_pick_need.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_controller.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_picker_offers.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_take_flow.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Hab ich" of a line through the product search: when the Vorrat is empty
/// or from the picker's "Etwas anderes suchen".
abstract final class KochmodusFoodSearchFlow {
  const new _();

  /// Which food [line] of the cooking of [target] takes, scanning first, the
  /// search starting with the food the line names, and a line in spoons
  /// asking by weight (`cookPickNeed`). A food new to the Vorrat goes in (one
  /// full pack, the amount the cook typed, or exactly the line's need for an
  /// estimated one) and the line takes what it needs of it; a food the Vorrat
  /// holds already (a hit, "Aus dem Vorrat nehmen", or a scanned pack) is
  /// taken from there and never removed, unless it has nothing left for the
  /// line (`kochmodusHeldItemIds`): then its product goes in as a new pack.
  /// The found food replaces the line's foods ("Anderes nehmen"); with [keep]
  /// ("Zweite Packung") they stay after it and give only what is still
  /// missing. When the line takes that one food, the cook is asked "Wie viel
  /// nimmst du?" with the cooking as it is after the search. [onFood] hears of
  /// the food once it is stored. A failed save of the food gets a message.
  ///
  /// Returns the choice to store, `null` when the cook backed out or the food
  /// could not be saved. A found food is in the Vorrat already then, and
  /// leaves it again when the choice fails to store. When the page is gone
  /// before it can store the choice, this flow stores it, with the recipe's
  /// amount as if the question was closed, and returns `null`.
  static Future<KochmodusLineChoice?> find(
    BuildContext context, {
    required KochmodusTarget target,
    required KochmodusLineView line,
    required ValueChanged<KochmodusNewFood>? onFood,
    required bool keep,
  }) async {
    final failed = AppLocalizations.of(context)!.kochmodusFoodAddFailed;
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    final provider = kochmodusControllerProvider(target);
    // The page's controller stays until the pick is stored, also when the
    // page goes while "Wie viel nimmst du?" is open.
    final alive = container.listen(provider, (_, _) {});
    try {
      final lineId = line.id;
      final pick = cookPickNeed(line.need, line.line.conversion);
      final view = container.read(provider).value;
      // The line's other foods that stay after [ids] ("Zweite Packung").
      List<String> others(List<String> ids) => [
        if (keep)
          for (final take in line.takes)
            if (!ids.contains(take.itemId)) take.itemId,
      ];
      KochmodusLineChoice Function(KochmodusTakeAmount? own)? found;
      // Asked only when the line takes this one food alone.
      var taken = const <InventoryItem>[];
      final filled = await PreparedMealPendingFoodFlow.fill(
        context: context,
        source: PreparedMealFoodSource.search,
        query: cookLineFoodName(line.line.text),
        ingredient: line.text,
        pieceWeight: pick.pieceWeight,
        need: pick.need,
        heldItemIds: view == null
            ? const {}
            : kochmodusHeldItemIds(view, lineId),
        onFill: (item, _) async {
          if (!context.mounted) return false;
          found = (own) => KochmodusTakeFlow.told(
            (controller) async {
              final stored = await controller.assignFound(
                lineId,
                item,
                own: own,
                alone: !keep,
              );
              if (!stored) {
                await PreparedMealPendingFoodFlow.remove(container, item.id);
              }
              return stored;
            },
            onFood,
            (lineId: lineId, item: item, fromStock: false),
          );
          taken = others([item.id]).isEmpty ? [item] : const [];
          return true;
        },
        onTake: (items) async {
          if (!context.mounted) return false;
          final ids = [for (final item in items) item.id];
          // Like a found food, the taken ones come first.
          found = (own) => KochmodusTakeFlow.told(
            (controller) => controller.assignItems(lineId, [
              ...ids,
              ...others(ids),
            ], own: own),
            onFood,
            (lineId: lineId, item: items.first, fromStock: true),
          );
          taken = others(ids).isEmpty ? items : const [];
          return true;
        },
      );
      if (filled == false && context.mounted) {
        messenger.showAppSnackBar(failed, tone: AppSnackBarTone.error);
      }
      final choice = found;
      if (choice == null) return null;
      // The cooking after the search holds a new pack and its stock.
      final now = container.read(provider).value;
      final lineNow = now?.lines.firstWhereOrNull((each) => each.id == lineId);
      final asked = now == null || lineNow == null || !context.mounted
          ? choice(null)
          : await KochmodusTakeFlow.taken(
              context,
              view: now,
              line: lineNow,
              items: taken,
              choice: choice,
            );
      if (context.mounted) return asked;
      await asked(container.read(provider.notifier));
      return null;
    } finally {
      alive.close();
    }
  }
}
