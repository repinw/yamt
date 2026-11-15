import 'dart:async';

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/log_failure.dart';
import 'package:yamt/core/utils/serialized_mutation_queue.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kitchen_utensils/application/kitchen_utensil_list_provider.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kochmodus/application/cook_recipe_source.dart';
import 'package:yamt/features/kochmodus/application/cook_refill.dart';
import 'package:yamt/features/kochmodus/application/cook_run_discard_service.dart';
import 'package:yamt/features/kochmodus/application/cook_run_finish_service.dart';
import 'package:yamt/features/kochmodus/application/cook_run_shopping_service.dart';
import 'package:yamt/features/kochmodus/application/cook_run_start_service.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_run_edits.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_said_controller.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_view_builder.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/recipes/application/cook_run_providers.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';
import 'package:yamt/features/recipes/domain/recipes_exceptions.dart';

part 'kochmodus_controller.g.dart';

const _logName = 'KochmodusController';

/// Assigning or cooking a [KochmodusTarget]: the household's run, or a draft
/// until its first change; `null` when the recipe or run never existed.
/// Edits are `KochmodusActions`, timers `KochmodusTimerController`.
@riverpod
class KochmodusController extends _$KochmodusController {
  // Until the first change, or free cooking's pots; then the run is stored.
  CookRun? _draft;
  // The stored run as last seen, also once it is gone.
  CookRun? _stored;
  bool _ended = false;
  int _rejected = 0;
  bool _leaving = false;
  bool _busy = false;
  bool _reopened = false;
  CookFinishSummary? _finished;
  final _draftEdits = SerializedMutationQueue();
  Future<CookFinishSummary?>? _finishing;
  KochmodusStep? _tab;
  List<CookRun> _runs = const [];
  List<InventoryItem> _items = const [];
  List<KitchenUtensil> _utensils = const [];
  late TemplateIngredientParser _parser;
  late CookRunStartService _start;

  @override
  FutureOr<KochmodusView?> build(KochmodusTarget target) {
    final runsValue = ref.watch(cookRunsProvider);
    final itemsValue = ref.watch(inventoryQuickEatItemsProvider);
    final utensilsValue = ref.watch(kitchenUtensilListProvider);
    final templateValue = switch (target) {
      KochmodusRecipeTarget(:final recipeId) => ref.watch(
        cookRecipeTemplateProvider(recipeId),
      ),
      KochmodusRunTarget() || KochmodusFreeTarget() => const AsyncData(null),
    };
    _parser = ref.watch(templateIngredientParserProvider);
    final runRepository = ref.watch(cookRunRepositoryProvider);
    ref.onDispose(runRepository.rejected.listen(_keepRejectedAsDraft).cancel);
    _start = ref.watch(cookRunStartServiceProvider);
    // What was said for "nein" lasts as long as this page's controller.
    ref.listen(kochmodusSaidControllerProvider(target), (_, _) {});
    // requireValue waits for every source, so a write never shows loading.
    final runs = runsValue.requireValue;
    _items = itemsValue.requireValue;
    _utensils = utensilsValue.requireValue;
    final template = templateValue.requireValue;
    final id = target.cookRunId;
    // Gone while the stream lacks a run it had; a new run may come later.
    final wasThere = _runs.any((run) => run.id == id);
    _runs = runs;
    final stored = runs.firstWhereOrNull((run) => run.id == id);
    // The first build binds the page: to the stored run, else a draft.
    if (!state.hasValue && stored == null && _draft == null) {
      _draft = kochmodusDraft(target, template, _start);
    }
    if (stored != null) {
      _stored = stored;
      _draft = null;
      _ended = false;
    } else if (wasThere && !_leaving && _stored != null) {
      _ended = true;
    }
    return _compose();
  }

  /// Applies [edit] to the run, then opens the tab after the shown one when
  /// [next], once it is stored and unless the cook opened another meanwhile.
  /// A recipe's draft is stored on its first change, free cooking's on
  /// choosing its pots; a stored run changes on its freshest stored state.
  /// The edits of a draft wait for the one before, which may be storing it.
  Future<bool> change(
    CookRun Function(CookRun run) edit, {
    bool next = false,
  }) async {
    final shown = _tab;
    final tab = next ? state.value?.nextStep ?? _tab : _tab;
    Future<bool> apply() => _apply(edit, shown, tab);
    // The guard keeps the controller alive while the edit waits.
    return _draft == null
        ? await apply()
        : await _guard('wait to edit', () => _draftEdits.enqueue(apply)) ??
              false;
  }

  Future<bool> _apply(
    CookRun Function(CookRun run) edit,
    KochmodusStep? shown,
    KochmodusStep? tab,
  ) async {
    final draft = _draft;
    if (draft == null) {
      final id = _stored?.id;
      if (id == null) return false;
      return await _write('change', () async {
        await ref.read(cookRunRepositoryProvider).mutate(id, edit);
        if (_tab == shown) _tab = tab;
      });
    }
    final edited = await _guard('edit the draft of', () async => edit(draft));
    if (edited == null || !ref.mounted) return false;
    if (edited.pots == null && edited.kind == CookRunKind.free) {
      _draft = edited;
      _tab = tab;
      _emit();
      return true;
    }
    return await _write('create', busy: true, () async {
      await ref.read(cookRunRepositoryProvider).create(edited);
      _stored = edited;
      _draft = null;
      _tab = tab;
    });
  }

