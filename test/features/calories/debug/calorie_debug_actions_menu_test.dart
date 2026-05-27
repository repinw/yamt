import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/debug/calorie_debug_actions_menu.dart';
import 'package:yamt/features/calories/debug/calorie_debug_file_exporter.dart';
import 'package:yamt/features/calories/debug/calorie_debug_keys.dart';
import 'package:yamt/features/health/data/diary_health_service_provider.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/'
    'manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/root_navigator_test_utils.dart';
import '../support/fake_calories_repositories.dart';

void main() {
  testWidgets('opens debug menu on root navigator from nested navigator', (
    tester,
  ) async {
    final rootObserver = RecordingNavigatorObserver();
    final nestedObserver = RecordingNavigatorObserver();

    await _pumpNestedDebugMenu(
      tester,
      rootObserver: rootObserver,
      nestedObserver: nestedObserver,
    );

    rootObserver.clear();
    nestedObserver.clear();
    await tester.tap(find.byKey(CalorieDebugKeys.actionsMenuButton));
    await tester.pumpAndSettle();

    expectRootPopupRoutePushed(
      rootObserver: rootObserver,
      nestedObserver: nestedObserver,
    );
    expect(find.byKey(CalorieDebugKeys.debugDumpButton), findsOneWidget);
  });

  testWidgets('opens app bar debug menu and downloads calorie dump', (
    tester,
  ) async {
    await _pumpDebugMenu(tester);

    await tester.tap(
      find.byKey(CalorieDebugKeys.actionsMenuButton),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CalorieDebugKeys.debugDumpButton), findsOneWidget);
    expect(
      find.byKey(CalorieDebugKeys.settingsDebugDumpButton),
      findsOneWidget,
    );
    expect(
      find.byKey(CalorieDebugKeys.weeklyCheckInDebugDumpButton),
      findsOneWidget,
    );

    await tester.tap(find.byKey(CalorieDebugKeys.debugDumpButton));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Downloaded calorie debug TXT'),
      findsOneWidget,
    );
  });

  testWidgets('debug menu shows failure snackbar when dump fails', (
    tester,
  ) async {
    final logRepository = FakeCalorieLogRepository()
      ..onReadEntriesInRange = (_, _) async {
        throw StateError('debug dump failed');
      };

    await _pumpDebugMenu(tester, logRepository: logRepository);

    await tester.tap(
      find.byKey(CalorieDebugKeys.actionsMenuButton),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CalorieDebugKeys.debugDumpButton));
    await tester.pumpAndSettle();

    expect(find.text('Could not download calorie debug TXT.'), findsOneWidget);
  });

  testWidgets('debug menu prints settings and weekly check-in dumps', (
    tester,
  ) async {
    await _pumpDebugMenu(tester);

    await _selectDebugAction(
      tester,
      CalorieDebugKeys.settingsDebugDumpButton,
    );

    expect(
      find.text('Printed calorie settings debug dump (0 goal entries).'),
      findsOneWidget,
    );

    await _selectDebugAction(
      tester,
      CalorieDebugKeys.weeklyCheckInDebugDumpButton,
    );

    expect(
      find.text('Printed weekly check-in debug dump.'),
      findsOneWidget,
    );
  });
}

Future<void> _selectDebugAction(WidgetTester tester, Key actionKey) async {
  await tester.tap(
    find.byKey(CalorieDebugKeys.actionsMenuButton),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(actionKey));
  await tester.pumpAndSettle();
}

Future<void> _pumpDebugMenu(
  WidgetTester tester, {
  FakeCalorieLogRepository? logRepository,
  FakeCalorieSettingsRepository? settingsRepository,
}) async {
  final resolvedLogRepository = logRepository ?? FakeCalorieLogRepository();
  final resolvedSettingsRepository =
      settingsRepository ?? FakeCalorieSettingsRepository();
  addTearDown(() async {
    await resolvedLogRepository.dispose();
    await resolvedSettingsRepository.dispose();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(resolvedLogRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(
          resolvedSettingsRepository,
        ),
        diaryHealthServiceProvider.overrideWithValue(
          FakeDiaryHealthService({}),
        ),
        healthConnectionServiceProvider.overrideWithValue(
          FakeHealthConnectionService(
            const HealthConnectionStatus.unsupported(),
          ),
        ),
        healthWeightServiceProvider.overrideWithValue(
          FakeHealthWeightService([]),
        ),
        calorieDebugFileExporterProvider.overrideWithValue(
          const _FakeCalorieDebugFileExporter(),
        ),
        manualHealthWeightRepositoryProvider.overrideWithValue(
          FakeManualHealthWeightRepository([]),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(
            actions: const [
              CalorieDebugActionsMenu(),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpNestedDebugMenu(
  WidgetTester tester, {
  required RecordingNavigatorObserver rootObserver,
  required RecordingNavigatorObserver nestedObserver,
}) async {
  final logRepository = FakeCalorieLogRepository();
  final settingsRepository = FakeCalorieSettingsRepository();
  addTearDown(() async {
    await logRepository.dispose();
    await settingsRepository.dispose();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        diaryHealthServiceProvider.overrideWithValue(
          FakeDiaryHealthService({}),
        ),
        healthConnectionServiceProvider.overrideWithValue(
          FakeHealthConnectionService(
            const HealthConnectionStatus.unsupported(),
          ),
        ),
        healthWeightServiceProvider.overrideWithValue(
          FakeHealthWeightService([]),
        ),
        calorieDebugFileExporterProvider.overrideWithValue(
          const _FakeCalorieDebugFileExporter(),
        ),
        manualHealthWeightRepositoryProvider.overrideWithValue(
          FakeManualHealthWeightRepository([]),
        ),
      ],
      child: nestedNavigatorHarness(
        rootObserver: rootObserver,
        nestedObserver: nestedObserver,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        child: Scaffold(
          appBar: AppBar(
            actions: const [
              CalorieDebugActionsMenu(),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeCalorieDebugFileExporter implements CalorieDebugFileExporter {
  const _FakeCalorieDebugFileExporter();

  @override
  Future<CalorieDebugFileExportResult> saveText({
    required String fileName,
    required String text,
  }) async {
    return const CalorieDebugFileExportSaved(
      path: '/tmp/yamt_diary_debug.txt',
    );
  }
}
