import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/settings/account_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _MockUser extends Mock implements User {}

Future<void> _ensureVisibleText(WidgetTester tester, String text) async {
  final finder = find.text(text, skipOffstage: false);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Widget _wrapWithApp({required Stream<User?> authStream}) {
  final container = ProviderContainer(
    overrides: [authStateChangesProvider.overrideWith((ref) => authStream)],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AccountPage(),
    ),
  );
}

void main() {
  testWidgets('AccountPage renders user details for non-guest user', (
    tester,
  ) async {
    final user = _MockUser();
    when(() => user.isAnonymous).thenReturn(false);
    when(() => user.displayName).thenReturn('Jane Doe');
    when(() => user.email).thenReturn('jane@example.com');
    when(() => user.uid).thenReturn('uid-123');

    await tester.pumpWidget(
      _wrapWithApp(authStream: Stream<User?>.value(user)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('jane@example.com'), findsOneWidget);
    expect(find.text('uid-123'), findsOneWidget);
    await _ensureVisibleText(tester, 'Sign out');
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Guest account'), findsNothing);
    expect(find.text('Link with Google'), findsNothing);
  });

  testWidgets('AccountPage shows guest upgrade UI for anonymous user', (
    tester,
  ) async {
    final user = _MockUser();
    when(() => user.isAnonymous).thenReturn(true);
    when(() => user.displayName).thenReturn(null);
    when(() => user.email).thenReturn(null);
    when(() => user.uid).thenReturn('guest-123');

    await tester.pumpWidget(
      _wrapWithApp(authStream: Stream<User?>.value(user)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Guest account'), findsOneWidget);
    expect(find.text('Link with Google'), findsOneWidget);
    expect(find.text('Link with email & password'), findsOneWidget);
    expect(find.text('Not set'), findsNWidgets(2));
    expect(find.text('guest-123'), findsOneWidget);
  });

  testWidgets('AccountPage shows fallback state when session is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithApp(authStream: Stream<User?>.value(null)),
    );
    await tester.pumpAndSettle();

    expect(find.text('No active account session.'), findsOneWidget);
  });
}
