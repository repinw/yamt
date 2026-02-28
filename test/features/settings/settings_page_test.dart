import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/config/ai_processing_level.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/seed_color_controller.dart';
import 'package:yamt/core/theme/theme_mode_controller.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/settings/provider/ai_processing_level_controller.dart';
import 'package:yamt/features/settings/account_page.dart';
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

void main() {
  testWidgets('SettingsPage renders localized rows', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(_FakeAppPreferences()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SettingsPage()),
        ),
      ),
    );

    expect(find.byIcon(Icons.language_outlined), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    expect(find.byIcon(Icons.format_paint_outlined), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsNWidgets(2));

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Choose app language'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('System'), findsNWidgets(2));
    expect(find.text('Accent color'), findsOneWidget);
    expect(find.text('Lime'), findsNWidgets(2));
    expect(find.text('AI processing'), findsOneWidget);
    expect(find.text('Control OCR and analysis intensity'), findsOneWidget);
    expect(find.text('Balanced'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Manage reminders and alerts'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Manage profile and sign-in'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('App version and information'), findsOneWidget);
  });

  testWidgets('non-implemented tiles show snackbar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(_FakeAppPreferences()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SettingsPage()),
        ),
      ),
    );

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    expect(find.text('Not implemented yet'), findsOneWidget);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Not implemented yet'), findsOneWidget);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('Not implemented yet'), findsOneWidget);
  });

  testWidgets('theme dropdown updates theme mode provider', (tester) async {
    final container = ProviderContainer(
      overrides: [
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

    final colorDropdownFinder = find.byWidgetPredicate(
      (widget) => widget is DropdownButton<int>,
    );

    expect(container.read(seedColorControllerProvider).toARGB32(), 0xFF29F006);

    await tester.tap(colorDropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('Pink'), findsOneWidget);
    await tester.tap(find.text('Teal').last);
    await tester.pumpAndSettle();

    expect(container.read(seedColorControllerProvider).toARGB32(), 0xFF00695C);
    expect(find.text('Teal'), findsNWidgets(2));
  });

  testWidgets('AI processing dropdown updates provider', (tester) async {
    final container = ProviderContainer(
      overrides: [
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

    final processingDropdownFinder = find.byWidgetPredicate(
      (widget) => widget is DropdownButton<AiProcessingLevel>,
    );

    expect(
      container.read(aiProcessingLevelControllerProvider),
      AiProcessingLevel.balanced,
    );

    await tester.tap(processingDropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('Minimal'), findsOneWidget);
    await tester.tap(find.text('High').last);
    await tester.pumpAndSettle();

    expect(
      container.read(aiProcessingLevelControllerProvider),
      AiProcessingLevel.high,
    );
    expect(find.text('High'), findsOneWidget);
  });

  testWidgets('AI processing info icon opens disclaimer dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(_FakeAppPreferences()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SettingsPage()),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Processing level info'));
    await tester.pumpAndSettle();

    expect(find.text('Processing level'), findsOneWidget);
    expect(
      find.text('Speed and result quality depend on the selected level.'),
      findsOneWidget,
    );
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
          appPreferencesProvider.overrideWithValue(_FakeAppPreferences()),
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
