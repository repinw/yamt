import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/health/data/'
    'firestore_manual_health_weight_repository.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

void main() {
  test(
    'saveEntry and readEntries persist weights under user collection',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repository = FirestoreManualHealthWeightRepository(
        firestore: firestore,
        currentUserId: 'user-1',
      );

      final saved = await repository.saveEntry(
        ManualHealthWeightEntry(day: DateTime(2026, 3, 20, 18), weightKg: 71.2),
      );
      final entries = await repository.readEntries();
      final snapshot = await firestore
          .collection('users')
          .doc('user-1')
          .collection('health_weights')
          .doc('2026-03-20')
          .get();

      expect(saved, isTrue);
      expect(entries, hasLength(1));
      expect(entries.single.day, DateTime(2026, 3, 20));
      expect(entries.single.weightKg, 71.2);
      expect(snapshot.data()?['day'], '2026-03-20');
      expect(snapshot.data()?['weightKg'], 71.2);
    },
  );

  test('deleteEntryForDay removes persisted day document', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreManualHealthWeightRepository(
      firestore: firestore,
      currentUserId: 'user-1',
    );
    await repository.saveEntry(
      ManualHealthWeightEntry(day: DateTime(2026, 3, 20), weightKg: 71.2),
    );

    final deleted = await repository.deleteEntryForDay(
      DateTime(2026, 3, 20, 9),
    );
    final entries = await repository.readEntries();

    expect(deleted, isTrue);
    expect(entries, isEmpty);
  });

  test('returns safe defaults when firestore or user missing', () async {
    final noFirestoreRepository = FirestoreManualHealthWeightRepository(
      firestore: null,
      currentUserId: 'user-1',
    );
    final noUserRepository = FirestoreManualHealthWeightRepository(
      firestore: FakeFirebaseFirestore(),
      currentUserId: null,
    );
    final entry = ManualHealthWeightEntry(
      day: DateTime(2026, 3, 20),
      weightKg: 71.2,
    );

    expect(await noFirestoreRepository.readEntries(), isEmpty);
    expect(await noFirestoreRepository.saveEntry(entry), isFalse);
    expect(
      await noFirestoreRepository.deleteEntryForDay(DateTime(2026, 3, 20)),
      isFalse,
    );

    expect(await noUserRepository.readEntries(), isEmpty);
    expect(await noUserRepository.saveEntry(entry), isFalse);
    expect(
      await noUserRepository.deleteEntryForDay(DateTime(2026, 3, 20)),
      isFalse,
    );
  });
}
