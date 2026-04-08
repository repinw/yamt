import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
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
    yield const <PreparedMealDocument>[];
  }
}

void main() {
  test('watchAll rethrows firestore permission denied errors', () async {
    final store = _FakePreparedMealStore()
      ..watchAllError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
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
}
