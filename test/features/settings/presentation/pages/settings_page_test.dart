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
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/domain/user_profile.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_keys.dart';
import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/data/'
    'health_connection_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/household/presentation/household_page.dart';
import 'package:yamt/features/settings/presentation/pages/account_page.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/memory_app_preferences.dart';
import '../../../calories/support/fake_calories_repositories.dart';

class _MockUser extends Mock implements User {}

class _FakeHealthConnectionService implements HealthConnectionService {
  _FakeHealthConnectionService({
    required this.disconnectResult,
    HealthConnectionStatus? status,
    this.requestAuthorizationResult,
    this.requestHistoryAuthorizationResult,
    this.statusAfterDisconnect,
  }) : _status =
           status ??
           const HealthConnectionStatus(
             platform: HealthPlatform.android,
             healthConnectAvailability: HealthConnectAvailability.available,
             permissionState: HealthPermissionState.granted,
             historyAccess: HealthHistoryAccess.granted,
           );

  final HealthDisconnectResult disconnectResult;
  final HealthConnectionStatus? requestAuthorizationResult;
  final HealthConnectionStatus? requestHistoryAuthorizationResult;
  final HealthConnectionStatus? statusAfterDisconnect;
  HealthConnectionStatus _status;
  int disconnectCallCount = 0;
  int installCallCount = 0;
  int openAppPermissionSettingsCallCount = 0;
  int openHealthPermissionSettingsCallCount = 0;
  int requestAuthorizationCallCount = 0;
  int requestHistoryAuthorizationCallCount = 0;

