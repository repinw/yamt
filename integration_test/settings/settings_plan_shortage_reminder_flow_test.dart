import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/core/theme/app_accent_controller.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/app_theme_mode_controller.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/health/data/'
    'health_connection_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/helpers/fake_local_notifications.dart';
import '../../test/helpers/memory_app_preferences.dart';

/// Opens the settings page in an app themed like `lib/app.dart`.
Future<MemoryAppPreferences> _pumpSettings(
  WidgetTester tester,
  FakeLocalNotifications notifications, {
  Map<String, String>? preferenceStrings,
}) async {
  final preferences = MemoryAppPreferences(initialStrings: preferenceStrings);
  final settingsRepository = FakeCalorieSettingsRepository();
  addTearDown(settingsRepository.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appPreferencesProvider.overrideWithValue(preferences),
        localNotificationsProvider.overrideWithValue(notifications),
        authStateChangesProvider.overrideWithValue(
          const AsyncData<User?>(null),
        ),
        appVersionProvider.overrideWithValue(const AsyncData('3.5.0+37')),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        healthConnectionServiceProvider.overrideWithValue(
          FakeHealthConnectionService(
            const HealthConnectionStatus(
              platform: HealthPlatform.android,
              healthConnectAvailability: HealthConnectAvailability.available,
              permissionState: HealthPermissionState.notGranted,
              historyAccess: HealthHistoryAccess.notGranted,
            ),
          ),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final accent = ref.watch(appAccentControllerProvider);
          return MaterialApp(
            theme: AppTheme.light(accent: accent),
            darkTheme: AppTheme.dark(accent: accent),
            themeMode: ref.watch(appThemeModeControllerProvider),
            locale: const Locale('de'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SettingsPage()),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return preferences;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the reminder switch turns the reminder off and on again', (
    tester,
  ) async {
    final notifications = FakeLocalNotifications();
    final preferences = await _pumpSettings(tester, notifications);
    final tile = find.descendant(
      of: find.byKey(SettingsPageKeys.planShortageReminderTile),
      matching: find.byType(Switch),
    );
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(preferences.getStringSync('plan_shortage_reminder_off_v1'), 'set');

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(preferences.getStringSync('plan_shortage_reminder_off_v1'), isNull);
    // Turning it on asks for the permission the user may have denied.
    expect(notifications.permissionRequests, 1);
    expect(
      find.byKey(SettingsPageKeys.planShortageReminderTimeTile),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a blocked reminder leads to the system settings and clears '
      'on return', (tester) async {
    final notifications = FakeLocalNotifications()..allowed = false;
    await _pumpSettings(
      tester,
      notifications,
      preferenceStrings: {'plan_shortage_reminder_permission_asked_v1': 'set'},
    );
    final tile = find.byKey(SettingsPageKeys.planShortageReminderTile);
    final blocked = lookupAppLocalizations(const Locale('de'))
        .settingsPlanShortageReminderBlocked;
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: tile, matching: find.text(blocked)),
      findsOneWidget,
    );

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(notifications.settingsOpened, 1);

    // The user allows them in the system settings and comes back.
    notifications.allowed = true;
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: tile, matching: find.text(blocked)),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
