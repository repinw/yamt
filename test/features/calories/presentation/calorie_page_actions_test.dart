import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/presentation/calorie_page_actions.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_service_provider.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_repository_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../support/fake_calories_repositories.dart';

void main() {
  testWidgets(
    'printCalorieDebugDumpFromPage shows success snackbar',
    (tester) async {
      final logRepository = FakeCalorieLogRepository();
      final settingsRepository = FakeCalorieSettingsRepository();
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);
      final harness = await _pumpActionHarness(
        tester,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      );

      await printCalorieDebugDumpFromPage(
        context: harness.context,
        ref: harness.ref,
        now: DateTime(2026, 2, 25, 12),
      );
      await tester.pump();

      expect(
        find.textContaining('Printed calorie debug table'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'printCalorieDebugDumpFromPage shows error snackbar',
    (tester) async {
      final logRepository = FakeCalorieLogRepository()
        ..onReadEntriesInRange = (_, _) async {
          throw StateError('debug dump failed');
        };
      final settingsRepository = FakeCalorieSettingsRepository();
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);
      final harness = await _pumpActionHarness(
        tester,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      );

      await printCalorieDebugDumpFromPage(
        context: harness.context,
        ref: harness.ref,
        now: DateTime(2026, 2, 25, 12),
      );
      await tester.pump();

      expect(
        find.text('Could not print calorie debug table.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'toggleSkippedCalorieIntakeDay stays quiet after successful save',
    (tester) async {
      final logRepository = FakeCalorieLogRepository();
      final settingsRepository = FakeCalorieSettingsRepository();
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);
      final harness = await _pumpActionHarness(
        tester,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      );

      await toggleSkippedCalorieIntakeDay(
        context: harness.context,
        ref: harness.ref,
        selectedDay: DateTime(2026, 2, 25),
        isSkipped: true,
      );
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets(
    'toggleSkippedCalorieIntakeDay shows error snackbar after failed save',
    (tester) async {
      final logRepository = FakeCalorieLogRepository();
      final settingsRepository = FakeCalorieSettingsRepository()
        ..saveShouldFail = true;
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);
      final harness = await _pumpActionHarness(
        tester,
        logRepository: logRepository,
        settingsRepository: settingsRepository,
      );

      await toggleSkippedCalorieIntakeDay(
        context: harness.context,
        ref: harness.ref,
        selectedDay: DateTime(2026, 2, 25),
        isSkipped: true,
      );
      await tester.pump();

      expect(find.text('Could not save calorie goal.'), findsOneWidget);
    },
  );
}

Future<({BuildContext context, WidgetRef ref})> _pumpActionHarness(
  WidgetTester tester, {
  required FakeCalorieLogRepository logRepository,
  required FakeCalorieSettingsRepository settingsRepository,
}) async {
  late BuildContext capturedContext;
  late WidgetRef capturedRef;
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
        manualHealthWeightRepositoryProvider.overrideWithValue(
          FakeManualHealthWeightRepository([]),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, child) {
              capturedContext = context;
              capturedRef = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return (context: capturedContext, ref: capturedRef);
}
