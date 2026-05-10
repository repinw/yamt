import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/auth/guest_name_setup_page.dart';
import 'package:yamt/features/auth/provider/auth_repository.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/memory_app_preferences.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockUserMetadata extends Mock implements UserMetadata {}

class _DelayedGuestNameRepository extends FakeAuthRepository {
  _DelayedGuestNameRepository(this.completer);

  final Completer<void> completer;

  @override
  Future<void> updateCurrentUserDisplayName({
    required String displayName,
  }) async {
    guestNameUpdateCalls++;
    lastGuestDisplayName = displayName;
    await completer.future;
  }
}

class _FailingGuestNameRepository extends FakeAuthRepository {
  @override
  Future<void> updateCurrentUserDisplayName({required String displayName}) {
    throw Exception('save failed');
  }
}

Widget _wrapWithRouter(
  FakeAuthRepository repository, {
  String? displayName,
  bool isFirstSignIn = true,
  bool isAnonymous = false,
  _MockFirebaseAuth? firebaseAuth,
  MemoryAppPreferences? appPreferences,
}) {
  final auth = firebaseAuth ?? _MockFirebaseAuth();
  if (displayName == null && !isAnonymous) {
    when(() => auth.currentUser).thenReturn(null);
  } else {
    final user = _MockUser();
    when(() => user.displayName).thenReturn(displayName);
    when(() => user.isAnonymous).thenReturn(isAnonymous);
    if (!isAnonymous) {
      final metadata = _MockUserMetadata();
      final createdAt = DateTime.utc(2026, 2, 1, 9);
      final lastSignInAt = isFirstSignIn
          ? createdAt
          : createdAt.add(const Duration(days: 2));
      when(() => metadata.creationTime).thenReturn(createdAt);
      when(() => metadata.lastSignInTime).thenReturn(lastSignInAt);
      when(() => user.metadata).thenReturn(metadata);
    }
    when(() => auth.currentUser).thenReturn(user);
  }

  final router = GoRouter(
    initialLocation: AppRoutes.guestNameSetup,
    routes: [
      GoRoute(
        path: AppRoutes.guestNameSetup,
        builder: (context, state) => const GuestNameSetupPage(),
      ),
      GoRoute(
        path: AppRoutes.homeInventory,
        builder: (context, state) => const Scaffold(body: Text('Inventory')),
      ),
    ],
  );

  final preferences = appPreferences ?? MemoryAppPreferences();
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      appPreferencesProvider.overrideWithValue(preferences),
      authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
      firebaseAuthProvider.overrideWithValue(auth),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets('shows inline error when name is empty', (tester) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(_wrapWithRouter(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a display name.'), findsOneWidget);
    expect(repository.guestNameUpdateCalls, 0);
  });

  testWidgets('clears inline name error when user types', (tester) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(_wrapWithRouter(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter a display name.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Guest Wlad');
    await tester.pumpAndSettle();

    expect(find.text('Please enter a display name.'), findsNothing);
  });

  testWidgets('submits guest name to repository', (tester) async {
    final repository = FakeAuthRepository();
    final preferences = MemoryAppPreferences();
    await tester.pumpWidget(
      _wrapWithRouter(repository, appPreferences: preferences),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Guest Wlad');
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blue').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(repository.guestNameUpdateCalls, 1);
    expect(repository.lastGuestDisplayName, 'Guest Wlad');
    expect(
      preferences.getIntSync('preferred_seed_color'),
      AppSeedColors.blue.toARGB32(),
    );
    expect(preferences.getStringSync('preferred_theme_mode'), 'system');
    expect(find.text('Inventory'), findsNothing);
  });

  testWidgets('ignores repeated submit while request is loading', (
    tester,
  ) async {
    final completer = Completer<void>();
    final repository = _DelayedGuestNameRepository(completer);
    await tester.pumpWidget(_wrapWithRouter(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Guest Wlad');
    await tester.tap(find.byType(TextField));
    await tester.pump();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(repository.guestNameUpdateCalls, 1);
    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('prefills name from current user display name', (tester) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(
      _wrapWithRouter(repository, displayName: 'Google Name'),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'Google Name');
  });

  testWidgets('prefills name for returning user sign-in', (tester) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(
      _wrapWithRouter(
        repository,
        displayName: 'Google Name',
        isFirstSignIn: false,
      ),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'Google Name');
  });

  testWidgets('back button signs out anonymous guest', (tester) async {
    final repository = FakeAuthRepository();
    final auth = _MockFirebaseAuth();
    when(auth.signOut).thenAnswer((_) async {});
    await tester.pumpWidget(
      _wrapWithRouter(
        repository,
        isAnonymous: true,
        firebaseAuth: auth,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('guest_name_setup_back_button')));
    await tester.pumpAndSettle();

    verify(auth.signOut).called(1);
    expect(repository.guestNameUpdateCalls, 0);
  });

  testWidgets('back button shows snackbar when guest sign out fails', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    final auth = _MockFirebaseAuth();
    when(auth.signOut).thenThrow(
      FirebaseAuthException(code: 'network-request-failed'),
    );
    await tester.pumpWidget(
      _wrapWithRouter(
        repository,
        isAnonymous: true,
        firebaseAuth: auth,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('guest_name_setup_back_button')));
    await tester.pump();

    expect(
      find.text('Network error. Please check your connection.'),
      findsOneWidget,
    );
    verify(auth.signOut).called(1);
  });

  testWidgets('back button is disabled while guest name is saving', (
    tester,
  ) async {
    final completer = Completer<void>();
    final repository = _DelayedGuestNameRepository(completer);
    await tester.pumpWidget(
      _wrapWithRouter(repository, isAnonymous: true),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Guest Wlad');
    await tester.tap(find.text('Continue'));
    await tester.pump();

    final backButton = tester.widget<IconButton>(
      find.byKey(const Key('guest_name_setup_back_button')),
    );
    expect(backButton.onPressed, isNull);
    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('hides guest back button for linked users', (tester) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(
      _wrapWithRouter(repository, displayName: 'Google Name'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('guest_name_setup_back_button')), findsNothing);
  });

  testWidgets('changing color selection does not persist before save', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    final preferences = MemoryAppPreferences();
    await tester.pumpWidget(
      _wrapWithRouter(repository, appPreferences: preferences),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blue').last);
    await tester.pumpAndSettle();

    expect(preferences.getIntSync('preferred_seed_color'), isNull);
  });

  testWidgets('changing theme selection does not persist before save', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    final preferences = MemoryAppPreferences();
    await tester.pumpWidget(
      _wrapWithRouter(repository, appPreferences: preferences),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<ThemeMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    expect(preferences.getStringSync('preferred_theme_mode'), isNull);
  });

  testWidgets('shows snackbar when profile save fails', (tester) async {
    final repository = _FailingGuestNameRepository();
    await tester.pumpWidget(_wrapWithRouter(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Guest Wlad');
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Authentication failed'), findsOneWidget);
  });

  testWidgets('does not access ref after page unmount during submit', (
    tester,
  ) async {
    final completer = Completer<void>();
    final repository = _DelayedGuestNameRepository(completer);
    await tester.pumpWidget(_wrapWithRouter(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Guest Wlad');
    await tester.tap(find.text('Continue'));
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    completer.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
