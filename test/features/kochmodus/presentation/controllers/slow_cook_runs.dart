import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';

/// The household's cook runs, except that a write fails when [fails] or
/// [createFails] says so and waits for [gate] or [createGate] when set; it
/// counts the writes it started. [serverRejects] stands for the server
/// rejecting a write later.
class SlowCookRuns implements CookRunRepository {
  /// Wraps [inner].
  new(this.inner);

  /// The real repository.
  final CookRunRepository inner;

  /// Whether `mutate` fails.
  bool fails = false;

  /// Whether `create` fails.
  bool createFails = false;

  /// `mutate` waits for it, when set.
  Completer<void>? gate;

  /// `create` waits for it, when set.
  Completer<void>? createGate;

  /// How many `create` calls started.
  int creates = 0;

  /// How many `mutate` calls started.
  int mutates = 0;

  /// What [rejected] reports.
  final serverRejects = StreamController<String>.broadcast(sync: true);

  @override
  Future<void> get pending => inner.pending;

  @override
  Stream<String> get rejected => serverRejects.stream;

  @override
  Stream<List<CookRun>> watchAll() => inner.watchAll();

  @override
  Future<CookRun?> load(String id) => inner.load(id);

  @override
  Future<void> create(CookRun run) async {
    creates++;
    // Decided when the call starts, not when the gate opens.
    final fail = createFails;
    await createGate?.future;
    if (fail) throw StateError('create failed');
    await inner.create(run);
  }

  @override
  Future<CookRun> mutate(
    String id,
    CookRun Function(CookRun run) change,
  ) async {
    mutates++;
    await gate?.future;
    if (fails) throw StateError('write failed');
    return await inner.mutate(id, change);
  }

  @override
  Future<void> stageDelete(WriteBatch batch, String id) =>
      inner.stageDelete(batch, id);
}
