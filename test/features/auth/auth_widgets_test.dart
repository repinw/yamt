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
import 'package:yamt/features/auth/auth_ui_constants.dart';
import 'package:yamt/features/auth/welcome_page.dart';
import 'package:yamt/features/auth/widgets/login_form.dart';
import 'package:yamt/features/auth/widgets/register_form.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../helpers/fake_auth_repository.dart';

class _FirebaseGuestErrorRepository implements AuthRepository {
  const _FirebaseGuestErrorRepository(this.error);

  final FirebaseAuthException error;

  @override
  String? get currentUserId => 'test-user-id';

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

  @override
  Future<void> updateCurrentUserDisplayName({
    required String displayName,
  }) async {}
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

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('LoginForm shows validation errors for empty fields', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapWithApp(const LoginForm()));

    await tester.tap(find.byKey(const Key('auth_login_submit_button')));
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
      find.byKey(const Key('auth_email_field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth_password_field')),
      'secret123',
    );

    await tester.tap(find.byKey(const Key('auth_login_submit_button')));
    await tester.pumpAndSettle();

    expect(fakeRepository.signInCalls, 1);
  });

  testWidgets('LoginForm shows email and password only as placeholders', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapWithApp(const LoginForm()));

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byIcon(Icons.mail_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });

  testWidgets('LoginForm places forgot password below the password field', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapWithApp(const LoginForm()));

    final forgotButton = find.byKey(const Key('auth_forgot_password_button'));
    final passwordField = find.byKey(const Key('auth_password_field'));

    expect(forgotButton, findsOneWidget);
    expect(passwordField, findsOneWidget);
    expect(
      tester.getTopLeft(forgotButton).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(passwordField).dy),
    );
    expect(
      tester.getTopLeft(forgotButton).dx,
      greaterThan(tester.getCenter(passwordField).dx),
    );
  });

  testWidgets('LoginForm toggles password visibility', (tester) async {
    await tester.pumpWidget(_wrapWithApp(const LoginForm()));

    final passwordField = find.byKey(const Key('auth_password_field'));
    final editablePassword = find.descendant(
      of: passwordField,
      matching: find.byType(EditableText),
    );

    expect(tester.widget<EditableText>(editablePassword).obscureText, isTrue);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();

    expect(tester.widget<EditableText>(editablePassword).obscureText, isFalse);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('RegisterForm shows placeholders and icons like the login form', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapWithApp(const RegisterForm()));

    expect(find.text('Display name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.mail_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));
  });

  testWidgets(
    'RegisterForm shows validation error when passwords do not match',
    (tester) async {
      await tester.pumpWidget(_wrapWithApp(const RegisterForm()));

      await tester.enterText(
        find.byKey(const Key('auth_display_name_field')),
        'Julianne Vane',
      );
      await tester.enterText(
        find.byKey(const Key('auth_email_field')),
        'user@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('auth_password_field')),
        'secret123',
      );
      await tester.enterText(
        find.byKey(const Key('auth_confirm_password_field')),
        'different-secret',
      );

      await tester.tap(find.byKey(const Key('auth_register_submit_button')));
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
      find.byKey(const Key('auth_display_name_field')),
      'Julianne Vane',
    );
    await tester.enterText(
      find.byKey(const Key('auth_email_field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth_password_field')),
      'secret123',
    );
    await tester.enterText(
      find.byKey(const Key('auth_confirm_password_field')),
      'secret123',
    );

    await tester.tap(find.byKey(const Key('auth_register_submit_button')));
    await tester.pumpAndSettle();

    expect(fakeRepository.registerCalls, 1);
    expect(fakeRepository.guestNameUpdateCalls, 1);
    expect(fakeRepository.lastGuestDisplayName, 'Julianne Vane');
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

    await _tapVisible(tester, find.byKey(const Key('auth_guest_button')));

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

    await _tapVisible(tester, find.byKey(const Key('auth_guest_button')));

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

    expect(find.byType(LoginForm), findsOneWidget);
    expect(find.text('Yamt'), findsOneWidget);
    expect(find.text('Yet Enother Meal Tracker'), findsOneWidget);
    expect(find.text('Login with Google'), findsOneWidget);

    await _tapVisible(
      tester,
      find.byKey(const Key('auth_switch_to_register_button')),
    );

    expect(find.byType(RegisterForm), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Register with Google'), findsOneWidget);
    expect(
      find.byKey(const Key('auth_switch_to_login_button')),
      findsOneWidget,
    );
  });

  testWidgets(
    'WelcomePage scales header on compact displays and stays scrollable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 560));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 560),
                padding: EdgeInsets.only(top: 44, bottom: 16),
                viewPadding: EdgeInsets.only(top: 44, bottom: 16),
              ),
              child: const WelcomePage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final badgeFinder = find.byKey(const Key('auth_header_badge'));

      expect(badgeFinder, findsOneWidget);
      expect(tester.getTopLeft(badgeFinder).dy, greaterThanOrEqualTo(44));
      expect(
        tester.getSize(badgeFinder).height,
        lessThan(AppAuthUi.heroBadgeSize),
      );

      await tester.ensureVisible(find.byKey(const Key('auth_guest_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_guest_button')), findsOneWidget);
    },
  );

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

    await tester.enterText(
      find.byKey(const Key('auth_email_field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth_password_field')),
      'secret123',
    );

    await tester.tap(find.byKey(const Key('auth_login_submit_button')));
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

    await _tapVisible(tester, find.byKey(const Key('auth_guest_button')));

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

      await _tapVisible(tester, find.byKey(const Key('auth_google_button')));

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

      await tester.ensureVisible(find.byKey(const Key('auth_google_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('auth_google_button')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      completer.completeError(
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      );
      await tester.pumpAndSettle();
    },
  );
}
