import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/recipes_exceptions.dart';

/// Keeps the household's cook runs in memory and sends every change to each
/// [watchAll] stream asynchronously, like Firestore does.
class FakeCookRunRepository implements CookRunRepository {
  /// Starts with [runs].
  new({List<CookRun> runs = const <CookRun>[]})
    : runs = List<CookRun>.unmodifiable(runs);

  /// The stored runs.
  List<CookRun> runs;

  final _watchers = <StreamController<List<CookRun>>>{};

  @override
  Future<void> get pending => Future<void>.value();

  @override
  Stream<String> get rejected => const Stream.empty();

  @override
  Stream<List<CookRun>> watchAll() {
    late final StreamController<List<CookRun>> watcher;
    watcher = StreamController<List<CookRun>>(
      onListen: () {
        _watchers.add(watcher);
        watcher.add(runs);
      },
      onCancel: () => _watchers.remove(watcher),
    );
    return watcher.stream;
  }

  @override
  Future<CookRun?> load(String id) async {
    for (final run in runs) {
      if (run.id == id) {
        return run;
      }
    }
    return null;
  }

  @override
  Future<void> create(CookRun run) async => _write([
    for (final stored in runs)
      if (stored.id != run.id) stored,
    run,
  ]);

  @override
  Future<CookRun> mutate(
    String id,
    CookRun Function(CookRun run) change,
  ) async {
    final run = await load(id);
    if (run == null) {
      throw CookRunGoneException(id);
    }
    final changed = change(run);
    _write([
      for (final stored in runs)
        if (stored.id == id) changed else stored,
    ]);
    return changed;
  }

  @override
  Future<void> stageDelete(WriteBatch batch, String id) =>
      throw UnimplementedError('The fake has no write batches.');

  void _write(List<CookRun> next) {
    runs = List<CookRun>.unmodifiable(next);
    for (final watcher in _watchers) {
      watcher.add(runs);
    }
  }
}
