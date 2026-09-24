import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/settings/data/secondary_auth_client.dart';
import 'package:yamt/features/settings/presentation/controllers/account_link_conflict_controller.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

class _MockUser extends Mock implements User {
  @override
  String get uid => 'guest-1';
}

class _MockUserCredential extends Mock implements UserCredential;

class _MockAuthCredential extends Mock implements AuthCredential;

class _MockFirebaseApp extends Mock implements FirebaseApp;

class _MockSecondaryAuthClient extends Mock implements SecondaryAuthClient;

void main() {
  setUpAll(() {
    registerFallbackValue(_MockAuthCredential());
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
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
      when(() => secondaryAuth.signInWithCredential(credential))
          .thenAnswer((_) async => secondaryCredential);
      when(() => secondaryCredential.user).thenReturn(existingUser);
      when(existingUser.delete).thenAnswer((_) async {});
      when(() => guestUser.linkWithCredential(credential))
          .thenAnswer((_) async => _MockUserCredential());
      when(() => secondaryClient.disposeApp(app)).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          secondaryAuthClientProvider.overrideWithValue(secondaryClient),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(accountLinkConflictControllerProvider.notifier)
          .overwriteExistingGoogleAccountWithGuest(credential);

      verify(existingUser.delete).called(1);
      verify(() => guestUser.linkWithCredential(credential)).called(1);
      verify(() => secondaryClient.disposeApp(app)).called(1);
      expect(
        container.read(accountLinkConflictControllerProvider),
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
            .read(accountLinkConflictControllerProvider.notifier)
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

  test('overwriteExistingGoogleAccountWithGuest throws when secondary '
      'user missing', () async {
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
    when(() => secondaryAuth.signInWithCredential(credential))
        .thenAnswer((_) async => secondaryCredential);
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
          .read(accountLinkConflictControllerProvider.notifier)
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
    expect(
      container.read(accountLinkConflictControllerProvider).hasError,
      isTrue,
    );
  });

  test('overwriteExistingGoogleAccountWithGuest stores AsyncError on '
      'sign-in failure', () async {
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
    when(() => secondaryAuth.signInWithCredential(credential)).thenThrow(error);
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
          .read(accountLinkConflictControllerProvider.notifier)
          .overwriteExistingGoogleAccountWithGuest(credential),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(
      container.read(accountLinkConflictControllerProvider).hasError,
      isTrue,
    );
    verify(() => secondaryClient.disposeApp(app)).called(1);
  });

  test(
    'deleteGuestAndSignInWithGoogleCredential signs in with credential',
    () async {
      final auth = _MockFirebaseAuth();
      final guestUser = _MockUser();
      final credential = _MockAuthCredential();
      when(() => auth.currentUser).thenReturn(guestUser);
      when(() => guestUser.isAnonymous).thenReturn(true);
      when(guestUser.delete).thenAnswer((_) async {});
      when(() => auth.signInWithCredential(credential))
          .thenAnswer((_) async => _MockUserCredential());

      final container = ProviderContainer(
        overrides: [firebaseAuthProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);

      await container
          .read(accountLinkConflictControllerProvider.notifier)
          .deleteGuestAndSignInWithGoogleCredential(credential);

      verify(guestUser.delete).called(1);
      verify(() => auth.signInWithCredential(credential)).called(1);
      expect(
        container.read(accountLinkConflictControllerProvider),
        const AsyncData<void>(null),
      );
    },
  );

  test('deleteGuestAndSignInWithGoogleCredential throws when guest '
      'session missing', () async {
    final auth = _MockFirebaseAuth();
    final credential = _MockAuthCredential();
    when(() => auth.currentUser).thenReturn(null);

    final container = ProviderContainer(
      overrides: [firebaseAuthProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);

    await expectLater(
      container
          .read(accountLinkConflictControllerProvider.notifier)
          .deleteGuestAndSignInWithGoogleCredential(credential),
      throwsA(
        isA<FirebaseAuthException>().having(
          (e) => e.code,
          'code',
          'guest-session-required',
        ),
      ),
    );
  });
}
