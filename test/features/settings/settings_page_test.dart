import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/core/theme/seed_color_controller.dart';
import 'package:yamt/core/theme/theme_mode_controller.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/settings/account_page.dart';
import 'package:yamt/features/household/presentation/household_page.dart';
import 'package:yamt/features/settings/settings_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _MockUser extends Mock implements User {}

class _FakeAppPreferences implements AppPreferences {
  _FakeAppPreferences({Map<String, Object>? initialValues})
    : _values = initialValues ?? <String, Object>{};

  final Map<String, Object> _values;

  @override
  String? getStringSync(String key) {
    return _values[key] as String?;
  }

  @override
  int? getIntSync(String key) {
    return _values[key] as int?;
  }

  @override
  Future<String?> getString(String key) async {
    return _values[key] as String?;
  }

  @override
  Future<int?> getInt(String key) async {
    return _values[key] as int?;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _values[key] = value;
    return true;
  }
}

Future<void> _pumpSettingsPage(
  WidgetTester tester, {
  FutureOr<String> Function(Ref ref)? appVersionOverride,
  AsyncValue<String>? appVersionValueOverride,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appPreferencesProvider.overrideWithValue(_FakeAppPreferences()),
        if (appVersionValueOverride != null)
          appVersionProvider.overrideWithValue(appVersionValueOverride),
        if (appVersionOverride != null)
          appVersionProvider.overrideWith(appVersionOverride),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SettingsPage()),
      ),
    ),
  );
}

ListTile _aboutTile(WidgetTester tester) {
  final finder = find.ancestor(
    of: find.text('About'),
    matching: find.byType(ListTile),
  );
  return tester.widget<ListTile>(finder.first);
}

void main() {
  testWidgets('SettingsPage renders localized rows', (tester) async {
    await _pumpSettingsPage(
      tester,
      appVersionOverride: (ref) async => '1.1.0+2',
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.language_outlined), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.byIcon(Icons.group_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    expect(find.byIcon(Icons.format_paint_outlined), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Choose app language'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('System'), findsNWidgets(2));
    expect(find.text('Accent color'), findsOneWidget);
    expect(find.text('Teal'), findsNWidgets(2));
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Manage reminders and alerts'), findsOneWidget);
    expect(find.text('Household'), findsOneWidget);
    expect(
      find.text('Invite members and manage shared access'),
      findsOneWidget,
    );
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Manage profile and sign-in'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('App version and information'), findsOneWidget);
    expect(find.text('1.1.0+2'), findsOneWidget);
  });

  testWidgets('Household tile opens HouseholdPage', (tester) async {
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
          path: AppRoutes.homeSettingsHousehold,
          builder: (context, state) => const HouseholdPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appVersionProvider.overrideWith((ref) async => '1.1.0+2'),
          authStateChangesProvider.overrideWith((ref) => Stream.value(user)),
          appPreferencesProvider.overrideWithValue(_FakeAppPreferences()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    await tester.tap(find.text('Household').first);
    await tester.pumpAndSettle();

    expect(find.byType(HouseholdPage), findsOneWidget);
    expect(find.text('Invite members'), findsOneWidget);
  });

  testWidgets('non-implemented tiles show snackbar', (tester) async {
    await _pumpSettingsPage(
      tester,
      appVersionOverride: (ref) async => '1.1.0+2',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    expect(find.text('Not implemented yet'), findsOneWidget);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Not implemented yet'), findsOneWidget);

    expect(find.text('1.1.0+2'), findsOneWidget);
  });

  testWidgets('theme dropdown updates theme mode provider', (tester) async {
    final container = ProviderContainer(
      overrides: [
        appVersionProvider.overrideWith((ref) async => '1.1.0+2'),
        appPreferencesProvider.overrideWithValue(_FakeAppPreferences()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SettingsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dropdownFinder = find.byWidgetPredicate(
      (widget) => widget is DropdownButton<ThemeMode>,
    );

    expect(container.read(themeModeControllerProvider), ThemeMode.system);

    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    expect(container.read(themeModeControllerProvider), ThemeMode.dark);
    expect(find.text('Dark'), findsNWidgets(2));
  });

  testWidgets('color dropdown updates seed color provider', (tester) async {
    final container = ProviderContainer(
      overrides: [
        appVersionProvider.overrideWith((ref) async => '1.1.0+2'),
        appPreferencesProvider.overrideWithValue(_FakeAppPreferences()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SettingsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final colorDropdownFinder = find.byWidgetPredicate(
      (widget) => widget is DropdownButton<int>,
    );

    expect(container.read(seedColorControllerProvider).toARGB32(), 0xFF00695C);

    await tester.tap(colorDropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('Pink'), findsOneWidget);
    await tester.tap(find.text('Pink').last);
    await tester.pumpAndSettle();

    expect(container.read(seedColorControllerProvider).toARGB32(), 0xFFFF006F);
    expect(find.text('Pink'), findsNWidgets(2));
  });

  testWidgets('About tile shows loading indicator while version loads', (
    tester,
  ) async {
    await _pumpSettingsPage(
      tester,
      appVersionValueOverride: const AsyncLoading<String>(),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(_aboutTile(tester).trailing, isNotNull);
  });

  testWidgets('About tile renders no trailing widget on version error', (
    tester,
  ) async {
    await _pumpSettingsPage(
      tester,
      appVersionValueOverride: AsyncError<String>(
        Exception('boom'),
        StackTrace.empty,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('1.1.0+2'), findsNothing);
    expect(_aboutTile(tester).trailing, isNull);
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
          appVersionProvider.overrideWith((ref) async => '1.1.0+2'),
          authStateChangesProvider.overrideWith((ref) => Stream.value(user)),
          appPreferencesProvider.overrideWithValue(_FakeAppPreferences()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Account').first);
    await tester.pumpAndSettle();

    expect(find.byType(AccountPage), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });
}
