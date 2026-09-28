import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/inventory/data/firestore_prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/data/inventory_user_session.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_store.dart';

class _FakeInventoryUserSession implements InventoryUserSession {
  const new({this.householdId});

  @override
  final String? householdId;
}

class _FakePreparedMealTemplateStore implements PreparedMealTemplateStore {
  Exception? watchAllError;

  @override
  Future<List<PreparedMealTemplateDocument>> readAll({
    required String householdId,
  }) async {
    return const <PreparedMealTemplateDocument>[];
  }

  @override
  Future<bool> replaceAll({
    required String householdId,
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
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
