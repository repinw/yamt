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
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/health_connection_service_provider.dart';
import 'package:yamt/features/household/presentation/household_page.dart';
import 'package:yamt/features/settings/account_page.dart';
import 'package:yamt/features/settings/settings_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../calories/support/fake_calories_repositories.dart';

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

class _FakeHealthConnectionService implements HealthConnectionService {
  _FakeHealthConnectionService({
    required this.disconnectResult,
    HealthConnectionStatus? status,
  }) : _status =
           status ??
           const HealthConnectionStatus(
             platform: HealthPlatform.android,
             healthConnectAvailability: HealthConnectAvailability.available,
             permissionState: HealthPermissionState.granted,
             historyAccess: HealthHistoryAccess.granted,
           );

  final HealthDisconnectResult disconnectResult;
  HealthConnectionStatus _status;
  int disconnectCallCount = 0;
  int installCallCount = 0;
  int requestAuthorizationCallCount = 0;
  int requestHistoryAuthorizationCallCount = 0;

  @override
  Future<HealthDisconnectResult> disconnect() async {
    disconnectCallCount += 1;
    _status = HealthConnectionStatus(
      platform: _status.platform,
      healthConnectAvailability: _status.healthConnectAvailability,
      permissionState: HealthPermissionState.notGranted,
      historyAccess: _status.platform == HealthPlatform.android
          ? HealthHistoryAccess.notGranted
          : HealthHistoryAccess.notApplicable,
    );
    return disconnectResult;
  }

  @override
  Future<void> installHealthConnect() async {
    installCallCount += 1;
  }

  @override
  Future<HealthConnectionStatus> loadStatus() async {
    return _status;
  }

  @override
  Future<HealthConnectionStatus> requestAuthorization() async {
    requestAuthorizationCallCount += 1;
    return _status;
  }

  @override
  Future<HealthConnectionStatus> requestHistoryAuthorization() async {
    requestHistoryAuthorizationCallCount += 1;
    return _status;
  }
}

HealthConnectionStatus _connectedHealthStatus() {
  return const HealthConnectionStatus(
    platform: HealthPlatform.android,
    healthConnectAvailability: HealthConnectAvailability.available,
    permissionState: HealthPermissionState.granted,
    historyAccess: HealthHistoryAccess.granted,
  );
}

Future<FakeCalorieSettingsRepository> _pumpSettingsPage(
  WidgetTester tester, {
  FutureOr<String> Function(Ref ref)? appVersionOverride,
  AsyncValue<String>? appVersionValueOverride,
  CalorieGoalSettings? calorieSettings,
  _FakeHealthConnectionService? healthService,
  List<dynamic> extraOverrides = const <dynamic>[],
}) async {
  final settingsRepository = FakeCalorieSettingsRepository(
    initialSettings: calorieSettings,
  );
  addTearDown(settingsRepository.dispose);
  final resolvedHealthService =
      healthService ??
      _FakeHealthConnectionService(
        disconnectResult: HealthDisconnectResult.disconnected,
      );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appPreferencesProvider.overrideWithValue(_FakeAppPreferences()),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        healthConnectionServiceProvider.overrideWith(
          (ref) => resolvedHealthService,
        ),
        if (appVersionValueOverride != null)
          appVersionProvider.overrideWithValue(appVersionValueOverride),
        if (appVersionOverride != null)
          appVersionProvider.overrideWith(appVersionOverride),
        ...extraOverrides.cast(),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SettingsPage()),
      ),
    ),
  );

  return settingsRepository;
}

ListTile _aboutTile(WidgetTester tester) {
  final finder = find.ancestor(
    of: find.text('About'),
    matching: find.byType(ListTile),
  );
  return tester.widget<ListTile>(finder.first);
}

