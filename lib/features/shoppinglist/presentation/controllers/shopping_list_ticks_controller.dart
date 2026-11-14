import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

part 'shopping_list_ticks_controller.g.dart';

/// Taps on tiles the list does not show yet: entries ticked a moment ago,
/// which stay among the tiles for a while, and the done state of taps whose
/// save has not finished, by entry id.
typedef ShoppingListTicks = ({
  Set<String> justTicked,
  Map<String, bool> pendingDone,
});

/// Holds [ShoppingListTicks] while the list page shows. Saves run one after
/// another, so the stored list can lag behind the finger.
@riverpod
class ShoppingListTicksController extends _$ShoppingListTicksController {
  final _lingers = <String, Timer>{};
  final _latestChange = <String, int>{};
  var _changes = 0;

  @override
  ShoppingListTicks build() {
    ref.onDispose(() {
      for (final timer in _lingers.values) {
        timer.cancel();
      }
      _lingers.clear();
    });
    return (justTicked: const {}, pendingDone: const {});
  }

  /// Ticks [item] off or puts it back, as the user sees it, and saves the
  /// new state with [save]. The tap shows at once; once saved or failed,
  /// the list state counts again, unless a later tap on the same entry is
  /// still on its way.
  Future<void> toggle(
    ShoppingListItem item, {
    required Future<bool> Function({required bool done}) save,
  }) async {
    final id = item.id;
    final done = !item.isDone;
    final change = ++_changes;
    _latestChange[id] = change;
    _lingers.remove(id)?.cancel();
    if (done) {
      _lingers[id] = Timer(AppShopping.tickLinger, () {
        _lingers.remove(id);
        if (ref.mounted) _update(justTicked: (ids) => ids.remove(id));
      });
    }
    _update(
      justTicked: (ids) => done ? ids.add(id) : ids.remove(id),
      pendingDone: (states) => states[id] = done,
    );
    await save(done: done);
    if (!ref.mounted || _latestChange[id] != change) return;
    _latestChange.remove(id);
    _update(pendingDone: (states) => states.remove(id));
  }

  void _update({
    void Function(Set<String> ids)? justTicked,
    void Function(Map<String, bool> states)? pendingDone,
  }) {
    final ids = {...state.justTicked};
    final states = {...state.pendingDone};
    justTicked?.call(ids);
    pendingDone?.call(states);
    state = (justTicked: ids, pendingDone: states);
  }
}
