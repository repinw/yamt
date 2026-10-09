import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/inventory/data/firestore_prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository_contract.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_store.dart';

import '../../../support/prepared_meal_test_data.dart';

class _FakePreparedMealTemplateStore implements PreparedMealTemplateStore {
  Exception? readAllError;
  Exception? watchAllError;

  @override
  Future<List<PreparedMealTemplateDocument>> readAll({
    required String householdId,
  }) async {
    if (readAllError case final error?) {
      throw error;
    }
    return const <PreparedMealTemplateDocument>[];
  }

  final writes = <String>[];

  @override
  Future<bool> save({
    required String householdId,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    writes.add('save $householdId/$id');
    return true;
  }

  @override
  Future<bool> delete({required String householdId, required String id}) async {
    writes.add('delete $householdId/$id');
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
        household: (householdId: 'household-1', store: store),
        sessionShutdownSignal: SessionShutdownSignal(),
      );

      await expectLater(
        repository.readAll(),
        throwsA(isA<FirebaseException>()),
      );
    },
  );

  test('saveChanges writes only the changed templates', () async {
    final store = _FakePreparedMealTemplateStore();
    final repository = FirestorePreparedMealTemplateRepository(
      household: (householdId: 'household-1', store: store),
      sessionShutdownSignal: SessionShutdownSignal(),
    );
    final kept = preparedMealTestData(id: 'kept');
    final gone = preparedMealTestData(id: 'gone');

    final saved = await repository.saveChanges(
      previous: [kept, gone],
      next: [
        kept,
        preparedMealTestData(id: 'new'),
      ],
    );

    expect(saved, isTrue);
    expect(store.writes, ['save household-1/new', 'delete household-1/gone']);
  });

  test('two writers with stale lists keep both new templates', () async {
    final store = FirestorePreparedMealTemplateStore(
      firestore: FakeFirebaseFirestore(),
      cipher: PayloadCipher(await PayloadCipher.newDataKey()),
    );
    FirestorePreparedMealTemplateRepository device() =>
        FirestorePreparedMealTemplateRepository(
          household: (householdId: 'household-1', store: store),
          sessionShutdownSignal: SessionShutdownSignal(),
        );
    final first = device();
    final second = device();
    final stale = await second.readAll();

    await first.save(preparedMealTestData(id: 'from-first'));
    await second.saveChanges(
      previous: stale,
      next: [
        ...stale,
        preparedMealTestData(id: 'from-second'),
      ],
    );

    final templates = await first.readAll();
    expect(
      templates.map((template) => template.id),
      unorderedEquals(['from-first', 'from-second']),
    );
  });

  test('watchAll rethrows firestore permission denied errors', () async {
    final store = _FakePreparedMealTemplateStore()
      ..watchAllError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    final repository = FirestorePreparedMealTemplateRepository(
      household: (householdId: 'household-1', store: store),
      sessionShutdownSignal: SessionShutdownSignal(),
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
      household: (householdId: 'household-1', store: store),
      sessionShutdownSignal: sessionShutdownSignal,
    );

    await expectLater(repository.watchAll().first, completion(isEmpty));
  });
}
