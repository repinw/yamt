import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/settings/account_page.dart';
import 'package:yamt/features/settings/settings_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _MockUser extends Mock implements User {}

void main() {
  testWidgets('SettingsPage renders localized rows', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SettingsPage()),
      ),
    );

    expect(find.byIcon(Icons.language_outlined), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Choose app language'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Manage reminders and alerts'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Manage profile and sign-in'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('App version and information'), findsOneWidget);
  });

  testWidgets('Account tile opens AccountPage', (tester) async {
    final user = _MockUser();
    when(() => user.isAnonymous).thenReturn(false);
    when(() => user.displayName).thenReturn('Jane Doe');
    when(() => user.email).thenReturn('jane@example.com');
    when(() => user.uid).thenReturn('uid-123');

    final router = GoRouter(
      initialLocation: AppRoutes.homeSettings,
      routes: [
        GoRoute(
          path: AppRoutes.homeSettings,
          builder: (context, state) => const Scaffold(body: SettingsPage()),
        ),
        GoRoute(
          path: AppRoutes.homeSettingsAccount,
          builder: (context, state) => const AccountPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(user)),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    await tester.tap(find.text('Account').first);
    await tester.pumpAndSettle();

    expect(find.byType(AccountPage), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });
}
