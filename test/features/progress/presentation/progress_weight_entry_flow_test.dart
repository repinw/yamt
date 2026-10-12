import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/'
    'diary_weight_dialog_keys.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/presentation/progress_page.dart';
import 'package:yamt/features/progress/presentation/progress_weight_entry_flow.dart';
import 'package:yamt/features/progress/presentation/widgets/'
    'progress_scope_switch.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/memory_app_preferences.dart';
import '../../../helpers/progress_source_overrides.dart';
import '../../calories/support/fake_calories_repositories.dart';

const _openKey = ValueKey<String>('progress-weight-entry-test-open');

/// Pumps [body] with a button that opens the weight entry.
Future<void> _pump(
  WidgetTester tester, {
  required List<Override> overrides,
  Widget? body,
}) async {
  tester.view.physicalSize = const Size(1080, 6000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: body,
          floatingActionButton: Builder(
            builder: (context) => FloatingActionButton(
              key: _openKey,
              onPressed: () => showProgressWeightEntry(context),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('saves the weight of today while nothing else watches it', (
    tester,
  ) async {
    final settings = FakeCalorieSettingsRepository(
      initialSettings: progressSettings(),
    );
    addTearDown(settings.dispose);
    final weights = FakeManualHealthWeightRepository([]);
    // No page watches the weights, so only the flow keeps the weight
    // controller alive until the save is done.
    await _pump(
      tester,
      overrides: [
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
        calorieSettingsRepositoryProvider.overrideWithValue(settings),
        clockProvider.overrideWithValue(() => progressNow),
        healthConnectionServiceProvider.overrideWith(
          (ref) => FakeHealthConnectionService(
            const HealthConnectionStatus.unsupported(),
          ),
        ),
        healthWeightServiceProvider.overrideWith(
          (ref) => FakeHealthWeightService(const []),
        ),
        manualHealthWeightRepositoryProvider.overrideWithValue(weights),
      ],
    );

    await tester.tap(find.byKey(_openKey));
    await tester.pumpAndSettle();
    expect(find.text('Set weight for Sep 24, 2026'), findsOneWidget);
    await tester.enterText(
      find.byKey(DiaryWeightDialogKeys.weightDialogField),
      '80.4',
    );
    await tester.tap(find.byKey(DiaryWeightDialogKeys.weightDialogSaveButton));
    await tester.pumpAndSettle();

    expect(find.byKey(DiaryWeightDialogKeys.weightDialogField), findsNothing);
    expect(
      [for (final entry in weights.entries) (entry.day, entry.weightKg)],
      [(DateTime(2026, 9, 24), 80.4)],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('fills in the last weigh-in of the chart on Gesamt', (
    tester,
  ) async {
    final settings = FakeCalorieSettingsRepository(
      initialSettings: progressSettings(),
    );
    addTearDown(settings.dispose);
    final calorieLog = FakeCalorieLogRepository(
      initialEntries: progressEntries(),
    );
    addTearDown(calorieLog.dispose);
    await _pump(
      tester,
      overrides: progressSourceOverrides(
        settingsRepository: settings,
        calorieLog: calorieLog,
      ),
      body: const ProgressPage(),
    );
    await tester.tap(
      find.byKey(ProgressScopeSwitch.chipKey(ProgressScope.all)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_openKey));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(DiaryWeightDialogKeys.weightDialogField),
    );
    expect(field.controller!.text, '82.0');
  });

  testWidgets('waits for the chart weights when no chart is built', (
    tester,
  ) async {
    final settings = FakeCalorieSettingsRepository(
      initialSettings: progressSettings(),
    );
    addTearDown(settings.dispose);
    final calorieLog = FakeCalorieLogRepository(
      initialEntries: progressEntries(),
    );
    addTearDown(calorieLog.dispose);
    await _pump(
      tester,
      overrides: progressSourceOverrides(
        settingsRepository: settings,
        calorieLog: calorieLog,
      ),
    );

    await tester.tap(find.byKey(_openKey));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(DiaryWeightDialogKeys.weightDialogField),
    );
    expect(field.controller!.text, '82.0');
  });
}