  @override
  Future<HealthDisconnectResult> disconnect() async {
    disconnectCallCount += 1;
    _status =
        statusAfterDisconnect ??
        HealthConnectionStatus(
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
  Future<void> openAppPermissionSettings() async {
    openAppPermissionSettingsCallCount += 1;
  }

  @override
  Future<void> openHealthPermissionSettings() async {
    openHealthPermissionSettingsCallCount += 1;
  }

  @override
  Future<HealthConnectionStatus> loadStatus() async {
    return _status;
  }

  @override
  Future<HealthConnectionStatus> requestAuthorization() async {
    requestAuthorizationCallCount += 1;
    final result = requestAuthorizationResult;
    if (result != null) {
      _status = result;
      return result;
    }
    return _status;
  }

  @override
  Future<HealthConnectionStatus> requestHistoryAuthorization() async {
    requestHistoryAuthorizationCallCount += 1;
    final result = requestHistoryAuthorizationResult;
    if (result != null) {
      _status = result;
      return result;
    }
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
  Stream<UserProfile?>? userProfile,
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
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(null),
        ),
        if (userProfile != null)
          userProfileProvider.overrideWith((ref) => userProfile),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        healthConnectionServiceProvider.overrideWith(
          (ref) => resolvedHealthService,
        ),
        if (appVersionValueOverride != null)
          appVersionProvider.overrideWithValue(appVersionValueOverride),
        if (appVersionOverride != null)
          appVersionProvider.overrideWith(appVersionOverride),
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

ProviderContainer _createSettingsContainer({
  required CalorieSettingsRepository settingsRepository,
}) {
  return ProviderContainer(
    overrides: [
      appVersionProvider.overrideWith((ref) async => '1.1.0+2'),
      authStateChangesProvider.overrideWith((ref) => Stream<User?>.value(null)),
      appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      healthConnectionServiceProvider.overrideWith(
        (ref) => _FakeHealthConnectionService(
          disconnectResult: HealthDisconnectResult.disconnected,
        ),
      ),
    ],
  );
}

Future<ProviderContainer> _pumpSettingsPageUnderShellOverlay(
  WidgetTester tester, {
  required ValueNotifier<bool> menuCatchesTaps,
  required VoidCallback onMenuTap,
}) async {
  final settingsRepository = FakeCalorieSettingsRepository();
  addTearDown(settingsRepository.dispose);
  final container = _createSettingsContainer(
    settingsRepository: settingsRepository,
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Stack(
            children: [
              Navigator(
                onGenerateRoute: (_) {
                  return MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: SettingsPage()),
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 320,
                child: ValueListenableBuilder<bool>(
                  valueListenable: menuCatchesTaps,
                  builder: (context, catchesTaps, child) {
                    return IgnorePointer(
                      ignoring: !catchesTaps,
                      child: child,
                    );
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onMenuTap,
                    child: const ColoredBox(
                      color: Colors.black54,
                      child: Center(child: Text('Shell bottom menu')),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}

Finder _settingsTile(Key key) => find.byKey(key);

Future<void> _scrollToTile(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(
    _settingsTile(key),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
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

    expect(find.byIcon(Icons.groups_2_outlined), findsOneWidget);
    expect(find.byKey(SettingsPageKeys.profileCard), findsOneWidget);

    expect(_settingsTile(SettingsPageKeys.householdTile), findsOneWidget);
    expect(find.text('Household'), findsNWidgets(2));
    expect(
      find.text('Invite members and manage shared access'),
      findsOneWidget,
    );
    expect(find.text('Account'), findsNothing);
    expect(find.text('Manage profile and sign-in'), findsNothing);
    await _scrollToText(tester, 'Health Connect');
    expect(find.byIcon(Icons.link_off_rounded), findsOneWidget);
    expect(find.text('Health Connect'), findsOneWidget);
    expect(find.text('Remove Health Connect access for YAMT.'), findsOneWidget);
    expect(find.text('Set goal manually'), findsNothing);

    await _scrollToText(tester, 'Theme');
    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('System'), findsNWidgets(2));

    await _scrollToText(tester, 'Accent color');
    expect(find.byIcon(Icons.format_paint_outlined), findsOneWidget);
    expect(find.text('Accent color'), findsOneWidget);
    expect(find.text('Teal'), findsNWidgets(2));

    await _scrollToText(tester, 'Language');
    expect(find.byIcon(Icons.language_rounded), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await _scrollToText(tester, 'Notifications');
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Manage reminders and alerts'), findsOneWidget);

    await _scrollToText(tester, 'About');
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('App version and information'), findsOneWidget);
    expect(find.text('1.1.0+2'), findsOneWidget);
  });

  testWidgets('profile card renders display name and email', (tester) async {
    await _pumpSettingsPage(
      tester,
      appVersionOverride: (ref) async => '1.1.0+2',
      userProfile: Stream.value(
        const UserProfile(
          uid: 'uid-123',
          email: 'jane@example.com',
          displayName: 'Jane Doe',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SettingsPageKeys.profileCard), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('jane@example.com'), findsOneWidget);
  });

  testWidgets('profile card falls back to email as title', (tester) async {
    await _pumpSettingsPage(
      tester,
      appVersionOverride: (ref) async => '1.1.0+2',
      userProfile: Stream.value(
        const UserProfile(uid: 'uid-123', email: 'jane@example.com'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SettingsPageKeys.profileCard), findsOneWidget);
    expect(find.text('jane@example.com'), findsNWidgets(2));
  });

  testWidgets('profile card renders guest mode without profile', (
    tester,
  ) async {
    await _pumpSettingsPage(
      tester,
      appVersionOverride: (ref) async => '1.1.0+2',
      userProfile: Stream<UserProfile?>.value(null),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SettingsPageKeys.profileCard), findsOneWidget);
    expect(find.text('Guest account'), findsOneWidget);
    expect(find.text('Guest mode'), findsOneWidget);
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

    await tester.tap(_settingsTile(SettingsPageKeys.healthConnectTile));
    await tester.pumpAndSettle();

    expect(healthService.requestAuthorizationCallCount, 1);
  });

  testWidgets('health connect tile opens health permission settings', (
    tester,
  ) async {
    final healthService = _FakeHealthConnectionService(
      disconnectResult: HealthDisconnectResult.disconnected,
      status: const HealthConnectionStatus(
        platform: HealthPlatform.android,
        healthConnectAvailability: HealthConnectAvailability.available,
        permissionState: HealthPermissionState.notGranted,
        historyAccess: HealthHistoryAccess.notGranted,
        errorMessage: 'permission denied',
      ),
    );

    await _pumpSettingsPage(
      tester,
      appVersionOverride: (ref) async => '1.1.0+2',
      healthService: healthService,
    );
    await tester.pumpAndSettle();

    await _scrollToText(tester, 'Health Connect');
    await tester.tap(_settingsTile(SettingsPageKeys.healthConnectTile));
    await tester.pumpAndSettle();

    expect(healthService.openHealthPermissionSettingsCallCount, 1);
  });

  testWidgets('health connect tile opens app permission settings', (
    tester,
  ) async {
    final healthService = _FakeHealthConnectionService(
      disconnectResult: HealthDisconnectResult.disconnected,
      status: const HealthConnectionStatus(
        platform: HealthPlatform.android,
        healthConnectAvailability: HealthConnectAvailability.available,
        permissionState: HealthPermissionState.notGranted,
        historyAccess: HealthHistoryAccess.notGranted,
        errorMessage: healthActivityRecognitionPermissionErrorMessage,
      ),
    );

    await _pumpSettingsPage(
      tester,
      appVersionOverride: (ref) async => '1.1.0+2',
      healthService: healthService,
    );
    await tester.pumpAndSettle();

    await _scrollToText(tester, 'Health Connect');
    await tester.tap(_settingsTile(SettingsPageKeys.healthConnectTile));
    await tester.pumpAndSettle();

    expect(healthService.openAppPermissionSettingsCallCount, 1);
  });

  testWidgets('health connect tile shows history prompt', (tester) async {
    final healthService = _FakeHealthConnectionService(
      disconnectResult: HealthDisconnectResult.disconnected,
      status: const HealthConnectionStatus(
        platform: HealthPlatform.android,
        healthConnectAvailability: HealthConnectAvailability.available,
        permissionState: HealthPermissionState.granted,
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
        'Allow older Health Connect history so past diary days can load '
        'activity data.',
      ),
      findsOneWidget,
    );

    await tester.tap(_settingsTile(SettingsPageKeys.healthConnectTile));
    await tester.pumpAndSettle();

    expect(healthService.requestHistoryAuthorizationCallCount, 1);
    expect(find.text('Health access could not be connected.'), findsOneWidget);
  });

  testWidgets('health connect tile accepts history authorization', (
    tester,
  ) async {
    final healthService = _FakeHealthConnectionService(
      disconnectResult: HealthDisconnectResult.disconnected,
      status: const HealthConnectionStatus(
        platform: HealthPlatform.android,
        healthConnectAvailability: HealthConnectAvailability.available,
        permissionState: HealthPermissionState.granted,
        historyAccess: HealthHistoryAccess.notGranted,
      ),
      requestHistoryAuthorizationResult: _connectedHealthStatus(),
    );

    await _pumpSettingsPage(
      tester,
      appVersionOverride: (ref) async => '1.1.0+2',
      healthService: healthService,
    );
    await tester.pumpAndSettle();

    await _scrollToText(tester, 'Health Connect');
    await tester.tap(_settingsTile(SettingsPageKeys.healthConnectTile));
    await tester.pumpAndSettle();

    expect(healthService.requestHistoryAuthorizationCallCount, 1);
    expect(find.text('Health access could not be connected.'), findsNothing);
    expect(find.text('Remove Health Connect access for YAMT.'), findsOneWidget);
  });

  testWidgets('health connect tile handles install-required connect result', (
    tester,
  ) async {
    final healthService = _FakeHealthConnectionService(
      disconnectResult: HealthDisconnectResult.disconnected,
      status: const HealthConnectionStatus(
        platform: HealthPlatform.android,
        healthConnectAvailability: HealthConnectAvailability.available,
        permissionState: HealthPermissionState.notGranted,
        historyAccess: HealthHistoryAccess.notGranted,
      ),
      requestAuthorizationResult: const HealthConnectionStatus(
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
    await tester.tap(_settingsTile(SettingsPageKeys.healthConnectTile));
    await tester.pumpAndSettle();

    expect(find.text('Health access could not be connected.'), findsOneWidget);
  });

  testWidgets('health connect tile handles unsupported connect result', (
    tester,
  ) async {
    final healthService = _FakeHealthConnectionService(
      disconnectResult: HealthDisconnectResult.disconnected,
      status: const HealthConnectionStatus(
        platform: HealthPlatform.android,
        healthConnectAvailability: HealthConnectAvailability.available,
        permissionState: HealthPermissionState.notGranted,
        historyAccess: HealthHistoryAccess.notGranted,
      ),
      requestAuthorizationResult: const HealthConnectionStatus.unsupported(),
    );

    await _pumpSettingsPage(
      tester,
      appVersionOverride: (ref) async => '1.1.0+2',
      healthService: healthService,
    );
    await tester.pumpAndSettle();

    await _scrollToText(tester, 'Health Connect');
    await tester.tap(_settingsTile(SettingsPageKeys.healthConnectTile));
    await tester.pumpAndSettle();

    expect(find.text('Health access could not be connected.'), findsOneWidget);
  });

  testWidgets('health connect tile is disabled when unsupported', (
    tester,
  ) async {
    final healthService = _FakeHealthConnectionService(
      disconnectResult: HealthDisconnectResult.disconnected,
      status: const HealthConnectionStatus.unsupported(),
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
        'Health Connect or Apple Health is not available on this '
        'device.',
      ),
      findsOneWidget,
    );

    await tester.tap(_settingsTile(SettingsPageKeys.healthConnectTile));
    await tester.pumpAndSettle();

    expect(healthService.requestAuthorizationCallCount, 0);
    expect(healthService.installCallCount, 0);
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

    await tester.tap(_settingsTile(SettingsPageKeys.healthConnectTile));
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
    await tester.tap(_settingsTile(SettingsPageKeys.healthConnectTile));
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

  testWidgets('health connect tile can cancel disconnect', (tester) async {
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
    await tester.tap(_settingsTile(SettingsPageKeys.healthConnectTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(healthService.disconnectCallCount, 0);
    expect(find.text('Disconnect health access?'), findsNothing);
  });

  testWidgets('health connect tile reports opened settings disconnect', (
    tester,
  ) async {
    final healthService = _FakeHealthConnectionService(
      disconnectResult: HealthDisconnectResult.openedSettings,
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
    await tester.tap(_settingsTile(SettingsPageKeys.healthConnectTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();

    expect(healthService.disconnectCallCount, 1);
    expect(
      find.text('Opened Settings so you can manage Apple Health access.'),
      findsOneWidget,
    );
  });

  testWidgets('health connect tile reports unsupported disconnect error', (
    tester,
  ) async {
    final healthService = _FakeHealthConnectionService(
      disconnectResult: HealthDisconnectResult.unsupported,
      status: _connectedHealthStatus(),
      statusAfterDisconnect: _connectedHealthStatus().copyWith(
        errorMessage: 'disconnect failed',
      ),
    );

    await _pumpSettingsPage(
      tester,
      appVersionOverride: (ref) async => '1.1.0+2',
      healthService: healthService,
    );
    await tester.pumpAndSettle();

    await _scrollToText(tester, 'Health Connect');
    await tester.tap(_settingsTile(SettingsPageKeys.healthConnectTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();

    expect(healthService.disconnectCallCount, 1);
    expect(
      find.text('Health access could not be disconnected.'),
      findsOneWidget,
    );
  });

  testWidgets('health connect tile reports unsupported disconnect hint', (
    tester,
  ) async {
    final healthService = _FakeHealthConnectionService(
      disconnectResult: HealthDisconnectResult.unsupported,
      status: _connectedHealthStatus(),
    );

    await _pumpSettingsPage(
      tester,
      appVersionOverride: (ref) async => '1.1.0+2',
      healthService: healthService,
    );
    await tester.pumpAndSettle();

    await _scrollToText(tester, 'Health Connect');
    await tester.tap(_settingsTile(SettingsPageKeys.healthConnectTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();

    expect(healthService.disconnectCallCount, 1);
    expect(
      find.text(
        'Health Connect or Apple Health is not available on this device.',
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

    await tester.tap(_settingsTile(SettingsPageKeys.healthConnectTile));
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
          authStateChangesProvider.overrideWith(
            (ref) => Stream<User?>.value(user),
          ),
          appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          healthConnectionServiceProvider.overrideWith(
            (ref) => _FakeHealthConnectionService(
              disconnectResult: HealthDisconnectResult.disconnected,
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    await tester.tap(_settingsTile(SettingsPageKeys.householdTile));
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

    await _scrollToText(tester, 'Language');
    await tester.tap(_settingsTile(SettingsPageKeys.languageTile));
    await tester.pumpAndSettle();
    expect(find.text('Not implemented yet'), findsOneWidget);

    await _scrollToText(tester, 'Notifications');
    await tester.tap(_settingsTile(SettingsPageKeys.notificationsTile));
    await tester.pumpAndSettle();
    expect(find.text('Not implemented yet'), findsOneWidget);

    await _scrollToText(tester, 'Privacy');
    await tester.tap(_settingsTile(SettingsPageKeys.privacyTile));
    await tester.pumpAndSettle();
    expect(find.text('Not implemented yet'), findsOneWidget);

    await _scrollToText(tester, 'About');
    expect(find.text('1.1.0+2'), findsOneWidget);
  });

  testWidgets('theme sheet updates theme mode provider', (tester) async {
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(settingsRepository.dispose);
    final container = _createSettingsContainer(
      settingsRepository: settingsRepository,
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

    expect(container.read(themeModeControllerProvider), ThemeMode.system);

    await _scrollToTile(tester, SettingsPageKeys.themeTile);
    await tester.tap(_settingsTile(SettingsPageKeys.themeTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    expect(container.read(themeModeControllerProvider), ThemeMode.dark);
    expect(find.text('Dark'), findsNWidgets(2));
  });

  testWidgets('color sheet updates seed color provider', (tester) async {
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(settingsRepository.dispose);
    final container = _createSettingsContainer(
      settingsRepository: settingsRepository,
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

    expect(container.read(seedColorControllerProvider).toARGB32(), 0xFF00695C);

    await _scrollToText(tester, 'Accent color');
    await tester.tap(_settingsTile(SettingsPageKeys.colorTile));
    await tester.pumpAndSettle();
    expect(find.text('Pink'), findsOneWidget);
    await tester.tap(find.text('Pink').last);
    await tester.pumpAndSettle();

    expect(container.read(seedColorControllerProvider).toARGB32(), 0xFFFF006F);
    expect(find.text('Pink'), findsNWidgets(2));
  });

  testWidgets('settings bottom sheets open above shell bottom menu', (
    tester,
  ) async {
    final menuCatchesTaps = ValueNotifier<bool>(false);
    addTearDown(menuCatchesTaps.dispose);
    var menuTapCount = 0;
    final container = await _pumpSettingsPageUnderShellOverlay(
      tester,
      menuCatchesTaps: menuCatchesTaps,
      onMenuTap: () => menuTapCount += 1,
    );

    await _scrollToText(tester, 'Accent color');
    await tester.tap(_settingsTile(SettingsPageKeys.colorTile));
    await tester.pumpAndSettle();
    menuCatchesTaps.value = true;
    await tester.pump();

    await tester.tap(find.text('Pink').last);
    await tester.pumpAndSettle();

    expect(menuTapCount, 0);
    expect(container.read(seedColorControllerProvider).toARGB32(), 0xFFFF006F);
  });

  testWidgets('calculator bottom sheet opens above shell bottom menu', (
    tester,
  ) async {
    final menuCatchesTaps = ValueNotifier<bool>(false);
    addTearDown(menuCatchesTaps.dispose);
    var menuTapCount = 0;
    await _pumpSettingsPageUnderShellOverlay(
      tester,
      menuCatchesTaps: menuCatchesTaps,
      onMenuTap: () => menuTapCount += 1,
    );

    await _scrollToTile(tester, SettingsPageKeys.calorieGoalCalculatorTile);
    await tester.tap(_settingsTile(SettingsPageKeys.calorieGoalCalculatorTile));
    await tester.pumpAndSettle();
    menuCatchesTaps.value = true;
    await tester.pump();

    await tester.tap(find.byKey(CalorieGoalCalculatorSheetKeys.nextButton));
    await tester.pumpAndSettle();

    expect(menuTapCount, 0);
    expect(
      find.byKey(CalorieGoalCalculatorSheetKeys.weightField),
      findsOneWidget,
    );
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
    expect(find.byKey(SettingsPageKeys.aboutTrailing), findsOneWidget);
    expect(find.text('1.1.0+2'), findsNothing);
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
    expect(find.byKey(SettingsPageKeys.aboutTrailing), findsNothing);
    expect(find.text('1.1.0+2'), findsNothing);
    expect(find.text('App version and information'), findsOneWidget);
  });

  testWidgets('Profile card opens AccountPage', (tester) async {
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
          authStateChangesProvider.overrideWith(
            (ref) => Stream<User?>.value(user),
          ),
          appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          healthConnectionServiceProvider.overrideWith(
            (ref) => _FakeHealthConnectionService(
              disconnectResult: HealthDisconnectResult.disconnected,
            ),
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

    await tester.tap(find.byKey(SettingsPageKeys.profileCard));
    await tester.pumpAndSettle();

    expect(find.byType(AccountPage), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });
}
