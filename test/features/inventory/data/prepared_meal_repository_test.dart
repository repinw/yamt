import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/inventory/data/firestore_prepared_meal_repository.dart';
import 'package:yamt/features/inventory/data/inventory_user_session.dart';
import 'package:yamt/features/inventory/data/prepared_meal_store.dart';

class _FakeInventoryUserSession implements InventoryUserSession {
  const _FakeInventoryUserSession({this.currentUserId});

  @override
  final String? currentUserId;
}

class _FakePreparedMealStore implements PreparedMealStore {
  Object? watchAllError;
  final StreamController<List<PreparedMealDocument>> _controller =
      StreamController<List<PreparedMealDocument>>.broadcast();

  @override
  Future<List<PreparedMealDocument>> readAll({required String userId}) async {
    return const <PreparedMealDocument>[];
  }

  @override
  Future<bool> replaceAll({
    required String userId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    return true;
  }

  @override
  Stream<List<PreparedMealDocument>> watchAll({required String userId}) async* {
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
  tearDown(resetSessionShutdownSignal);

  test('watchAll rethrows firestore permission denied errors', () async {
    final store = _FakePreparedMealStore()
      ..watchAllError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    addTearDown(store.dispose);
    final repository = FirestorePreparedMealRepository(
      session: const _FakeInventoryUserSession(currentUserId: 'user-1'),
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
    sessionShutdownSignal.begin();
    final store = _FakePreparedMealStore()
      ..watchAllError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    addTearDown(store.dispose);
    final repository = FirestorePreparedMealRepository(
      session: const _FakeInventoryUserSession(currentUserId: 'user-1'),
      store: store,
    );

    await expectLater(repository.watchAll().first, completion(isEmpty));
  });

  test(
    'watchAll ignores late permission denied after shutdown finished',
    () async {
      final store = _FakePreparedMealStore();
      addTearDown(store.dispose);
      final repository = FirestorePreparedMealRepository(
        session: const _FakeInventoryUserSession(currentUserId: 'user-1'),
        store: store,
      );

      final firstEmission = repository.watchAll().first;
      await Future<void>.delayed(Duration.zero);

      sessionShutdownSignal.begin();
      sessionShutdownSignal.finish();
      store.emitWatchError(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );

      await expectLater(firstEmission, completion(isEmpty));
    },
  );
}
