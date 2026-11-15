import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/recipes/domain/recipes_exceptions.dart';

import '../cook_run_fixtures.dart';

/// A database whose server rejects every batch while [rejects] is on: the
/// commit fails and nothing is written.
class _RejectingFirestore extends FakeFirebaseFirestore {
  bool rejects = false;

  @override
  WriteBatch batch() => rejects ? _RejectedBatch() : super.batch();
}

class _RejectedBatch implements WriteBatch {
  @override
  void delete(DocumentReference<Object?> document) {}

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) {}

  @override
  void update<T>(DocumentReference<T> document, T data) {}

  @override
  Future<void> commit() async => throw FirebaseException(
    plugin: 'cloud_firestore',
    code: 'permission-denied',
  );
}

void main() {
  late PayloadCipher cipher;
  late _RejectingFirestore firestore;

  setUp(() async {
    cipher = PayloadCipher(await PayloadCipher.newDataKey());
    firestore = _RejectingFirestore();
  });

  CookRunRepository repository() => CookRunRepository(
    scope: (householdId: 'h1', firestore: firestore, cipher: cipher),
  );

  Future<void> settle(CookRunRepository repo) async {
    await repo.pending;
    await Future<void>.delayed(Duration.zero);
  }

  test('a create the server rejects is reported, and the run is gone '
      'afterwards', () async {
    final repo = repository();
    final rejected = <String>[];
    repo.rejected.listen(rejected.add);
    final run = buildCookRun();
    firestore.rejects = true;

    await repo.create(run);
    await settle(repo);

    expect(rejected, [run.id]);
    expect(await repo.load(run.id), isNull);
    await expectLater(
      repo.mutate(run.id, (r) => r.copyWith(portions: 6)),
      throwsA(isA<CookRunGoneException>()),
    );
  });

  test('a change the server rejects is reported', () async {
    final repo = repository();
    final rejected = <String>[];
    repo.rejected.listen(rejected.add);
    final run = buildCookRun();
    await repo.create(run);
    await settle(repo);
    firestore.rejects = true;

    await repo.mutate(run.id, (r) => r.copyWith(portions: 6));
    await settle(repo);

    expect(rejected, [run.id]);
    expect(await repo.load(run.id), run);
  });

  test('a write the server takes reports nothing', () async {
    final repo = repository();
    final rejected = <String>[];
    repo.rejected.listen(rejected.add);
    final run = buildCookRun();

    await repo.create(run);
    await repo.mutate(run.id, (r) => r.copyWith(portions: 6));
    await settle(repo);

    expect(rejected, isEmpty);
  });
}
