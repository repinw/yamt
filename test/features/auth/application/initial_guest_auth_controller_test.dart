import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/features/auth/application/initial_guest_auth_controller.dart';
import 'package:yamt/features/auth/data/auth_repository.dart';
import 'package:yamt/features/auth/data/auth_service.dart';

import '../../../helpers/fake_auth_repository.dart';

class _MockUser extends Mock implements User;

void main() {
  test(
    'is loading while authState is loading, then signs in on null user',
    () async {
      final fakeRepo = FakeAuthRepository();
      final authController = StreamController<User?>();
      addTearDown(authController.close);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
          authStateChangesProvider.overrideWith((ref) => authController.stream),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(
        initialGuestAuthControllerProvider,
        (previous, next) {},
      );
      addTearDown(sub.close);

      // Initial state before stream emits is loading.
      expect(
        container.read(initialGuestAuthControllerProvider).isLoading,
        isTrue,
      );

      // Emit null (fresh install: no cached user).
      authController.add(null);
      await pumpEventQueue();

      // Controller should have initiated guest sign-in.
      expect(fakeRepo.guestCalls, 1);
      expect(
        container.read(initialGuestAuthControllerProvider).hasValue,
        isTrue,
      );
    },
  );

  test('does not sign in anonymously when user already exists', () async {
    final fakeRepo = FakeAuthRepository();
    final user = _MockUser();
    when(() => user.uid).thenReturn('user-1');

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepo),
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(user),
        ),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(
      initialGuestAuthControllerProvider,
      (previous, next) {},
    );
    addTearDown(sub.close);

    await pumpEventQueue();
    expect(fakeRepo.guestCalls, 0);
    expect(container.read(initialGuestAuthControllerProvider).hasValue, isTrue);
  });

  test('does not trigger second guest sign-in after user signs out', () async {
    final fakeRepo = FakeAuthRepository();
    final authController = StreamController<User?>();
    addTearDown(authController.close);

    final user = _MockUser();
    when(() => user.uid).thenReturn('user-1');

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepo),
        authStateChangesProvider.overrideWith((ref) => authController.stream),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(
      initialGuestAuthControllerProvider,
      (previous, next) {},
    );
    addTearDown(sub.close);

    // First emission: null triggers initial sign-in.
    authController.add(null);
    await pumpEventQueue();
    expect(fakeRepo.guestCalls, 1);

    // Second emission: user signs in.
    authController.add(user);
    await pumpEventQueue();
    expect(fakeRepo.guestCalls, 1);

    // Third emission: user logs out (user becomes null again).
    authController.add(null);
    await pumpEventQueue();
    // guestCalls must still be 1 (does not repeat).
    expect(fakeRepo.guestCalls, 1);
  });

  test('stores AsyncError when anonymous sign in fails', () async {
    final fakeRepo = FakeAuthRepository(shouldFailGuest: true);
    final authController = StreamController<User?>();
    addTearDown(authController.close);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepo),
        authStateChangesProvider.overrideWith((ref) => authController.stream),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(
      initialGuestAuthControllerProvider,
      (previous, next) {},
    );
    addTearDown(sub.close);

    authController.add(null);
    await pumpEventQueue();

    expect(fakeRepo.guestCalls, 1);
    expect(container.read(initialGuestAuthControllerProvider).hasError, isTrue);
  });
}