  /// [run] with [lineId] taking from [itemIds] (`refillKochmodusTakes`).
  CookRun refillTakes(
    CookRun run,
    String lineId,
    List<String> itemIds, {
    InventoryItem? found,
  }) => refillKochmodusTakes(
    run,
    lineId,
    itemIds,
    items: _items,
    otherReservations: _others(run.id),
    parser: _parser,
    found: found,
  );

  /// Shows the tab [step]. Moving on past the run's step stores it, so
  /// "Läuft" says where the cook is; a paused run stays paused.
  Future<bool> goTo(KochmodusStep step) async {
    _tab = step;
    _emit();
    final to = kochmodusStepToStore(_stored, step);
    return to == null || await change((run) => run.toStep(to));
  }

  /// "Zuweisen" calls it once on opening (`cookRunOpened`): cut takes fill
  /// up, and a paused run's shopping lines open again, with a hint.
  Future<bool> open() async {
    final paused = await _guard(
      'open',
      () async => (await future)?.paused ?? false,
    );
    if (paused == null || !ref.mounted) return paused != null;
    if (_stored == null) return true;
    final done = await change((run) => cookRunOpened(run, refillTakes));
    if (done && paused && ref.mounted) {
      _reopened = true;
      _emit();
    }
    return done;
  }

  /// "Erst einkaufen": puts the shopping lines on the list and pauses the run.
  Future<bool> pauseForShopping() async {
    final shopping = ref.read(cookRunShoppingServiceProvider);
    final id = _stored?.id;
    return id != null &&
        await _write('pause', busy: true, () => shopping.pause(id));
  }

  /// Puts the meals into the Vorrat ("In Vorrat") once, then the page shows
  /// "Fertig"; later calls share that result. `null` when it failed.
  Future<CookFinishSummary?> finish() => _finishing ??= _end(
    'finish',
    (id) async =>
        _finished = await ref.read(cookRunFinishServiceProvider).finish(id),
  ).then((result) => result ?? (_finishing = null));

  /// Discards the run ("Verwerfen") and returns it as it was, for
  /// [restore]; `null` when it failed.
  Future<CookRun?> discard() => _end(
    'discard',
    (id) => ref.read(cookRunDiscardServiceProvider).discard(id),
  );

  /// Brings the discarded [run] back ("Rückgängig").
  Future<bool> restore(CookRun run) => _write(
    'restore',
    () => ref.read(cookRunDiscardServiceProvider).restore(run),
  );

  // Ends the stored run; the page keeps it meanwhile instead of "ended".
  Future<T?> _end<T extends Object>(
    String action,
    Future<T> Function(String id) body,
  ) async {
    final id = _stored?.id;
    if (id == null) return null;
    _leaving = true;
    final result = await _guard(action, busy: true, () => body(id));
    _leaving = result != null;
    return result;
  }

  Future<bool> _write(
    String action,
    Future<void> Function() body, {
    bool busy = false,
  }) async =>
      await _guard(action, busy: busy, () => body().then((_) => true)) ?? false;

  // Runs [body] alive after the page closes; `null` when it failed.
  Future<T?> _guard<T extends Object>(
    String action,
    Future<T> Function() body, {
    bool busy = false,
  }) async {
    final link = ref.keepAlive();
    if (busy) {
      _busy = true;
      _emit();
    }
    try {
      return await body();
    } on Object catch (error, stackTrace) {
      logFailure('Failed to $action.', _logName, error, stackTrace);
      _ended = _ended || error is CookRunGoneException;
      return null;
    } finally {
      if (busy) _busy = false;
      _emit();
      link.close();
    }
  }

  void _keepRejectedAsDraft(String id) {
    if (id != target.cookRunId || _finishing != null) return;
    _rejected++;
    _draft = _stored ?? _draft;
    _stored = null;
    _ended = false;
    _emit();
  }

  void _emit() {
    // Before the first build there is nothing to show yet.
    if (!ref.mounted || !state.hasValue) return;
    state = AsyncData(_compose());
  }

  KochmodusView? _compose() {
    final run = _stored ?? _draft;
    if (run == null) return null;
    return buildKochmodusView(
      run: run,
      saved: _stored != null,
      ended: _ended,
      rejected: _rejected,
      busy: _busy,
      reopened: _reopened,
      finished: _finished,
      tab: _tab,
      items: _items,
      otherReservations: _others(run.id),
      holders: kochmodusItemHolders(_runs, run.id),
      utensils: _utensils,
      parser: _parser,
    );
  }

  Map<String, int> _others(String runId) =>
      reservationsOf(_runs.where((run) => run.id != runId));
}
