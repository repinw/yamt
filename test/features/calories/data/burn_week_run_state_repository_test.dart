import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';

void main() {
  test(
    'readState returns fresh one-heart state when profile has no entry',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repository = FirestoreBurnWeekRunStateRepository(
        firestore: firestore,
        currentUserId: 'user-1',
      );

      final state = await repository.readState();

      expect(state.runWeekNumber, 1);
      expect(state.starCount, 0);
      expect(state.heartCount, 1);
      expect(state.heartDayKeys, isEmpty);
      expect(state.lastActiveDayKey, isNull);
    },
  );

  test('saveState persists nested user profile entry', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreBurnWeekRunStateRepository(
      firestore: firestore,
      currentUserId: 'user-1',
    );
    const savedState = BurnWeekRunState(
      currentWeekStartDayKey: '2026-04-21',
      runWeekNumber: 3,
      starCount: 2,
      heartCount: 2,
      heartCreditKcal: 700,
      starBrokeThisWeek: true,
      missedTrackingThisWeek: false,
      heartDayKeys: <String>['2026-4-22'],
    );

    final saved = await repository.saveState(savedState);
    final restored = await repository.readState();
    final profileSnapshot = await firestore
        .collection('users')
        .doc('user-1')
        .get();
    final profileData = profileSnapshot.data()!;

    expect(saved, isTrue);
    expect(profileData['burn_week_run_state'], isA<Map<String, dynamic>>());
    expect(
      (profileData['burn_week_run_state']
          as Map<String, dynamic>)['schema_version'],
      burnWeekRunStateSchemaVersion,
    );
    expect(restored.currentWeekStartDayKey, '2026-04-21');
    expect(restored.lastActiveDayKey, isNull);
    expect(restored.runWeekNumber, 3);
    expect(restored.starCount, 2);
    expect(restored.heartCount, 2);
    expect(restored.heartCreditKcal, 700);
    expect(restored.starBrokeThisWeek, isTrue);
    expect(restored.heartDayKeys, <String>['2026-4-22']);
  });

  test('readState ignores old unversioned profile entry', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc('user-1').set(<String, dynamic>{
      'burn_week_run_state': <String, dynamic>{
        'run_week_number': 7,
        'star_count': 4,
        'heart_count': 3,
        'heart_day_keys': <String>['2026-4-22'],
      },
    });
    final repository = FirestoreBurnWeekRunStateRepository(
      firestore: firestore,
      currentUserId: 'user-1',
    );

    final state = await repository.readState();

    expect(state.runWeekNumber, burnWeekLearningRunWeekNumber);
    expect(state.starCount, 0);
    expect(state.heartCount, burnWeekInitialHeartCount);
    expect(state.heartDayKeys, isEmpty);
  });

  test('readState falls back to fresh state on malformed entry', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc('user-1').set(<String, dynamic>{
      'burn_week_run_state': 'bad state',
    });
    final repository = FirestoreBurnWeekRunStateRepository(
      firestore: firestore,
      currentUserId: 'user-1',
    );

    final state = await repository.readState();

    expect(state.runWeekNumber, 1);
    expect(state.starCount, 0);
    expect(state.heartCount, 1);
  });

  test('missing user reads fresh state and refuses save', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreBurnWeekRunStateRepository(
      firestore: firestore,
      currentUserId: null,
    );

    final state = await repository.readState();
    final saved = await repository.saveState(const BurnWeekRunState.initial());

    expect(state.heartCount, 1);
    expect(saved, isFalse);
  });
}
