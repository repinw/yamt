import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/features/auth/provider/auth_form_controller.dart';
import 'package:yamt/features/auth/provider/auth_repository.dart';
import 'package:yamt/features/auth/provider/google_auth_controller.dart';
import 'package:yamt/features/auth/provider/guest_auth_controller.dart';
import 'package:yamt/features/auth/provider/guest_name_setup_controller.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../helpers/fake_auth_repository.dart';

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MockFirebaseUser extends Mock implements User {}

class _FakeAuthCredential extends Fake implements AuthCredential {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeAuthCredential());
  });

  group('AuthFormController', () {
    test('sign in success sets data state', () async {
      final fakeRepository = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      );
      addTearDown(container.dispose);

      await container
          .read(authFormControllerProvider.notifier)
          .signInWithEmailAndPassword(
            email: 'demo@test.com',
            password: 'secret',
          );

      expect(fakeRepository.signInCalls, 1);
      expect(container.read(authFormControllerProvider).hasError, isFalse);
    });

    test('register error sets error state', () async {
      final fakeRepository = FakeAuthRepository(shouldFailRegister: true);
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      );
      addTearDown(container.dispose);

      await container
          .read(authFormControllerProvider.notifier)
          .createUserWithEmailAndPassword(
            email: 'demo@test.com',
            password: 'secret',
          );

      expect(fakeRepository.registerCalls, 1);
      expect(container.read(authFormControllerProvider).hasError, isTrue);
    });
  });

  group('GuestAuthController', () {
    test('guest sign in success calls repository', () async {
      final fakeRepository = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      );
      addTearDown(container.dispose);

      await container
          .read(guestAuthControllerProvider.notifier)
          .signInAnonymously();

      expect(fakeRepository.guestCalls, 1);
      expect(container.read(guestAuthControllerProvider).hasError, isFalse);
    });

    test('guest sign in failure sets error state', () async {
      final fakeRepository = FakeAuthRepository(shouldFailGuest: true);
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      );
      addTearDown(container.dispose);

      await container
          .read(guestAuthControllerProvider.notifier)
          .signInAnonymously();

      expect(fakeRepository.guestCalls, 1);
      expect(container.read(guestAuthControllerProvider).hasError, isTrue);
    });
  });

  group('GuestNameSetupController', () {
    test('saveDisplayName updates repository with trimmed value', () async {
      final fakeRepository = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      );
      addTearDown(container.dispose);

      await container
          .read(guestNameSetupControllerProvider.notifier)
          .saveDisplayName('  Guest Wlad  ');

      expect(fakeRepository.guestNameUpdateCalls, 1);
      expect(fakeRepository.lastGuestDisplayName, 'Guest Wlad');
      expect(
        container.read(guestNameSetupControllerProvider).hasError,
        isFalse,
      );
    });

    test('saveDisplayName ignores empty values', () async {
      final fakeRepository = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      );
      addTearDown(container.dispose);

      await container
          .read(guestNameSetupControllerProvider.notifier)
          .saveDisplayName('  ');

      expect(fakeRepository.guestNameUpdateCalls, 0);
      expect(
        container.read(guestNameSetupControllerProvider),
        const AsyncData<void>(null),
      );
    });
  });

  group('GoogleAuthController', () {
    test(
      'maps canceled GoogleSignInException to user-friendly auth error',
      () async {
        final mockGoogleSignIn = _MockGoogleSignIn();
        when(() => mockGoogleSignIn.authenticate()).thenThrow(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.canceled,
            description: 'account picker canceled',
          ),
        );

        final container = ProviderContainer(
          overrides: [
            googleSignInProvider.overrideWith(
              (ref) => Future<GoogleSignIn>.value(mockGoogleSignIn),
            ),
          ],
        );
        addTearDown(container.dispose);
        final subscription = container.listen(
          googleAuthControllerProvider,
          (previous, next) {},
        );
        addTearDown(subscription.close);

        await container
            .read(googleAuthControllerProvider.notifier)
            .signInWithGoogle();

        final state = container.read(googleAuthControllerProvider);
        expect(state.hasError, isTrue);
        final error = state.asError!.error;
        expect(error, isA<FirebaseAuthException>());
        expect(
          (error as FirebaseAuthException).code,
          'google-sign-in-canceled',
        );
        expect(error.message, 'Google sign-in failed. Please try again.');
      },
    );

    test(
      'treats interrupted GoogleSignInException as non-error state',
      () async {
        final mockGoogleSignIn = _MockGoogleSignIn();
        when(() => mockGoogleSignIn.authenticate()).thenThrow(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.interrupted,
            description: 'flow interrupted',
          ),
        );

        final container = ProviderContainer(
          overrides: [
            googleSignInProvider.overrideWith(
              (ref) => Future<GoogleSignIn>.value(mockGoogleSignIn),
            ),
          ],
        );
        addTearDown(container.dispose);
        final subscription = container.listen(
          googleAuthControllerProvider,
          (previous, next) {},
        );
        addTearDown(subscription.close);

        await container
            .read(googleAuthControllerProvider.notifier)
            .signInWithGoogle();

        final state = container.read(googleAuthControllerProvider);
        expect(state.hasError, isFalse);
        expect(state, const AsyncData<void>(null));
      },
    );

    test('returns auth error when Google ID token is missing', () async {
      final mockGoogleSignIn = _MockGoogleSignIn();
      final mockGoogleAccount = _MockGoogleSignInAccount();

      when(
        () => mockGoogleSignIn.authenticate(),
      ).thenAnswer((_) async => mockGoogleAccount);
      when(
        () => mockGoogleAccount.authentication,
      ).thenReturn(const GoogleSignInAuthentication(idToken: null));

      final container = ProviderContainer(
        overrides: [
          googleSignInProvider.overrideWith(
            (ref) => Future<GoogleSignIn>.value(mockGoogleSignIn),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        googleAuthControllerProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      await container
          .read(googleAuthControllerProvider.notifier)
          .signInWithGoogle();

      final state = container.read(googleAuthControllerProvider);
      expect(state.hasError, isTrue);
      final error = state.asError!.error;
      expect(error, isA<FirebaseAuthException>());
      expect((error as FirebaseAuthException).code, 'google-id-token-missing');
      expect(error.message, 'Missing Google ID token.');
    });

    test('signs in to Firebase when Google returns a valid ID token', () async {
      final mockGoogleSignIn = _MockGoogleSignIn();
      final mockGoogleAccount = _MockGoogleSignInAccount();
      final mockFirebaseAuth = _MockFirebaseAuth();
      final mockUserCredential = _MockUserCredential();

      when(
        () => mockGoogleSignIn.authenticate(),
      ).thenAnswer((_) async => mockGoogleAccount);
      when(
        () => mockGoogleAccount.authentication,
      ).thenReturn(const GoogleSignInAuthentication(idToken: 'id-token-123'));
      when(
        () => mockFirebaseAuth.signInWithCredential(any()),
      ).thenAnswer((_) async => mockUserCredential);

      final container = ProviderContainer(
        overrides: [
          googleSignInProvider.overrideWith(
            (ref) => Future<GoogleSignIn>.value(mockGoogleSignIn),
          ),
          firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        googleAuthControllerProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      await container
          .read(googleAuthControllerProvider.notifier)
          .signInWithGoogle();

      final state = container.read(googleAuthControllerProvider);
      expect(state.hasError, isFalse);
      expect(state, const AsyncData<void>(null));

      final capturedCredential =
          verify(
                () => mockFirebaseAuth.signInWithCredential(captureAny()),
              ).captured.single
              as AuthCredential;
      expect(capturedCredential.providerId, 'google.com');
      expect((capturedCredential as OAuthCredential).idToken, 'id-token-123');
    });

    test(
      'links Google credential to current user when linking account',
      () async {
        final mockGoogleSignIn = _MockGoogleSignIn();
        final mockGoogleAccount = _MockGoogleSignInAccount();
        final mockFirebaseAuth = _MockFirebaseAuth();
        final mockFirebaseUser = _MockFirebaseUser();
        final mockUserCredential = _MockUserCredential();

        when(
          () => mockGoogleSignIn.authenticate(),
        ).thenAnswer((_) async => mockGoogleAccount);
        when(
          () => mockGoogleAccount.authentication,
        ).thenReturn(const GoogleSignInAuthentication(idToken: 'id-token-123'));
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
        when(
          () => mockFirebaseUser.linkWithCredential(any()),
        ).thenAnswer((_) async => mockUserCredential);

        final container = ProviderContainer(
          overrides: [
            googleSignInProvider.overrideWith(
              (ref) => Future<GoogleSignIn>.value(mockGoogleSignIn),
            ),
            firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
          ],
        );
        addTearDown(container.dispose);
        final subscription = container.listen(
          googleAuthControllerProvider,
          (previous, next) {},
        );
        addTearDown(subscription.close);

        await container
            .read(googleAuthControllerProvider.notifier)
            .linkCurrentUserWithGoogle();

        final state = container.read(googleAuthControllerProvider);
        expect(state.hasError, isFalse);
        expect(state, const AsyncData<void>(null));
        verifyNever(() => mockFirebaseAuth.signInWithCredential(any()));

        final capturedCredential =
            verify(
                  () => mockFirebaseUser.linkWithCredential(captureAny()),
                ).captured.single
                as AuthCredential;
        expect(capturedCredential.providerId, 'google.com');
        expect((capturedCredential as OAuthCredential).idToken, 'id-token-123');
      },
    );

    test('linking without current user throws no-current-user', () async {
      final mockGoogleSignIn = _MockGoogleSignIn();
      final mockGoogleAccount = _MockGoogleSignInAccount();
      final mockFirebaseAuth = _MockFirebaseAuth();

      when(
        () => mockGoogleSignIn.authenticate(),
      ).thenAnswer((_) async => mockGoogleAccount);
      when(
        () => mockGoogleAccount.authentication,
      ).thenReturn(const GoogleSignInAuthentication(idToken: 'id-token-123'));
      when(() => mockFirebaseAuth.currentUser).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          googleSignInProvider.overrideWith(
            (ref) => Future<GoogleSignIn>.value(mockGoogleSignIn),
          ),
          firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        googleAuthControllerProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      await expectLater(
        container
            .read(googleAuthControllerProvider.notifier)
            .linkCurrentUserWithGoogle(),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'no-current-user',
          ),
        ),
      );

      expect(container.read(googleAuthControllerProvider).hasError, isTrue);
    });

    test(
      'linking rethrows canceled Google sign-in as FirebaseAuthException',
      () async {
        final mockGoogleSignIn = _MockGoogleSignIn();
        when(() => mockGoogleSignIn.authenticate()).thenThrow(
          const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
        );

        final container = ProviderContainer(
          overrides: [
            googleSignInProvider.overrideWith(
              (ref) => Future<GoogleSignIn>.value(mockGoogleSignIn),
            ),
          ],
        );
        addTearDown(container.dispose);
        final subscription = container.listen(
          googleAuthControllerProvider,
          (previous, next) {},
        );
        addTearDown(subscription.close);

        await expectLater(
          container
              .read(googleAuthControllerProvider.notifier)
              .linkCurrentUserWithGoogle(),
          throwsA(
            isA<FirebaseAuthException>().having(
              (e) => e.code,
              'code',
              'google-sign-in-canceled',
            ),
          ),
        );
      },
    );

    test('googleSignInProvider executes default initialization path', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await expectLater(
        container.read(googleSignInProvider.future),
        throwsA(anything),
      );
    });

    test(
      'googleSignInProvider evaluates non-android server client path',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await expectLater(
          container.read(googleSignInProvider.future),
          throwsA(anything),
        );
      },
    );
  });
}
