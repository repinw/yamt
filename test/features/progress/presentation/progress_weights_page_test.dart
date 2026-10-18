import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/progress/domain/progress_weight_list.dart';
import 'package:yamt/features/progress/presentation/progress_weights_page.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_weight_health_connect.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_weight_list_summary.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_weight_run_rows.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/progress_source_overrides.dart';
import '../../calories/support/fake_calories_repositories.dart';

const _notConnected = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.notGranted,
  historyAccess: HealthHistoryAccess.notGranted,
);

Future<void> _pump(
  WidgetTester tester, {
  HealthConnectionStatus healthStatus =
      const HealthConnectionStatus.unsupported(),
}) async {
  final settings = FakeCalorieSettingsRepository(
    initialSettings: progressSettings(),
  );
  addTearDown(settings.dispose);
  final calorieLog = FakeCalorieLogRepository();
  addTearDown(calorieLog.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: progressSourceOverrides(
        settingsRepository: settings,
        calorieLog: calorieLog,
        healthStatus: healthStatus,
      ),
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProgressWeightsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the change since the goal start and the weighings', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byKey(ProgressWeightListSummary.summaryKey), findsOneWidget);
    expect(find.text('SEIT ZIELSTART 7. SEPT.'), findsOneWidget);
    expect(find.byType(ProgressWeightRunHeader), findsWidgets);
    expect(find.byType(ProgressWeighingRow), findsWidgets);
    // Health is unsupported, so nothing offers to connect it.
    expect(find.byKey(ProgressWeightHealthCard.cardKey), findsNothing);
    expect(find.byKey(ProgressWeightHealthButton.buttonKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the chips switch the range', (tester) async {
    await _pump(tester);

    await tester.tap(
      find.byKey(ProgressWeightsPage.rangeKey(ProgressWeightRange.fourWeeks)),
    );
    await tester.pumpAndSettle();
    expect(find.text('SEIT 27. AUG.'), findsOneWidget);

    await tester.tap(
      find.byKey(ProgressWeightsPage.rangeKey(ProgressWeightRange.all)),
    );
    await tester.pumpAndSettle();
    expect(find.text('SEIT 7. SEPT.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a dismissed Health card leaves an icon in the header', (
    tester,
  ) async {
    await _pump(tester, healthStatus: _notConnected);

    expect(find.byKey(ProgressWeightHealthCard.cardKey), findsOneWidget);
    expect(find.byKey(ProgressWeightHealthButton.buttonKey), findsNothing);

    await tester.tap(find.byKey(ProgressWeightHealthCard.dismissKey));
    await tester.pumpAndSettle();

    expect(find.byKey(ProgressWeightHealthCard.cardKey), findsNothing);
    expect(find.byKey(ProgressWeightHealthButton.buttonKey), findsOneWidget);
  });
}
