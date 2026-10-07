import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/inventory/data/firestore_prepared_meal_repository.dart';
import 'package:yamt/features/inventory/data/inventory_user_session.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository_contract.dart';
import 'package:yamt/features/inventory/data/prepared_meal_store.dart';

import '../../../support/prepared_meal_test_data.dart';

class _FakeInventoryUserSession implements InventoryUserSession {
  const new({this.householdId});

  @override
  final String? householdId;
}

class _FakePreparedMealStore implements PreparedMealStore {
  Exception? readAllError;
  Exception? watchAllError;
  final saved = <String, Map<String, dynamic>>{};
  final deleted = <String>[];
  final StreamController<List<PreparedMealDocument>> _controller =
      StreamController<List<PreparedMealDocument>>.broadcast();

  @override
  Future<List<PreparedMealDocument>> readAll({
    required String householdId,
  }) async {
    if (readAllError case final error?) {
      throw error;
    }
    return const <PreparedMealDocument>[];
  }

  @override
  Future<bool> save({
    required String householdId,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    saved[id] = data;
    return true;
  }

  @override
  Future<bool> delete({required String householdId, required String id}) async {
    deleted.add(id);
    return true;
  }

  @override
  Stream<List<PreparedMealDocument>> watchAll({
    required String householdId,
  }) async* {
    final error = watchAllError;
    if (error != null) {
      throw error;
    }
    yield* _controller.stream;
  }

  Future<void> dispose() {
    return _controller.close();
  }

  void emitWatchItems(List<PreparedMealDocument> documents) {
    _controller.add(documents);
  }

  void emitWatchError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }
}

void main() {
  test(
    'readAll rethrows a failed read instead of returning no meals',
    () async {
      final store = _FakePreparedMealStore()
        ..readAllError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        );
      final repository = FirestorePreparedMealRepository(
        session: const _FakeInventoryUserSession(householdId: 'household-1'),
        sessionShutdownSignal: SessionShutdownSignal(),
        store: store,
      );

      await expectLater(
        repository.readAll(),
        throwsA(isA<FirebaseException>()),
      );
    },
  );

  test('save and delete touch only the one meal', () async {
    final store = _FakePreparedMealStore();
    final repository = FirestorePreparedMealRepository(
      session: const _FakeInventoryUserSession(householdId: 'household-1'),
      sessionShutdownSignal: SessionShutdownSignal(),
      store: store,
    );

    await repository.save(preparedMealTestData(id: 'new'));
    await repository.delete('old');

    expect(store.saved.keys, ['new']);
    expect(store.saved['new']!['name'], preparedMealTestData().name);
    expect(store.deleted, ['old']);
  });

  test('saveChanges writes only what changed in the list', () async {
    final store = _FakePreparedMealStore();
    final repository = FirestorePreparedMealRepository(
      session: const _FakeInventoryUserSession(householdId: 'household-1'),
      sessionShutdownSignal: SessionShutdownSignal(),
      store: store,
    );
    final kept = preparedMealTestData(id: 'kept');
    final changed = preparedMealTestData(id: 'changed');

    await repository.saveChanges(
      previous: [
        kept,
        changed,
        preparedMealTestData(id: 'gone'),
      ],
      next: [
        kept,
        changed.copyWith(remainingPortions: 1),
        preparedMealTestData(id: 'added'),
      ],
    );

    expect(store.saved.keys, unorderedEquals(['changed', 'added']));
    expect(store.deleted, ['gone']);
  });

  test('watchAll rethrows firestore permission denied errors', () async {
    final store = _FakePreparedMealStore()
      ..watchAllError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    addTearDown(store.dispose);
    final repository = FirestorePreparedMealRepository(
      session: const _FakeInventoryUserSession(householdId: 'household-1'),
      sessionShutdownSignal: SessionShutdownSignal(),
      store: store,
    );

    await expectLater(
      repository.watchAll().first,
      throwsA(
        isA<FirebaseException>().having(
          (error) => error.code,
          'code',
          'permission-denied',
        ),
      ),
    );
  });

  test('watchAll returns empty list during session shutdown', () async {
    final sessionShutdownSignal = SessionShutdownSignal()..begin();
    final store = _FakePreparedMealStore()
      ..watchAllError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    addTearDown(store.dispose);
    final repository = FirestorePreparedMealRepository(
      session: const _FakeInventoryUserSession(householdId: 'household-1'),
      sessionShutdownSignal: sessionShutdownSignal,
      store: store,
    );

    await expectLater(repository.watchAll().first, completion(isEmpty));
  });

  test(
    'watchAll ignores late permission denied after shutdown finished',
    () async {
      final store = _FakePreparedMealStore();
      addTearDown(store.dispose);
      final sessionShutdownSignal = SessionShutdownSignal();
      final repository = FirestorePreparedMealRepository(
        session: const _FakeInventoryUserSession(householdId: 'household-1'),
        sessionShutdownSignal: sessionShutdownSignal,
        store: store,
      );

      final firstEmission = repository.watchAll().first;
      await Future<void>.delayed(Duration.zero);

      sessionShutdownSignal
        ..begin()
        ..finish();
      store.emitWatchError(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );

      await expectLater(firstEmission, completion(isEmpty));
    },
  );
}
