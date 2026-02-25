import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/settings/account_page.dart';
import 'package:yamt/features/settings/provider/account_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _MockUser extends Mock implements User {}

class _FakeCredential extends Fake implements AuthCredential {}

class _FakeAccountController extends AccountController {
  _FakeAccountController({
    this.onSignOut,
    this.onLinkGuestWithGoogle,
    this.onOverwriteExisting,
    this.onDeleteGuestAndSignIn,
    this.onDeleteCurrentAccount,
  });

  final Future<void> Function()? onSignOut;
  final Future<bool> Function()? onLinkGuestWithGoogle;
  final Future<void> Function(AuthCredential credential)? onOverwriteExisting;
  final Future<void> Function(AuthCredential credential)?
  onDeleteGuestAndSignIn;
  final Future<void> Function()? onDeleteCurrentAccount;

  @override
  FutureOr<void> build() {}

  @override
  Future<void> signOut() async {
    await onSignOut?.call();
  }

  @override
  Future<bool> linkGuestWithGoogle() async {
    return onLinkGuestWithGoogle?.call() ?? true;
  }

  @override
  Future<void> overwriteExistingGoogleAccountWithGuest(
    AuthCredential credential,
  ) async {
    await onOverwriteExisting?.call(credential);
  }

  @override
  Future<void> deleteGuestAndSignInWithGoogleCredential(
    AuthCredential credential,
  ) async {
    await onDeleteGuestAndSignIn?.call(credential);
  }

  @override
  Future<void> deleteCurrentAccount() async {
    await onDeleteCurrentAccount?.call();
  }
}

