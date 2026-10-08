import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/onboarding/presentation/controllers/'
    'calorie_goal_load_failed_controller.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

void main() {
  late List<AsyncValue<void>> states;

  ProviderContainer containerWith(FirebaseAuth auth) {
    final container = ProviderContainer(
      overrides: [firebaseAuthProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    states = [];
    container.listen(
      calorieGoalLoadFailedControllerProvider,
      (_, next) => states.add(next),
    );
    return container;
  }

  test('signs out', () async {
    final auth = _MockFirebaseAuth();
    when(auth.signOut).thenAnswer((_) async {});
    final container = containerWith(auth);

    final signedOut = await container
        .read(calorieGoalLoadFailedControllerProvider.notifier)
        .signOut();

    expect(signedOut, isTrue);
    verify(auth.signOut).called(1);
    expect(states.first, isA<AsyncLoading<void>>());
    expect(states.last, isA<AsyncData<void>>());
  });

  test('keeps a failed sign-out as an error', () async {
    final auth = _MockFirebaseAuth();
    when(auth.signOut)
        .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
    final container = containerWith(auth);

    final signedOut = await container
        .read(calorieGoalLoadFailedControllerProvider.notifier)
        .signOut();

    expect(signedOut, isFalse);
    expect(states.first, isA<AsyncLoading<void>>());
    expect(states.last.error, isA<FirebaseAuthException>());
  });
}
