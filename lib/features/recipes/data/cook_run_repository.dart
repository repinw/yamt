import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/firestore_json_normalizer.dart';
import 'package:yamt/core/data/firestore_offline_writes.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/core/data/sealed_document.dart';
import 'package:yamt/core/utils/log_failure.dart';
import 'package:yamt/features/household/application/household_data_scope.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/recipes_exceptions.dart';

part 'cook_run_repository.g.dart';

const _logName = 'CookRunRepository';

/// A write of this repository, which the local cache may not show yet.
typedef _OwnWrite = ({
  /// The stored documents it replaces. A read that returns one of them ran
  /// before the write was applied; the seal's random nonce makes them unique.
  List<Map<String, dynamic>> replaced,

  /// The stored document it wrote.
  Map<String, dynamic> sealed,

  /// The run it wrote.
  CookRun run,

  /// The document [CookRunRepository.create] wrote while it may not have
  /// landed yet: until its commit completes or a read shows a document of
  /// the run, a read of none ran before it. `null` after that.
  Map<String, dynamic>? created,
});

/// The cook run repository of the active household.
@riverpod
CookRunRepository cookRunRepository(Ref ref) {
  return CookRunRepository(scope: ref.watch(householdDataScopeProvider));
}

/// Stores the cook runs of a household, one encrypted document per run
/// without plaintext fields.
///
/// A run is written whole once by [create]. After that every write is a
/// [mutate]: a change applied to the freshest local copy, one after another,
/// written with `update`, so a run that another device ended never comes
/// back. When two devices change the same line at once, the later wins.
///
/// A commit is only posted, so a read right after it can overtake it. A
/// [mutate] or [load] whose read still returns a document this instance
/// already replaced goes on from the run it wrote; any other document wins,
/// because the write landed or another device wrote. So does a read of no
/// document right after [create], until the create's commit completes or a
/// read shows the run: only after that does no document mean the run is gone.
/// A change that changes nothing writes nothing.
///
/// The write order, [pending] and the own writes hold per instance, so they
/// end with the household's scope. The provider is auto-dispose, so a caller
/// keeps it alive (`ref.keepAlive()`, closed in `finally`) until its writes
/// are staged.
///
/// The scope is `null` while signed out or while the household key is not
/// ready. Reads then return no runs and writes throw a [StateError].
class CookRunRepository {
  /// Creates the repository for [scope].
  new({required HouseholdDataScope? scope})
    : _collection = scope == null
          ? null
          : SealedCollection(
              scope.firestore
                  .collection('households')
                  .doc(scope.householdId)
                  .collection('cook_runs'),
              cipher: scope.cipher,
            );

  final SealedCollection? _collection;
  Future<void> _writeBarrier = Future<void>.value();
  final _ownWrites = <String, _OwnWrite>{};
  final _rejected = StreamController<String>.broadcast(sync: true);

  /// The ids of runs whose create or change the server rejected; the local
  /// cache then rolls the write back.
  Stream<String> get rejected => _rejected.stream;

  /// Completes when every write started so far is staged.
  Future<void> get pending => _writeBarrier;

  /// Watches every run of the household. A run that does not open or parse
  /// is logged and left out; a watch that Firestore rules deny emits no
  /// runs and ends.
  Stream<List<CookRun>> watchAll() async* {
    final collection = _collection;
    if (collection == null) {
      yield const <CookRun>[];
      return;
    }
    try {
      await for (final snapshot in collection.reference.snapshots()) {
        final runs = await Future.wait(
          snapshot.docs.map((document) => _openOrSkip(collection, document)),
        );
        yield List.unmodifiable(runs.nonNulls);
      }
    } on FirebaseException catch (error, stackTrace) {
      if (error.code != 'permission-denied') rethrow;
      _log('Cook run watch denied by Firestore rules.', error, stackTrace);
      yield const <CookRun>[];
    }
  }

  /// Loads the run [id], from the local cache first so it works offline;
  /// `null` when it does not exist. Throws when it does not open or parse.
  Future<CookRun?> load(String id) async {
    final collection = _collection;
    if (collection == null) {
      return null;
    }
    return await _runOf(
      collection,
      await readDocumentLocalFirst(collection.reference.doc(id)),
    );
  }

  /// Writes the new [run]. Firestore queues the write offline, so this does
  /// not wait for the server; a later rejection is logged and reported on
  /// [rejected]. It replaces a
  /// run with the same id, so a caller opens an existing run instead (a
  /// recipe has one run per household).
  Future<void> create(CookRun run) => _queue((collection) async {
    final sealed = await collection.seal(run.id, run.toJson());
    _ownWrites[run.id] = (
      replaced: const [],
      sealed: sealed,
      run: run,
      created: sealed,
    );
    final batch = collection.reference.firestore.batch()
      ..set(collection.reference.doc(run.id), sealed);
    unawaited(
      batch.commit().then<void>(
        (_) => _landed(run.id, sealed),
        onError: (Object error, StackTrace stackTrace) {
          _log('Server rejected cook run ${run.id}.', error, stackTrace);
          _reject(run.id);
        },
      ),
    );
  });