Future<void> _scrollToText(
  WidgetTester tester,
  String text, {
  bool settle = true,
}) async {
  await tester.scrollUntilVisible(
    find.text(text),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  testWidgets('SettingsPage renders localized rows', (tester) async {
    await _pumpSettingsPage(
      tester,
      appVersionOverride: (ref) async => '1.1.0+2',
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.language_outlined), findsOneWidget);
    expect(find.byIcon(Icons.group_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    expect(find.byIcon(Icons.format_paint_outlined), findsOneWidget);

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
    await _scrollToText(tester, 'Health Connect');
    expect(find.byIcon(Icons.link_off), findsOneWidget);
    expect(find.text('Health Connect'), findsOneWidget);
    expect(find.text('Remove Health Connect access for YAMT.'), findsOneWidget);

    await _scrollToText(tester, 'Notifications');
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Manage reminders and alerts'), findsOneWidget);

    await _scrollToText(tester, 'About');
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('App version and information'), findsOneWidget);
    expect(find.text('1.1.0+2'), findsOneWidget);
  });

  testWidgets(
    'SettingsPage stays scrollable on compact display-size layouts',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpSettingsPage(
        tester,
        appVersionOverride: (ref) async => '1.1.0+2',
      );
      await tester.pumpAndSettle();

      await _scrollToText(tester, 'About');

      expect(find.text('About'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('health connect tile requests authorization', (tester) async {
    final healthService = _FakeHealthConnectionService(
      disconnectResult: HealthDisconnectResult.disconnected,
      status: const HealthConnectionStatus(
        platform: HealthPlatform.android,
        healthConnectAvailability: HealthConnectAvailability.available,
        permissionState: HealthPermissionState.notGranted,
        historyAccess: HealthHistoryAccess.notGranted,
      ),
    );

    await _pumpSettingsPage(
      tester,
      appVersionOverride: (ref) async => '1.1.0+2',
      healthService: healthService,
    );
    await tester.pumpAndSettle();

    await _scrollToText(tester, 'Health Connect');
    expect(
      find.text(
        'Allow YAMT to read steps, workouts, and burned calories from '
        'Health Connect.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Health Connect').first);
    await tester.pumpAndSettle();

    expect(healthService.requestAuthorizationCallCount, 1);
  });

  testWidgets('health connect tile installs provider when unavailable', (
    tester,
  ) async {
    final healthService = _FakeHealthConnectionService(
      disconnectResult: HealthDisconnectResult.disconnected,
      status: const HealthConnectionStatus(
        platform: HealthPlatform.android,
        healthConnectAvailability: HealthConnectAvailability.notInstalled,
        permissionState: HealthPermissionState.notGranted,
        historyAccess: HealthHistoryAccess.notApplicable,
      ),
    );

    await _pumpSettingsPage(
      tester,
      appVersionOverride: (ref) async => '1.1.0+2',
      healthService: healthService,
    );
    await tester.pumpAndSettle();

    await _scrollToText(tester, 'Health Connect');
    expect(
      find.text(
        'Install Health Connect before you can connect health data here.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Health Connect').first);
    await tester.pumpAndSettle();

    expect(healthService.installCallCount, 1);
  });

  testWidgets('health connect tile confirms and disconnects', (tester) async {
    final healthService = _FakeHealthConnectionService(
      disconnectResult: HealthDisconnectResult.disconnected,
      status: _connectedHealthStatus(),
    );

    await _pumpSettingsPage(
      tester,
      appVersionOverride: (ref) async => '1.1.0+2',
      healthService: healthService,
    );
    await tester.pumpAndSettle();

    await _scrollToText(tester, 'Health Connect');
    await tester.tap(find.text('Health Connect').first);
    await tester.pumpAndSettle();

    expect(find.text('Disconnect health access?'), findsOneWidget);

    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();

    expect(healthService.disconnectCallCount, 1);
    expect(
      find.text(
        'Health access disconnected. Restart YAMT before reconnecting '
        'Health Connect.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Apple Health tile disconnects locally on iPhone', (
    tester,
  ) async {
    final healthService = _FakeHealthConnectionService(
      disconnectResult: HealthDisconnectResult.disconnected,
      status: const HealthConnectionStatus(
        platform: HealthPlatform.ios,
        healthConnectAvailability: HealthConnectAvailability.notApplicable,
        permissionState: HealthPermissionState.granted,
        historyAccess: HealthHistoryAccess.notApplicable,
      ),
    );

    await _pumpSettingsPage(
      tester,
      appVersionOverride: (ref) async => '1.1.0+2',
      healthService: healthService,
    );
    await tester.pumpAndSettle();

    await _scrollToText(tester, 'Apple Health');
    expect(
      find.text('Stop using Apple Health in YAMT.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Apple Health').first);
    await tester.pumpAndSettle();

    expect(find.text('Disconnect health access?'), findsOneWidget);
    expect(
      find.text(
        'YAMT will stop using Apple Health data until you connect it again. '
        'Apple Health permissions on your iPhone stay unchanged.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();

    expect(healthService.disconnectCallCount, 1);
    expect(
      find.text(
        'Apple Health disconnected in YAMT. You can reconnect it anytime '
        'from Settings.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Household tile opens HouseholdPage', (tester) async {
    final user = _MockUser();
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(settingsRepository.dispose);
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
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
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

    await _scrollToText(tester, 'Notifications');
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Not implemented yet'), findsOneWidget);

    await _scrollToText(tester, 'About');
    expect(find.text('1.1.0+2'), findsOneWidget);
  });

  testWidgets('theme dropdown updates theme mode provider', (tester) async {
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(settingsRepository.dispose);
    final container = ProviderContainer(
      overrides: [
        appVersionProvider.overrideWith((ref) async => '1.1.0+2'),
        appPreferencesProvider.overrideWithValue(_FakeAppPreferences()),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
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
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(settingsRepository.dispose);
    final container = ProviderContainer(
      overrides: [
        appVersionProvider.overrideWith((ref) async => '1.1.0+2'),
        appPreferencesProvider.overrideWithValue(_FakeAppPreferences()),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
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

    await _scrollToText(tester, 'About', settle: false);
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

    await _scrollToText(tester, 'About');
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('1.1.0+2'), findsNothing);
    expect(_aboutTile(tester).trailing, isNull);
  });

  testWidgets('Account tile opens AccountPage', (tester) async {
    final user = _MockUser();
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(settingsRepository.dispose);
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
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
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
