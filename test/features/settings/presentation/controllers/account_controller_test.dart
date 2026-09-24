import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/presentation/controllers/google_auth_controller.dart';
import 'package:yamt/features/settings/presentation/controllers/account_controller.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

class _MockUser extends Mock implements User;

class _MockUserCredential extends Mock implements UserCredential;

class _MockAuthCredential extends Mock implements AuthCredential;

class _FakeGoogleAuthController extends GoogleAuthController {
  new({required this.onLink});

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

  test('generated provider hash methods are callable', () {
    expect(accountControllerProvider.debugGetCreateSourceHash(), isA<String>());
  });

  test('signOut succeeds and clears loading state', () async {
    final auth = _MockFirebaseAuth();
    when(auth.signOut).thenAnswer((_) async {});

    final container = ProviderContainer(
      overrides: [firebaseAuthProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);

    await container.read(accountControllerProvider.notifier).signOut();

    expect(
      container.read(accountControllerProvider),
      const AsyncData<void>(null),
    );
    verify(auth.signOut).called(1);
  });

  test('signOut propagates failure and stores AsyncError', () async {
    final auth = _MockFirebaseAuth();
    final error = FirebaseAuthException(code: 'network-request-failed');
    when(auth.signOut).thenThrow(error);

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

  test('deleteCurrentAccount deletes the user and its local keys', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'data_key_u1': 'key',
      'recovery_key_u1': 'recovery',
      'data_key_u2': 'other',
    });
    final auth = _MockFirebaseAuth();
    final user = _MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('u1');
    when(user.delete).thenAnswer((_) async {});

    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firebaseFirestoreProvider.overrideWith(
          (ref) => FakeFirebaseFirestore(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(accountControllerProvider.notifier)
        .deleteCurrentAccount();

    verify(user.delete).called(1);
    expect(
      container.read(accountControllerProvider),
      const AsyncData<void>(null),
    );
    const storage = FlutterSecureStorage();
    expect(await storage.read(key: 'data_key_u1'), isNull);
    expect(await storage.read(key: 'recovery_key_u1'), isNull);
    expect(await storage.read(key: 'data_key_u2'), 'other');
  });

  test('deleteCurrentAccount throws when no active user exists', () async {
    final auth = _MockFirebaseAuth();
    when(() => auth.currentUser).thenReturn(null);

    final container = ProviderContainer(
      overrides: [firebaseAuthProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(accountControllerProvider.notifier).deleteCurrentAccount(),
      throwsA(
        isA<FirebaseAuthException>().having(
          (e) => e.code,
          'code',
          'no-current-user',
        ),
      ),
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
    'linkGuestWithEmailPassword links guest user and returns true',
    () async {
      final auth = _MockFirebaseAuth();
      final guestUser = _MockUser();
      final linkedUser = _MockUser();
      final linkedCredential = _MockUserCredential();
      when(() => auth.currentUser).thenReturn(guestUser);
      when(() => guestUser.isAnonymous).thenReturn(true);
      when(() => linkedUser.isAnonymous).thenReturn(false);
      when(() => linkedCredential.user).thenReturn(linkedUser);
      when(() => guestUser.linkWithCredential(any()))
          .thenAnswer((_) async => linkedCredential);

      final container = ProviderContainer(
        overrides: [firebaseAuthProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);

      final linked = await container
          .read(accountControllerProvider.notifier)
          .linkGuestWithEmailPassword(
            email: 'jane@example.com',
            password: 'secret123',
          );

      expect(linked, isTrue);
      verify(() => guestUser.linkWithCredential(any())).called(1);
      expect(
        container.read(accountControllerProvider),
        const AsyncData<void>(null),
      );
    },
  );

  test(
    'linkGuestWithEmailPassword throws when no guest session is active',
    () async {
      final auth = _MockFirebaseAuth();
      when(() => auth.currentUser).thenReturn(null);

      final container = ProviderContainer(
        overrides: [firebaseAuthProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container
            .read(accountControllerProvider.notifier)
            .linkGuestWithEmailPassword(
              email: 'jane@example.com',
              password: 'x',
            ),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'guest-session-required',
          ),
        ),
      );
      expect(container.read(accountControllerProvider).hasError, isTrue);
    },
  );

  test(
    'linkGuestWithEmailPassword attaches credential to conflict errors',
    () async {
      final auth = _MockFirebaseAuth();
      final guestUser = _MockUser();
      final capturedCredentials = <AuthCredential>[];
      when(() => auth.currentUser).thenReturn(guestUser);
      when(() => guestUser.isAnonymous).thenReturn(true);
      when(() => guestUser.linkWithCredential(captureAny()))
          .thenAnswer((invocation) async {
            capturedCredentials.add(
              invocation.positionalArguments.first as AuthCredential,
            );
            throw FirebaseAuthException(code: 'email-already-in-use');
          });

      final container = ProviderContainer(
        overrides: [firebaseAuthProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container
            .read(accountControllerProvider.notifier)
            .linkGuestWithEmailPassword(
              email: 'jane@example.com',
              password: 'secret123',
            ),
        throwsA(
          isA<FirebaseAuthException>()
              .having((e) => e.code, 'code', 'email-already-in-use')
              .having((e) => e.credential, 'credential', isNotNull),
        ),
      );

      expect(capturedCredentials, hasLength(1));
      expect(container.read(accountControllerProvider).hasError, isTrue);
    },
  );
}