Widget _wrap({
  required Stream<User?> authStream,
  required _FakeAccountController controller,
}) {
  return ProviderScope(
    overrides: [
      authStateChangesProvider.overrideWith((ref) => authStream),
      accountControllerProvider.overrideWith(() => controller),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AccountPage(),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeCredential());
  });

  testWidgets('shows loading indicator while auth stream is pending', (
    tester,
  ) async {
    final controller = StreamController<User?>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      _wrap(
        authStream: controller.stream,
        controller: _FakeAccountController(),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows auth error fallback for auth stream failure', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        authStream: Stream<User?>.error(Exception('auth stream failed')),
        controller: _FakeAccountController(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Authentication failed'), findsOneWidget);
  });

  testWidgets('sign out error shows localized snackbar message', (
    tester,
  ) async {
    final user = _MockUser();
    when(() => user.isAnonymous).thenReturn(false);
    when(() => user.displayName).thenReturn('Jane');
    when(() => user.email).thenReturn('jane@example.com');
    when(() => user.uid).thenReturn('uid-123');

    await tester.pumpWidget(
      _wrap(
        authStream: Stream<User?>.value(user),
        controller: _FakeAccountController(
          onSignOut: () async =>
              throw FirebaseAuthException(code: 'operation-not-allowed'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('This sign-in method is not enabled.'), findsOneWidget);
  });

  testWidgets('guest link success shows success snackbar', (tester) async {
    final user = _MockUser();
    when(() => user.isAnonymous).thenReturn(true);
    when(() => user.displayName).thenReturn(null);
    when(() => user.email).thenReturn(null);
    when(() => user.uid).thenReturn('guest-123');

    await tester.pumpWidget(
      _wrap(
        authStream: Stream<User?>.value(user),
        controller: _FakeAccountController(
          onLinkGuestWithGoogle: () async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Link with Google'));
    await tester.pumpAndSettle();

    expect(find.text('Account linked successfully.'), findsOneWidget);
  });

  testWidgets(
    'non-firebase guest link error falls back to generic auth error',
    (tester) async {
      final user = _MockUser();
      when(() => user.isAnonymous).thenReturn(true);
      when(() => user.displayName).thenReturn(null);
      when(() => user.email).thenReturn(null);
      when(() => user.uid).thenReturn('guest-123');

      await tester.pumpWidget(
        _wrap(
          authStream: Stream<User?>.value(user),
          controller: _FakeAccountController(
            onLinkGuestWithGoogle: () async => throw Exception('unexpected'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Link with Google'));
      await tester.pumpAndSettle();

      expect(find.text('Authentication failed'), findsOneWidget);
    },
  );

  testWidgets('credential conflict without credential shows mapped error', (
    tester,
  ) async {
    final user = _MockUser();
    when(() => user.isAnonymous).thenReturn(true);
    when(() => user.displayName).thenReturn(null);
    when(() => user.email).thenReturn(null);
    when(() => user.uid).thenReturn('guest-123');

    await tester.pumpWidget(
      _wrap(
        authStream: Stream<User?>.value(user),
        controller: _FakeAccountController(
          onLinkGuestWithGoogle: () async =>
              throw FirebaseAuthException(code: 'credential-already-in-use'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Link with Google'));
    await tester.pumpAndSettle();

    expect(
      find.text('This credential is already used by another account.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'credential conflict dialog cancel keeps both actions untouched',
    (tester) async {
      final user = _MockUser();
      final credential = _FakeCredential();
      when(() => user.isAnonymous).thenReturn(true);
      when(() => user.displayName).thenReturn(null);
      when(() => user.email).thenReturn(null);
      when(() => user.uid).thenReturn('guest-123');
      var overwriteCalled = false;
      var deleteCalled = false;

      await tester.pumpWidget(
        _wrap(
          authStream: Stream<User?>.value(user),
          controller: _FakeAccountController(
            onLinkGuestWithGoogle: () async => throw FirebaseAuthException(
              code: 'credential-already-in-use',
              credential: credential,
            ),
            onOverwriteExisting: (_) async => overwriteCalled = true,
            onDeleteGuestAndSignIn: (_) async => deleteCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Link with Google'));
      await tester.pumpAndSettle();
      expect(find.text('Google account already in use'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(overwriteCalled, isFalse);
      expect(deleteCalled, isFalse);
    },
  );

  testWidgets('credential conflict overwrite action triggers overwrite flow', (
    tester,
  ) async {
    final user = _MockUser();
    final credential = _FakeCredential();
    when(() => user.isAnonymous).thenReturn(true);
    when(() => user.displayName).thenReturn(null);
    when(() => user.email).thenReturn(null);
    when(() => user.uid).thenReturn('guest-123');
    var called = false;

    await tester.pumpWidget(
      _wrap(
        authStream: Stream<User?>.value(user),
        controller: _FakeAccountController(
          onLinkGuestWithGoogle: () async => throw FirebaseAuthException(
            code: 'credential-already-in-use',
            credential: credential,
          ),
          onOverwriteExisting: (_) async => called = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Link with Google'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Overwrite with this guest'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(
      find.text('Google account moved to this guest account.'),
      findsOneWidget,
    );
  });

  testWidgets('credential conflict delete action triggers delete flow', (
    tester,
  ) async {
    final user = _MockUser();
    final credential = _FakeCredential();
    when(() => user.isAnonymous).thenReturn(true);
    when(() => user.displayName).thenReturn(null);
    when(() => user.email).thenReturn(null);
    when(() => user.uid).thenReturn('guest-123');
    var called = false;

    await tester.pumpWidget(
      _wrap(
        authStream: Stream<User?>.value(user),
        controller: _FakeAccountController(
          onLinkGuestWithGoogle: () async => throw FirebaseAuthException(
            code: 'credential-already-in-use',
            credential: credential,
          ),
          onDeleteGuestAndSignIn: (_) async => called = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Link with Google'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete guest and sign in'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(
      find.text('Guest account deleted. Signed in with Google.'),
      findsOneWidget,
    );
  });

  testWidgets('credential conflict action error is surfaced to user', (
    tester,
  ) async {
    final user = _MockUser();
    final credential = _FakeCredential();
    when(() => user.isAnonymous).thenReturn(true);
    when(() => user.displayName).thenReturn(null);
    when(() => user.email).thenReturn(null);
    when(() => user.uid).thenReturn('guest-123');

    await tester.pumpWidget(
      _wrap(
        authStream: Stream<User?>.value(user),
        controller: _FakeAccountController(
          onLinkGuestWithGoogle: () async => throw FirebaseAuthException(
            code: 'credential-already-in-use',
            credential: credential,
          ),
          onOverwriteExisting: (_) async =>
              throw FirebaseAuthException(code: 'operation-not-allowed'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Link with Google'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Overwrite with this guest'));
    await tester.pumpAndSettle();

    expect(find.text('This sign-in method is not enabled.'), findsOneWidget);
  });

  testWidgets('delete account cancel keeps account untouched', (tester) async {
    final user = _MockUser();
    when(() => user.isAnonymous).thenReturn(false);
    when(() => user.displayName).thenReturn('Jane');
    when(() => user.email).thenReturn('jane@example.com');
    when(() => user.uid).thenReturn('uid-123');
    var deleteCalled = false;

    await tester.pumpWidget(
      _wrap(
        authStream: Stream<User?>.value(user),
        controller: _FakeAccountController(
          onDeleteCurrentAccount: () async => deleteCalled = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    expect(find.text('Delete account?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(deleteCalled, isFalse);
  });

  testWidgets('delete account confirm triggers controller and snackbar', (
    tester,
  ) async {
    final user = _MockUser();
    when(() => user.isAnonymous).thenReturn(false);
    when(() => user.displayName).thenReturn('Jane');
    when(() => user.email).thenReturn('jane@example.com');
    when(() => user.uid).thenReturn('uid-123');
    var deleteCalled = false;

    await tester.pumpWidget(
      _wrap(
        authStream: Stream<User?>.value(user),
        controller: _FakeAccountController(
          onDeleteCurrentAccount: () async => deleteCalled = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(deleteCalled, isTrue);
    expect(find.text('Account deleted.'), findsOneWidget);
  });

  testWidgets('delete account failure shows localized auth error', (
    tester,
  ) async {
    final user = _MockUser();
    when(() => user.isAnonymous).thenReturn(false);
    when(() => user.displayName).thenReturn('Jane');
    when(() => user.email).thenReturn('jane@example.com');
    when(() => user.uid).thenReturn('uid-123');

    await tester.pumpWidget(
      _wrap(
        authStream: Stream<User?>.value(user),
        controller: _FakeAccountController(
          onDeleteCurrentAccount: () async =>
              throw FirebaseAuthException(code: 'operation-not-allowed'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('This sign-in method is not enabled.'), findsOneWidget);
  });
}
