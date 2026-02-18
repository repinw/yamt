import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/features/auth/provider/auth_repository.dart';
import 'package:yamt/features/auth/provider/google_auth_controller.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/auth/welcome_page.dart';
import 'package:yamt/features/auth/widgets/login_form.dart';
import 'package:yamt/features/auth/widgets/register_form.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../helpers/fake_auth_repository.dart';

class _FirebaseGuestErrorRepository implements AuthRepository {
  const _FirebaseGuestErrorRepository(this.error);

  final FirebaseAuthException error;

  @override
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInAnonymously() {
    throw error;
  }
}

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

Widget _wrapWithApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('LoginForm shows validation errors for empty fields', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapWithApp(const LoginForm()));

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('The field is required'), findsNWidgets(2));
  });

  testWidgets('LoginForm submits valid credentials', (tester) async {
    final fakeRepository = FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: LoginForm()),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'user@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret123',
    );

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(fakeRepository.signInCalls, 1);
  });

  testWidgets(
    'RegisterForm shows validation error when passwords do not match',
    (tester) async {
      await tester.pumpWidget(_wrapWithApp(const RegisterForm()));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'secret123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'),
        'different-secret',
      );

      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    },
  );

  testWidgets('RegisterForm submits valid credentials', (tester) async {
    final fakeRepository = FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: RegisterForm()),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'user@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'secret123',
    );

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(fakeRepository.registerCalls, 1);
  });

  testWidgets('WelcomePage guest button triggers guest sign in', (
    tester,
  ) async {
    final fakeRepository = FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepository),
          authStateChangesProvider.overrideWith(
            (ref) => const Stream<User?>.empty(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WelcomePage(),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Login as guest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login as guest'));
    await tester.pumpAndSettle();

    expect(fakeRepository.guestCalls, 1);
  });

  testWidgets('WelcomePage shows fallback snackbar when guest sign-in fails', (
    tester,
  ) async {
    final fakeRepository = FakeAuthRepository(shouldFailGuest: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepository),
          authStateChangesProvider.overrideWith(
            (ref) => const Stream<User?>.empty(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WelcomePage(),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Login as guest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login as guest'));
    await tester.pumpAndSettle();

    expect(fakeRepository.guestCalls, 1);
    expect(find.text('Authentication failed'), findsOneWidget);
  });

  testWidgets('WelcomePage toggles between register and login modes', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => const Stream<User?>.empty(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WelcomePage(),
        ),
      ),
    );

    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Register with Google'), findsOneWidget);

    await tester.tap(find.text("Already have an account? Login"));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Login with Google'), findsOneWidget);
    expect(find.text("Don't have an account? Register"), findsOneWidget);
  });

  testWidgets('WelcomePage shows auth form error from login submit', (
    tester,
  ) async {
    final fakeRepository = FakeAuthRepository(shouldFailSignIn: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepository),
          authStateChangesProvider.overrideWith(
            (ref) => const Stream<User?>.empty(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WelcomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Already have an account? Login'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'user@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret123',
    );

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(fakeRepository.signInCalls, 1);
    expect(find.text('Authentication failed'), findsOneWidget);
  });

  testWidgets('WelcomePage localizes FirebaseAuthException code in snackbar', (
    tester,
  ) async {
    final repository = _FirebaseGuestErrorRepository(
      FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'backend message should not be shown',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          authStateChangesProvider.overrideWith(
            (ref) => const Stream<User?>.empty(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WelcomePage(),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Login as guest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login as guest'));
    await tester.pumpAndSettle();

    expect(find.text('This sign-in method is not enabled.'), findsOneWidget);
  });

  testWidgets(
    'WelcomePage shows GoogleSignInException description in snackbar',
    (tester) async {
      const googleErrorMessage = 'Google consent screen failed';
      final mockGoogleSignIn = _MockGoogleSignIn();
      when(() => mockGoogleSignIn.authenticate()).thenThrow(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
          description: googleErrorMessage,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith(
              (ref) => const Stream<User?>.empty(),
            ),
            googleSignInProvider.overrideWith(
              (ref) => Future<GoogleSignIn>.value(mockGoogleSignIn),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const WelcomePage(),
          ),
        ),
      );

      await tester.ensureVisible(find.text('Register with Google'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Register with Google'));
      await tester.pumpAndSettle();

      expect(find.text(googleErrorMessage), findsOneWidget);
    },
  );

  testWidgets(
    'WelcomePage shows progress indicator while Google auth is loading',
    (tester) async {
      final mockGoogleSignIn = _MockGoogleSignIn();
      final completer = Completer<GoogleSignInAccount>();
      when(
        () => mockGoogleSignIn.authenticate(),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith(
              (ref) => const Stream<User?>.empty(),
            ),
            googleSignInProvider.overrideWith(
              (ref) => Future<GoogleSignIn>.value(mockGoogleSignIn),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const WelcomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Register with Google'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      completer.completeError(
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      );
      await tester.pumpAndSettle();
    },
  );
}