  /// Applies [change] to the freshest local copy of the run [id] and writes
  /// the result, after every earlier write of this repository. Returns the
  /// changed run. Throws a [CookRunGoneException] when the run is gone;
  /// then nothing is written. A later rejection is reported on [rejected].
  Future<CookRun> mutate(String id, CookRun Function(CookRun run) change) =>
      _queue((collection) async {
        final reference = collection.reference.doc(id);
        final snapshot = await readDocumentLocalFirst(reference);
        final stored = snapshot.data();
        final ownWrite = _notAppliedYet(id, stored);
        final run = await _runOf(collection, snapshot);
        if (run == null) {
          throw CookRunGoneException(id);
        }
        final changed = change(run);
        if (changed.id != id) {
          throw ArgumentError.value(changed.id, 'change', 'changed the id');
        }
        if (changed == run) return run;
        final sealed = await collection.seal(id, changed.toJson());
        _ownWrites[id] = (
          replaced: ownWrite == null
              ? [?stored]
              : [...ownWrite.replaced, ownWrite.sealed],
          sealed: sealed,
          run: changed,
          created: _ownWrites[id]?.created,
        );
        final batch = collection.reference.firestore.batch()
          ..update(reference, sealed);
        _commit(batch, id);
        return changed;
      });

  /// Adds the deletion of the run [id] to [batch], which the caller commits
  /// with other writes. Waits for the earlier writes first, so none of them
  /// lands after it. Throws a [StateError] while signed out.
  Future<void> stageDelete(WriteBatch batch, String id) async {
    final collection = _require();
    await _writeBarrier;
    _ownWrites.remove(id);
    batch.delete(collection.reference.doc(id));
  }

  // The run that [snapshot] stands for: the write it does not show yet, else
  // what it holds; `null` when it holds nothing.
  Future<CookRun?> _runOf(
    SealedCollection collection,
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final ownWrite = _notAppliedYet(snapshot.id, snapshot.data());
    if (ownWrite != null) {
      return ownWrite.run;
    }
    final data = await collection.open(snapshot);
    return data == null ? null : _decode(data);
  }

  // The last write of the run [id] when the read that returned [stored] ran
  // before that write was applied. A read of no document did so only while
  // the run's create may not have landed; a read of one shows it landed.
  _OwnWrite? _notAppliedYet(String id, Map<String, dynamic>? stored) {
    final ownWrite = _ownWrites[id];
    if (ownWrite == null) {
      return null;
    }
    if (stored == null) {
      return ownWrite.created == null ? null : ownWrite;
    }
    if (ownWrite.created case final created?) {
      _landed(id, created);
    }
    const equality = DeepCollectionEquality();
    return ownWrite.replaced.any((old) => equality.equals(old, stored))
        ? ownWrite
        : null;
  }

  // The create that wrote [created] of the run [id] has landed: from now on
  // a read of no document means the run is gone.
  void _landed(String id, Map<String, dynamic> created) {
    final ownWrite = _ownWrites[id];
    if (ownWrite != null && identical(ownWrite.created, created)) {
      _ownWrites[id] = (
        replaced: ownWrite.replaced,
        sealed: ownWrite.sealed,
        run: ownWrite.run,
        created: null,
      );
    }
  }

  Future<T> _queue<T>(Future<T> Function(SealedCollection) write) {
    final collection = _require();
    final result = _writeBarrier.then((_) => write(collection));
    _writeBarrier = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  void _commit(WriteBatch batch, String id) {
    commitBatchInBackground(
      batch,
      failureMessage: 'Server rejected cook run $id.',
      logName: _logName,
      onFailure: (_) => _reject(id),
    );
  }

  // The server rejected a write of the run [id]: what this instance wrote
  // of it no longer stands.
  void _reject(String id) {
    _ownWrites.remove(id);
    _rejected.add(id);
  }

  SealedCollection _require() {
    final collection = _collection;
    if (collection == null) {
      throw StateError('Cook runs are not available while signed out.');
    }
    return collection;
  }

  Future<CookRun?> _openOrSkip(
    SealedCollection collection,
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    try {
      final data = await openDocument(
        document.data(),
        path: document.reference.path,
        cipher: collection.cipher,
      );
      return _decode(data);
    } on Object catch (error, stackTrace) {
      _log('Skipping unreadable cook run ${document.id}.', error, stackTrace);
      return null;
    }
  }

  CookRun _decode(Map<String, dynamic> data) =>
      CookRun.fromJson(normalizeFirestoreJson(data));

  void _log(String message, Object error, StackTrace stackTrace) {
    logFailure(message, _logName, error, stackTrace);
  }
}
