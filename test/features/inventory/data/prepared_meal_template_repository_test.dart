import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/inventory/data/firestore_prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/data/inventory_user_session.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_store.dart';

import '../../../support/prepared_meal_test_data.dart';

class _FakeInventoryUserSession implements InventoryUserSession {
  const new({this.householdId});

  @override
  final String? householdId;
}

class _FakePreparedMealTemplateStore implements PreparedMealTemplateStore {
  Exception? readAllError;
  Exception? watchAllError;
  void Function(String id, Map<String, dynamic> data)? parse;

  @override
  Future<List<PreparedMealTemplateDocument>> readAll({
    required String householdId,
  }) async {
    if (readAllError case final error?) {
      throw error;
    }
    return const <PreparedMealTemplateDocument>[];
  }

  @override
  Future<bool> replaceAll({
    required String householdId,
    required Map<String, Map<String, dynamic>> documentsById,
    required void Function(String id, Map<String, dynamic> data) parse,
  }) async {
    this.parse = parse;
    return true;
  }

  @override
  Stream<List<PreparedMealTemplateDocument>> watchAll({
    required String householdId,
  }) async* {
    final error = watchAllError;
    if (error != null) {
      throw error;
    }
    yield const <PreparedMealTemplateDocument>[];
  }
}

void main() {
  test(
    'readAll rethrows a failed read instead of returning no templates',
    () async {
      final store = _FakePreparedMealTemplateStore()
        ..readAllError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        );
      final repository = FirestorePreparedMealTemplateRepository(
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

  test('saveAll lets the store keep templates that do not parse', () async {
    final store = _FakePreparedMealTemplateStore();
    final repository = FirestorePreparedMealTemplateRepository(
      session: const _FakeInventoryUserSession(householdId: 'household-1'),
      sessionShutdownSignal: SessionShutdownSignal(),
      store: store,
    );

    await repository.saveAll([preparedMealTestData(id: 'new')]);

    store.parse!('old', preparedMealTestData(id: 'old').toJson());
    expect(
      () => store.parse!('bad', <String, dynamic>{'components': 42}),
      throwsA(isA<TypeError>()),
    );
    // The list skips a stored entry with a non-text id, so the delete check
    // must not accept it either.
    expect(
      () => store.parse!(
        'odd',
        preparedMealTestData(id: 'odd').toJson()..['id'] = 5,
      ),
      throwsA(isA<TypeError>()),
    );
  });

  test('watchAll rethrows firestore permission denied errors', () async {
    final store = _FakePreparedMealTemplateStore()
      ..watchAllError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    final repository = FirestorePreparedMealTemplateRepository(
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
    final store = _FakePreparedMealTemplateStore()
      ..watchAllError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    final repository = FirestorePreparedMealTemplateRepository(
      session: const _FakeInventoryUserSession(householdId: 'household-1'),
      sessionShutdownSignal: sessionShutdownSignal,
      store: store,
    );

    await expectLater(repository.watchAll().first, completion(isEmpty));
  });
}
