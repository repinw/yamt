import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/auth/provider/google_auth_controller.dart';
import 'package:yamt/features/settings/provider/account_controller.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MockAuthCredential extends Mock implements AuthCredential {}

class _MockFirebaseApp extends Mock implements FirebaseApp {}

class _MockSecondaryAuthClient extends Mock implements SecondaryAuthClient {}

class _FakeGoogleAuthController extends GoogleAuthController {
  _FakeGoogleAuthController({required this.onLink});

  final Future<void> Function() onLink;

  @override
  FutureOr<void> build() {}

  @override
  Future<void> linkCurrentUserWithGoogle() => onLink();
}

void main() {
  setUpAll(() {
    registerFallbackValue(_MockAuthCredential());
  });

  test('secondaryAuthClientProvider returns default implementation', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final client = container.read(secondaryAuthClientProvider);
    expect(client, isA<SecondaryAuthClient>());
  });

  test('generated provider hash methods are callable', () {
    expect(
      secondaryAuthClientProvider.debugGetCreateSourceHash(),
      isA<String>(),
    );
    expect(accountControllerProvider.debugGetCreateSourceHash(), isA<String>());
  });

  test('signOut succeeds and clears loading state', () async {
    final auth = _MockFirebaseAuth();
    when(() => auth.signOut()).thenAnswer((_) async {});

    final container = ProviderContainer(
      overrides: [firebaseAuthProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);

    await container.read(accountControllerProvider.notifier).signOut();

    expect(
      container.read(accountControllerProvider),
      const AsyncData<void>(null),
    );
    verify(() => auth.signOut()).called(1);
  });

  test('signOut propagates failure and stores AsyncError', () async {
    final auth = _MockFirebaseAuth();
    final error = FirebaseAuthException(code: 'network-request-failed');
    when(() => auth.signOut()).thenThrow(error);

    final container = ProviderContainer(
      overrides: [firebaseAuthProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(accountControllerProvider.notifier).signOut(),
      throwsA(isA<FirebaseAuthException>()),
    );

    expect(container.read(accountControllerProvider).hasError, isTrue);
  });

  test(
    'linkGuestWithGoogle returns true for linked non-anonymous user',
    () async {
      final auth = _MockFirebaseAuth();
      final user = _MockUser();
      when(() => user.isAnonymous).thenReturn(false);
      when(() => auth.currentUser).thenReturn(user);

      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          googleAuthControllerProvider.overrideWith(
            () => _FakeGoogleAuthController(onLink: () async {}),
          ),
        ],
      );
      addTearDown(container.dispose);

      final linked = await container
          .read(accountControllerProvider.notifier)
          .linkGuestWithGoogle();

      expect(linked, isTrue);
      expect(
        container.read(accountControllerProvider),
        const AsyncData<void>(null),
      );
    },
  );

  test(
    'linkGuestWithGoogle throws link-not-completed for anonymous user',
    () async {
      final auth = _MockFirebaseAuth();
      final user = _MockUser();
      when(() => user.isAnonymous).thenReturn(true);
      when(() => auth.currentUser).thenReturn(user);

      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          googleAuthControllerProvider.overrideWith(
            () => _FakeGoogleAuthController(onLink: () async {}),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container
            .read(accountControllerProvider.notifier)
            .linkGuestWithGoogle(),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'link-not-completed',
          ),
        ),
      );
      expect(container.read(accountControllerProvider).hasError, isTrue);
    },
  );

  test('linkGuestWithGoogle rethrows linking failure', () async {
    final auth = _MockFirebaseAuth();
    when(() => auth.currentUser).thenReturn(_MockUser());
    final error = FirebaseAuthException(code: 'operation-not-allowed');

    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        googleAuthControllerProvider.overrideWith(
          () => _FakeGoogleAuthController(onLink: () async => throw error),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(accountControllerProvider.notifier).linkGuestWithGoogle(),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(container.read(accountControllerProvider).hasError, isTrue);
  });

  test(
    'overwriteExistingGoogleAccountWithGuest completes happy path',
    () async {
      final auth = _MockFirebaseAuth();
      final guestUser = _MockUser();
      final existingUser = _MockUser();
      final credential = _MockAuthCredential();
      final app = _MockFirebaseApp();
      final secondaryAuth = _MockFirebaseAuth();
      final secondaryCredential = _MockUserCredential();
      final secondaryClient = _MockSecondaryAuthClient();

      when(() => auth.currentUser).thenReturn(guestUser);
      when(() => guestUser.isAnonymous).thenReturn(true);
      when(() => secondaryClient.createApp(any())).thenAnswer((_) async => app);
      when(() => secondaryClient.authForApp(app)).thenReturn(secondaryAuth);
      when(
        () => secondaryAuth.signInWithCredential(credential),
      ).thenAnswer((_) async => secondaryCredential);
      when(() => secondaryCredential.user).thenReturn(existingUser);
      when(() => existingUser.delete()).thenAnswer((_) async {});
      when(
        () => guestUser.linkWithCredential(credential),
      ).thenAnswer((_) async => _MockUserCredential());
      when(() => secondaryClient.disposeApp(app)).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          secondaryAuthClientProvider.overrideWithValue(secondaryClient),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(accountControllerProvider.notifier)
          .overwriteExistingGoogleAccountWithGuest(credential);

      verify(() => existingUser.delete()).called(1);
      verify(() => guestUser.linkWithCredential(credential)).called(1);
      verify(() => secondaryClient.disposeApp(app)).called(1);
      expect(
        container.read(accountControllerProvider),
        const AsyncData<void>(null),
      );
    },
  );

  test(
    'overwriteExistingGoogleAccountWithGuest throws when no guest session',
    () async {
      final auth = _MockFirebaseAuth();
      final credential = _MockAuthCredential();
      final secondaryClient = _MockSecondaryAuthClient();
      when(() => auth.currentUser).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          secondaryAuthClientProvider.overrideWithValue(secondaryClient),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container
            .read(accountControllerProvider.notifier)
            .overwriteExistingGoogleAccountWithGuest(credential),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'guest-session-required',
          ),
        ),
      );
      verifyNever(() => secondaryClient.createApp(any()));
    },
  );

  test(
    'overwriteExistingGoogleAccountWithGuest throws when secondary user missing',
    () async {
      final auth = _MockFirebaseAuth();
      final guestUser = _MockUser();
      final credential = _MockAuthCredential();
      final app = _MockFirebaseApp();
      final secondaryAuth = _MockFirebaseAuth();
      final secondaryCredential = _MockUserCredential();
      final secondaryClient = _MockSecondaryAuthClient();

      when(() => auth.currentUser).thenReturn(guestUser);
      when(() => guestUser.isAnonymous).thenReturn(true);
      when(() => secondaryClient.createApp(any())).thenAnswer((_) async => app);
      when(() => secondaryClient.authForApp(app)).thenReturn(secondaryAuth);
      when(
        () => secondaryAuth.signInWithCredential(credential),
      ).thenAnswer((_) async => secondaryCredential);
      when(() => secondaryCredential.user).thenReturn(null);
      when(() => secondaryClient.disposeApp(app)).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          secondaryAuthClientProvider.overrideWithValue(secondaryClient),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container
            .read(accountControllerProvider.notifier)
            .overwriteExistingGoogleAccountWithGuest(credential),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'link-not-completed',
          ),
        ),
      );
      verify(() => secondaryClient.disposeApp(app)).called(1);
      expect(container.read(accountControllerProvider).hasError, isTrue);
    },
  );

  test(
    'overwriteExistingGoogleAccountWithGuest stores AsyncError on sign-in failure',
    () async {
      final auth = _MockFirebaseAuth();
      final guestUser = _MockUser();
      final credential = _MockAuthCredential();
      final app = _MockFirebaseApp();
      final secondaryAuth = _MockFirebaseAuth();
      final secondaryClient = _MockSecondaryAuthClient();
      final error = FirebaseAuthException(code: 'network-request-failed');

      when(() => auth.currentUser).thenReturn(guestUser);
      when(() => guestUser.isAnonymous).thenReturn(true);
      when(() => secondaryClient.createApp(any())).thenAnswer((_) async => app);
      when(() => secondaryClient.authForApp(app)).thenReturn(secondaryAuth);
      when(
        () => secondaryAuth.signInWithCredential(credential),
      ).thenThrow(error);
      when(() => secondaryClient.disposeApp(app)).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          secondaryAuthClientProvider.overrideWithValue(secondaryClient),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container
            .read(accountControllerProvider.notifier)
            .overwriteExistingGoogleAccountWithGuest(credential),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(container.read(accountControllerProvider).hasError, isTrue);
      verify(() => secondaryClient.disposeApp(app)).called(1);
    },
  );

  test(
    'deleteGuestAndSignInWithGoogleCredential signs in with credential',
    () async {
      final auth = _MockFirebaseAuth();
      final guestUser = _MockUser();
      final credential = _MockAuthCredential();
      when(() => auth.currentUser).thenReturn(guestUser);
      when(() => guestUser.isAnonymous).thenReturn(true);
      when(() => guestUser.delete()).thenAnswer((_) async {});
      when(
        () => auth.signInWithCredential(credential),
      ).thenAnswer((_) async => _MockUserCredential());

      final container = ProviderContainer(
        overrides: [firebaseAuthProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);

      await container
          .read(accountControllerProvider.notifier)
          .deleteGuestAndSignInWithGoogleCredential(credential);

      verify(() => guestUser.delete()).called(1);
      verify(() => auth.signInWithCredential(credential)).called(1);
      expect(
        container.read(accountControllerProvider),
        const AsyncData<void>(null),
      );
    },
  );

  test(
    'deleteGuestAndSignInWithGoogleCredential throws when guest session missing',
    () async {
      final auth = _MockFirebaseAuth();
      final credential = _MockAuthCredential();
      when(() => auth.currentUser).thenReturn(null);

      final container = ProviderContainer(
        overrides: [firebaseAuthProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container
            .read(accountControllerProvider.notifier)
            .deleteGuestAndSignInWithGoogleCredential(credential),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'guest-session-required',
          ),
        ),
      );
    },
  );
}
