import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/health/application/health_steps_controller.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_steps_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_steps_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/memory_app_preferences.dart';
import '../../../calories/support/fake_calories_repositories.dart';
import '../../../health/support/fake_health_steps_service.dart';

const _ready = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.granted,
);

const _notGranted = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.notGranted,
  historyAccess: HealthHistoryAccess.notApplicable,
);

void main() {
  Future<MemoryAppPreferences> pumpTile(
    WidgetTester tester, {
    FakeHealthConnectionService? connection,
    bool grant = true,
  }) async {
    final preferences = MemoryAppPreferences();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(preferences),
          healthConnectionServiceProvider.overrideWithValue(
            connection ?? FakeHealthConnectionService(_ready),
          ),
          healthStepsServiceProvider.overrideWithValue(
            FakeHealthStepsService(grant: grant),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SettingsStepsTile()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return preferences;
  }

  testWidgets('without Health a tap connects it, then turns the steps on', (
    tester,
  ) async {
    final connection = FakeHealthConnectionService(_notGranted);
    await pumpTile(tester, connection: connection);

    await tester.tap(find.byKey(SettingsPageKeys.stepsTile));
    await tester.pumpAndSettle();

    expect(connection.requestAuthorizationCallCount, 1);
    // The fake keeps its status, so Health stays unconnected.
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.textContaining('Kein Zugriff'), findsOneWidget);
  });

  testWidgets('a device without Health says so', (tester) async {
    await pumpTile(
      tester,
      connection: FakeHealthConnectionService(
        const HealthConnectionStatus.unsupported(),
      ),
    );

    await tester.tap(find.byKey(SettingsPageKeys.stepsTile));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.textContaining('nicht verfügbar'), findsOneWidget);
  });

  testWidgets('a tap turns the steps on and off again', (tester) async {
    final preferences = await pumpTile(tester);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await tester.tap(find.byKey(SettingsPageKeys.stepsTile));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(preferences.getIntSync(healthStepsPreferenceKey), 1);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(preferences.getIntSync(healthStepsPreferenceKey), isNull);
  });

  testWidgets('declined steps keep the switch off and say why', (tester) async {
    await pumpTile(tester, grant: false);

    await tester.tap(find.byKey(SettingsPageKeys.stepsTile));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.textContaining('Kein Zugriff'), findsOneWidget);
  });
}
