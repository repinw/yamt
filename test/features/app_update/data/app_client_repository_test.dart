import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/app_update/data/app_client_repository.dart';

import '../../../helpers/memory_app_preferences.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MemoryAppPreferences preferences;
  late AppClientRepository repository;
  final start = DateTime.utc(2026, 10, 7, 8);

  setUp(() {
    firestore = FakeFirebaseFirestore();
    preferences = MemoryAppPreferences();
    repository = AppClientRepository(firestore, preferences);
  });

  Future<List<Map<String, dynamic>>> clients() async {
    final snapshot = await firestore.collection('users/u1/clients').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  test('saves version, platform and start under one install id', () async {
    await repository.saveClientVersion(
      uid: 'u1',
      appVersion: '3.6.0+38',
      now: start,
    );

    final saved = await clients();
    expect(saved, hasLength(1));
    expect(saved.single['app_version'], '3.6.0+38');
    expect(saved.single['platform'], isA<String>());
    expect((saved.single['last_seen_at'] as Timestamp).toDate().toUtc(), start);
  });

  test('skips the write within a day for the same version', () async {
    await repository.saveClientVersion(
      uid: 'u1',
      appVersion: '3.6.0',
      now: start,
    );
    await repository.saveClientVersion(
      uid: 'u1',
      appVersion: '3.6.0',
      now: start.add(const Duration(hours: 23)),
    );

    expect(
      (((await clients()).single['last_seen_at']) as Timestamp)
          .toDate()
          .toUtc(),
      start,
    );
  });

  test('writes again for a new version or after a day', () async {
    await repository.saveClientVersion(
      uid: 'u1',
      appVersion: '3.6.0',
      now: start,
    );
    await repository.saveClientVersion(
      uid: 'u1',
      appVersion: '3.7.0',
      now: start.add(const Duration(hours: 1)),
    );
    expect((await clients()).single['app_version'], '3.7.0');

    final nextDay = start.add(const Duration(days: 1, hours: 1));
    await repository.saveClientVersion(
      uid: 'u1',
      appVersion: '3.7.0',
      now: nextDay,
    );
    final saved = (await clients()).single;
    expect((saved['last_seen_at'] as Timestamp).toDate().toUtc(), nextDay);
  });

  test('keeps one document per device across users', () async {
    await repository.saveClientVersion(
      uid: 'u1',
      appVersion: '3.6.0',
      now: start,
    );
    await repository.saveClientVersion(
      uid: 'u2',
      appVersion: '3.6.0',
      now: start,
    );

    final u1 = await firestore.collection('users/u1/clients').get();
    final u2 = await firestore.collection('users/u2/clients').get();
    expect(u1.docs.single.id, u2.docs.single.id);
  });
}
