import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/application/cook_refill.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_controller.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';

part 'kochmodus_said_controller.g.dart';

/// What the lines said or typed while cooking the [KochmodusTarget] did, the
/// last one last, for "nein". The page's `KochmodusController` listens to it,
/// so it lasts as long as the page and stays while the cook switches tabs or
/// between guide and list. Its actions change the run through that
/// controller, which the caller hands in (it cannot read the controller that
/// listens to it).
@riverpod
class KochmodusSaidController extends _$KochmodusSaidController {
  @override
  List<KochmodusSaid> build(KochmodusTarget target) => const [];

  /// Takes the line [said] into the run of [cooking]
  /// (`KochmodusActions.takeSaid`) with the Vorrat [items] by id and names in
  /// the language [localeCode], and keeps what it did. `null` when it failed.
  Future<KochmodusSaid?> take(
    KochmodusController cooking,
    String said, {
    required Map<String, InventoryItem> items,
    required String localeCode,
  }) async {
    final taken = await cooking.takeSaid(
      said,
      items: items,
      localeCode: localeCode,
    );
    if (taken != null && ref.mounted) state = [...state, taken];
    return taken;
  }

  /// "nein" in the run of [cooking]: takes back the last said line that is
  /// still as saying it left it: the new line goes, the assigned line is
  /// weighed and takes as before.
  /// A said line that changed since, as when the cook chose another food,
  /// weighed or removed it, is dropped and never undone; "nein" goes on to
  /// the one before. With none, nothing happens. Returns whether it worked.
  Future<bool> undoLast(KochmodusController cooking) async {
    final said = state;
    if (said.isEmpty) return true;
    var rest = said;
    final done = await cooking.change((run) {
      rest = said;
      while (rest.isNotEmpty) {
        final last = rest.last;
        rest = rest.sublist(0, rest.length - 1);
        if (run.lineOf(last.lineId) == last.after) {
          return _undone(run, last, cooking.refillTakes);
        }
      }
      return run;
    });
    // Said while "nein" was being stored stays.
    if (done && ref.mounted) state = [...rest, ...state.skip(said.length)];
    return done;
  }
}

// [run] without what [said] did: its new line gone, or its assigned line
// weighed and taking as before ([refill]).
CookRun _undone(CookRun run, KochmodusSaid said, CookRefill refill) =>
    switch (said.before) {
      null => run.removeLine(said.lineId),
      final before => cookRefillLine(
        run
            .weigh(before.id, before.weighed)
            .settle(before.id, before.settlement),
        before.id,
        refill,
      ),
    };
