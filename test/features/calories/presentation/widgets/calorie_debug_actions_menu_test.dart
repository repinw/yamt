import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_debug_actions_menu.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_service_provider.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_repository_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../support/fake_calories_repositories.dart';

void main() {
  testWidgets('opens app bar debug menu and prints calorie dump', (
    tester,
  ) async {
    await _pumpDebugMenu(tester);

    await tester.tap(
      find.byKey(CaloriesPageKeys.calorieDebugActionsMenuButton),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CaloriesPageKeys.calorieDebugDumpButton), findsOneWidget);
    expect(
      find.byKey(CaloriesPageKeys.calorieSettingsDebugDumpButton),
      findsOneWidget,
    );
    expect(
      find.byKey(CaloriesPageKeys.calorieWeeklyCheckInDebugDumpButton),
      findsOneWidget,
    );

    await tester.tap(find.byKey(CaloriesPageKeys.calorieDebugDumpButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('Printed calorie debug table'), findsOneWidget);
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
      find.byKey(CaloriesPageKeys.calorieDebugActionsMenuButton),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CaloriesPageKeys.calorieDebugDumpButton));
    await tester.pumpAndSettle();

    expect(find.text('Could not print calorie debug table.'), findsOneWidget);
  });

  testWidgets('debug menu prints settings and weekly check-in dumps', (
    tester,
  ) async {
    await _pumpDebugMenu(tester);

    await _selectDebugAction(
      tester,
      CaloriesPageKeys.calorieSettingsDebugDumpButton,
    );

    expect(
      find.text('Printed calorie settings debug dump (0 goal entries).'),
      findsOneWidget,
    );

    await _selectDebugAction(
      tester,
      CaloriesPageKeys.calorieWeeklyCheckInDebugDumpButton,
    );

    expect(
      find.text('Printed weekly check-in debug dump.'),
      findsOneWidget,
    );
  });
}

Future<void> _selectDebugAction(WidgetTester tester, Key actionKey) async {
  await tester.tap(
    find.byKey(CaloriesPageKeys.calorieDebugActionsMenuButton),
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
