import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';

void main() {
  late UserDataCipher signedIn;

  setUpAll(() async {
    signedIn = (
      uid: 'user-1',
      cipher: PayloadCipher(await PayloadCipher.newDataKey()),
    );
  });

  test('readState returns fresh state when profile has no entry', () async {
    final repository = FirestoreBurnWeekRunStateRepository(
      firestore: FakeFirebaseFirestore(),
      dataCipher: signedIn,
    );

    final state = await repository.readState();

    expect(state.runWeekNumber, 1);
    expect(state.starCount, 0);
    expect(state.lastActiveDayKey, isNull);
  });

  test('saveState stores an encrypted entry on the user profile', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreBurnWeekRunStateRepository(
      firestore: firestore,
      dataCipher: signedIn,
    );
    const savedState = BurnWeekRunState(
      currentWeekStartDayKey: '2026-04-21',
      runWeekNumber: 3,
      starCount: 2,
      starBrokeThisWeek: true,
      missedTrackingThisWeek: false,
    );

    final saved = await repository.saveState(savedState);
    final restored = await repository.readState();
    final profileData = (await firestore.doc('users/user-1').get()).data()!;

    expect(saved, isTrue);
    expect(profileData['uid'], 'user-1');
    expect(profileData['burn_week_run_state'], isA<String>());
    expect(profileData['burn_week_run_state'], isNot(contains('2026-04-21')));
    expect(restored.currentWeekStartDayKey, '2026-04-21');
    expect(restored.lastActiveDayKey, isNull);
    expect(restored.runWeekNumber, 3);
    expect(restored.starCount, 2);
    expect(restored.starBrokeThisWeek, isTrue);
  });

  test('readState falls back to fresh state on malformed entry', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc('user-1').set(<String, dynamic>{
      'burn_week_run_state': 'bad state',
    });
    final repository = FirestoreBurnWeekRunStateRepository(
      firestore: firestore,
      dataCipher: signedIn,
    );

    final state = await repository.readState();

    expect(state.runWeekNumber, 1);
    expect(state.starCount, 0);
  });

  test('missing data key reads fresh state and refuses save', () async {
    final repository = FirestoreBurnWeekRunStateRepository(
      firestore: FakeFirebaseFirestore(),
      dataCipher: null,
    );

    final state = await repository.readState();
    final saved = await repository.saveState(const BurnWeekRunState.initial());

    expect(state.runWeekNumber, burnWeekLearningRunWeekNumber);
    expect(saved, isFalse);
  });
}
