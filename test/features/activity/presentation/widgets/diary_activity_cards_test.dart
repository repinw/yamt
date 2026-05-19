import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/activity/application/diary_activity_weight_data_provider.dart';
import 'package:yamt/features/activity/application/diary_steps_summary_provider.dart';
import 'package:yamt/features/activity/application/diary_weight_actions.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
import 'package:yamt/features/activity/presentation/widgets/activity_weight_section/diary_activity_weight_section.dart';
import 'package:yamt/features/activity/presentation/widgets/activity_weight_section/diary_activity_weight_section_keys.dart';
import 'package:yamt/features/activity/presentation/widgets/diary_activity_details_card.dart';
import 'package:yamt/features/activity/presentation/widgets/diary_steps_card.dart';
import 'package:yamt/features/activity/presentation/widgets/diary_workouts_card.dart';
import 'package:yamt/features/activity/presentation/widgets/health_connect_metric_card/diary_health_connect_metric_card.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_card.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_details_card.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_details_content.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_dialog_keys.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/health/data/diary_health_service_provider.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/diary_activity_summary.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/memory_app_preferences.dart';
import '../../../calories/support/fake_calories_repositories.dart';

void main() {
  final selectedDay = DateTime(2026, 4, 27);

  testWidgets('steps card shows progress and expands custom details', (
    tester,
  ) async {
    await _pumpDiaryWidget(
      tester,
      DiaryStepsCard(
        selectedDay: selectedDay,
        expandedContent: const Text('expanded step details'),
      ),
      overrides: [
        _stepsSummaryOverride(
          selectedDay,
          _activitySummary(
            selectedDay,
            totalSteps: 6500,
            stepsDuringWorkouts: 1500,
            stepsOutsideWorkouts: 5000,
          ),
        ),
      ],
    );

    expect(find.text('Schritte'), findsOneWidget);
    expect(
      find.textContaining('6.500 / 10.000', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('expanded step details'), findsNothing);

    await tester.tap(find.text('Schritte'));
    await tester.pumpAndSettle();

    expect(find.text('expanded step details'), findsOneWidget);
  });

  testWidgets('step details card renders workout and outside step split', (
    tester,
  ) async {
    await _pumpDiaryWidget(
      tester,
      DiaryActivityDetailsCard(selectedDay: selectedDay),
      overrides: [
        _stepsSummaryOverride(
          selectedDay,
          _activitySummary(
            selectedDay,
            totalSteps: 6500,
            stepsDuringWorkouts: 1500,
            stepsOutsideWorkouts: 5000,
          ),
        ),
      ],
    );

    expect(find.text('SCHRITTE DETAILS'), findsOneWidget);
    expect(find.text('Schritte im Training'), findsOneWidget);
    expect(find.text('Schritte außerhalb'), findsOneWidget);
    expect(find.text('1.500'), findsOneWidget);
    expect(find.text('5.000'), findsOneWidget);
  });

  testWidgets('step details card renders unassigned active steps', (
    tester,
  ) async {
    await _pumpDiaryWidget(
      tester,
      DiaryActivityDetailsCard(selectedDay: selectedDay),
      overrides: [
        _stepsSummaryOverride(
          selectedDay,
          _activitySummary(
            selectedDay,
            totalSteps: 6500,
            stepsDuringWorkouts: 1500,
            stepsDuringUnassignedActiveEnergy: 800,
            stepsOutsideWorkouts: 4200,
          ),
        ),
      ],
    );

    expect(find.text('Sonstige aktive Schritte'), findsOneWidget);
    expect(find.text('800'), findsOneWidget);
    expect(find.text('4.200'), findsOneWidget);
  });

  testWidgets('step details card hides empty unassigned active steps', (
    tester,
  ) async {
    await _pumpDiaryWidget(
      tester,
      DiaryActivityDetailsCard(selectedDay: selectedDay),
      overrides: [
        _stepsSummaryOverride(
          selectedDay,
          _activitySummary(
            selectedDay,
            totalSteps: 6500,
            stepsDuringWorkouts: 1500,
            stepsOutsideWorkouts: 5000,
          ),
        ),
      ],
    );

    expect(find.text('Sonstige aktive Schritte'), findsNothing);
  });

  testWidgets('step details card retries after load error', (tester) async {
    var shouldFail = true;
    await _pumpDiaryWidget(
      tester,
      DiaryActivityDetailsCard(selectedDay: selectedDay),
      overrides: [
        diaryStepsSummaryProvider(selectedDay).overrideWith((ref) async {
          if (shouldFail) {
            throw StateError('load failed');
          }
          return _activitySummary(
            selectedDay,
            totalSteps: 6500,
            stepsDuringWorkouts: 1500,
            stepsOutsideWorkouts: 5000,
          );
        }),
      ],
    );

    expect(find.text('Schritte konnten nicht geladen werden'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();

    expect(find.text('Schritte konnten nicht geladen werden'), findsNothing);
    expect(find.text('SCHRITTE DETAILS'), findsOneWidget);
    expect(find.text('1.500'), findsOneWidget);
  });

  testWidgets('workouts card renders tracked workout rows', (tester) async {
    final workout = _workout(
      selectedDay,
      activityLabel: 'Radfahren',
      durationMinutes: 42,
      totalCalories: 320,
      sourceName: 'Health Connect',
    );

    await _pumpDiaryWidget(
      tester,
      DiaryWorkoutsCard(selectedDay: selectedDay),
      overrides: [
        _stepsSummaryOverride(
          selectedDay,
          _activitySummary(
            selectedDay,
            totalSteps: 6500,
            stepsDuringWorkouts: 1500,
            stepsOutsideWorkouts: 5000,
            workouts: [workout],
          ),
        ),
      ],
    );

    expect(find.text('TRAININGS'), findsOneWidget);
    expect(find.text('Radfahren'), findsOneWidget);
    expect(find.textContaining('Health Connect'), findsOneWidget);
    expect(find.text('42 Min.'), findsOneWidget);
    expect(find.text('320 kcal'), findsOneWidget);
  });

  testWidgets('activity and weight cards expand their detail panels', (
    tester,
  ) async {
    final workout = _workout(
      selectedDay,
      activityLabel: 'Morgenspaziergang',
      durationMinutes: 30,
      totalCalories: 150,
      sourceName: 'YAMT',
    );
    final weightData = _activityWeightData(
      selectedDay,
      activityKcal: 450,
      activeMinutes: 45,
      selectedWeightKg: 78.4,
      hasSelectedDayWeight: true,
    );

    await _pumpDiaryWidget(
      tester,
      DiaryActivityWeightSection(selectedDay: selectedDay),
      overrides: [
        ..._commonOverrides(),
        _stepsSummaryOverride(
          selectedDay,
          _activitySummary(
            selectedDay,
            totalSteps: 6500,
            stepsDuringWorkouts: 1500,
            stepsOutsideWorkouts: 5000,
            workouts: [workout],
          ),
        ),
        _activityWeightOverride(selectedDay, weightData),
      ],
    );

    expect(find.text('AKTIVITÄT'), findsOneWidget);
    expect(find.text('GEWICHT'), findsOneWidget);
    expect(find.textContaining('450 kcal', findRichText: true), findsOneWidget);
    expect(find.textContaining('78,4 kg', findRichText: true), findsOneWidget);

    await tester.tap(find.text('AKTIVITÄT'));
    await tester.pumpAndSettle();

    expect(find.text('TRAININGS'), findsOneWidget);
    expect(find.text('Morgenspaziergang'), findsOneWidget);

    await tester.tap(find.text('GEWICHT').first);
    await tester.pumpAndSettle();

    expect(find.text('Gewicht eintragen'), findsOneWidget);
    expect(find.textContaining('78,4 kg'), findsWidgets);
    expect(find.byIcon(Icons.close_rounded), findsNWidgets(2));
  });

  testWidgets('compact activity section renders header and expands steps', (
    tester,
  ) async {
    await _pumpDiaryWidget(
      tester,
      DiaryActivityWeightSection(
        selectedDay: selectedDay,
        header: const Text('WOCHE 6 SUMMARY'),
      ),
      overrides: [
        ..._commonOverrides(),
        _stepsSummaryOverride(
          selectedDay,
          _activitySummary(
            selectedDay,
            totalSteps: 6500,
            stepsDuringWorkouts: 1500,
            stepsOutsideWorkouts: 5000,
          ),
        ),
        _activityWeightOverride(
          selectedDay,
          _activityWeightData(
            selectedDay,
            activityKcal: 450,
            activeMinutes: 45,
            selectedWeightKg: 78.4,
            hasSelectedDayWeight: true,
          ),
        ),
      ],
    );

    expect(find.text('WOCHE 6 SUMMARY'), findsOneWidget);
    expect(find.text('SCHRITTE'), findsOneWidget);
    expect(find.text('AKTIVITÄT'), findsOneWidget);
    expect(find.text('GEWICHT'), findsOneWidget);
    expect(find.text('6.500'), findsOneWidget);
    expect(find.textContaining('450 kcal', findRichText: true), findsOneWidget);
    expect(find.textContaining('78,4 kg', findRichText: true), findsOneWidget);

    await tester.tap(find.text('SCHRITTE'));
    await tester.pumpAndSettle();

    expect(find.text('SCHRITTE DETAILS'), findsOneWidget);
    expect(find.text('Schritte im Training'), findsOneWidget);
    expect(find.text('Schritte außerhalb'), findsOneWidget);
    expect(find.text('5.000'), findsOneWidget);
  });

  testWidgets('activity and weight section defers data load', (tester) async {
    var loadCount = 0;
    final deferredDataOverride =
        diaryActivityWeightDataProvider(
          selectedDay,
        ).overrideWith((ref) async {
          loadCount += 1;
          return _activityWeightData(
            selectedDay,
            activityKcal: 450,
            activeMinutes: 45,
            selectedWeightKg: 78.4,
            hasSelectedDayWeight: true,
          );
        });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._commonOverrides(),
          deferredDataOverride,
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DiaryActivityWeightSection(selectedDay: selectedDay),
          ),
        ),
      ),
    );

    expect(loadCount, 0);

    await tester.pump(const Duration(milliseconds: 699));

    expect(loadCount, 0);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(loadCount, 1);
    expect(find.text('AKTIVITÄT'), findsOneWidget);
  });

  testWidgets('activity and weight cards retry after load error', (
    tester,
  ) async {
    var shouldFail = true;
    await _pumpDiaryWidget(
      tester,
      DiaryActivityWeightSection(selectedDay: selectedDay),
      overrides: [
        ..._commonOverrides(),
        diaryActivityWeightDataProvider(selectedDay).overrideWith((ref) async {
          if (shouldFail) {
            throw StateError('load failed');
          }
          return _activityWeightData(
            selectedDay,
            activityKcal: 450,
            activeMinutes: 45,
            selectedWeightKg: 78.4,
            hasSelectedDayWeight: true,
          );
        }),
      ],
    );

    expect(
      find.text('Aktivität und Gewicht konnten nicht geladen werden'),
      findsOneWidget,
    );
    expect(
      find.byKey(DiaryActivityWeightSectionKeys.retryButton),
      findsOneWidget,
    );

    shouldFail = false;
    await tester.tap(find.byKey(DiaryActivityWeightSectionKeys.retryButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Aktivität und Gewicht konnten nicht geladen werden'),
      findsNothing,
    );
    expect(find.text('AKTIVITÄT'), findsOneWidget);
    expect(find.text('GEWICHT'), findsOneWidget);
    expect(find.textContaining('450 kcal', findRichText: true), findsOneWidget);
  });

  testWidgets('weight card shows missing-weight prompt until dismissed', (
    tester,
  ) async {
    await _pumpDiaryWidget(
      tester,
      DiaryActivityWeightSection(selectedDay: selectedDay),
      overrides: [
        ..._commonOverrides(),
        _activityWeightOverride(
          selectedDay,
          _activityWeightData(
            selectedDay,
            selectedWeightKg: 80,
            hasSelectedDayWeight: false,
          ),
        ),
      ],
    );

    expect(
      find.text('Trage dein Gewicht ein für bessere Berechnung.'),
      findsOneWidget,
    );
    expect(find.text('JETZT TRACKEN'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(
      find.text('Trage dein Gewicht ein für bessere Berechnung.'),
      findsNothing,
    );
    expect(find.text('GEWICHT'), findsOneWidget);
  });

  testWidgets('weight card track prompt saves manual weight', (tester) async {
    final manualRepository = FakeManualHealthWeightRepository(
      <ManualHealthWeightEntry>[],
    );

    await _pumpDiaryWidget(
      tester,
      DiaryWeightCard(
        selectedDay: selectedDay,
        data: _activityWeightData(
          selectedDay,
          selectedWeightKg: 80,
          hasSelectedDayWeight: false,
        ),
        isExpanded: false,
        onToggleExpanded: () {},
      ),
      overrides: [
        ..._commonOverrides(),
        manualHealthWeightRepositoryProvider.overrideWith(
          (ref) => manualRepository,
        ),
        healthWeightServiceProvider.overrideWith(
          (ref) => FakeHealthWeightService(const <HealthWeightSample>[]),
        ),
      ],
    );

    await tester.tap(find.text('JETZT TRACKEN'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(DiaryWeightDialogKeys.weightDialogField),
      '82,1',
    );
    await tester.tap(
      find.byKey(DiaryWeightDialogKeys.weightDialogSaveButton),
    );
    await tester.pumpAndSettle();

    expect(manualRepository.entries, hasLength(1));
    expect(manualRepository.entries.single.weightKg, 82.1);
  });

  testWidgets('weight card falls back to seven-day footer', (tester) async {
    await _pumpDiaryWidget(
      tester,
      DiaryWeightCard(
        selectedDay: selectedDay,
        data: _activityWeightData(
          selectedDay,
          selectedWeightKg: 78.4,
          hasSelectedDayWeight: true,
          profileWeightKg: null,
        ),
        isExpanded: false,
        onToggleExpanded: () {},
      ),
      overrides: _commonOverrides(),
    );

    expect(find.text('7 Tage'), findsWidgets);
  });

  testWidgets(
    'weight dialog clears manual entry before app-owned health sample',
    (tester) async {
      final healthSample = HealthWeightSample(
        recordedAt: selectedDay.add(const Duration(hours: 8)),
        weightKg: 77.1,
        uuid: 'app-health-sample',
        sourcePackageName: 'de.yamt.app',
        isFromThisApp: true,
      );
      final manualRepository = FakeManualHealthWeightRepository([
        ManualHealthWeightEntry(day: selectedDay, weightKg: 76.8),
      ]);
      final healthWeightService = FakeHealthWeightService([healthSample]);

      await _pumpDiaryWidget(
        tester,
        DiaryActivityWeightSection(selectedDay: selectedDay),
        overrides: [
          ..._commonOverrides(),
          manualHealthWeightRepositoryProvider.overrideWith(
            (ref) => manualRepository,
          ),
          healthWeightServiceProvider.overrideWith(
            (ref) => healthWeightService,
          ),
          _activityWeightOverride(
            selectedDay,
            _activityWeightData(
              selectedDay,
              selectedWeightKg: 76.8,
              hasSelectedDayWeight: true,
              selectedDayHasManualWeight: true,
              selectedDayHealthSample: healthSample,
            ),
          ),
        ],
      );

      await tester.tap(find.text('GEWICHT').first);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('76,8 kg').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(DiaryWeightDialogKeys.weightDialogClearButton),
      );
      await tester.pumpAndSettle();

      expect(manualRepository.deleteEntryForDayCallCount, 1);
      expect(manualRepository.deletedDays.single, selectedDay);
      expect(healthWeightService.deleteWeightSampleCallCount, 0);
    },
  );

  testWidgets('weight details can add manual weight for selected day', (
    tester,
  ) async {
    final manualRepository = FakeManualHealthWeightRepository(
      <ManualHealthWeightEntry>[],
    );

    await _pumpDiaryWidget(
      tester,
      DiaryWeightDetailsCard(
        selectedDay: selectedDay,
        data: _activityWeightData(
          selectedDay,
          selectedWeightKg: 78.4,
          hasSelectedDayWeight: true,
        ),
      ),
      overrides: [
        ..._commonOverrides(),
        manualHealthWeightRepositoryProvider.overrideWith(
          (ref) => manualRepository,
        ),
        healthWeightServiceProvider.overrideWith(
          (ref) => FakeHealthWeightService(const <HealthWeightSample>[]),
        ),
      ],
    );

    await tester.tap(find.text('Gewicht eintragen'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(DiaryWeightDialogKeys.weightDialogField),
      '81,2',
    );
    await tester.tap(
      find.byKey(DiaryWeightDialogKeys.weightDialogSaveButton),
    );
    await tester.pumpAndSettle();

    expect(manualRepository.entries, hasLength(1));
    expect(manualRepository.entries.single.day, selectedDay);
    expect(manualRepository.entries.single.weightKg, 81.2);
  });

  testWidgets('weight details can edit previous-day manual weight', (
    tester,
  ) async {
    final previousDay = selectedDay.subtract(const Duration(days: 1));
    final manualRepository = FakeManualHealthWeightRepository([
      ManualHealthWeightEntry(day: previousDay, weightKg: 78.9),
    ]);

    await _pumpDiaryWidget(
      tester,
      DiaryWeightDetailsCard(
        selectedDay: selectedDay,
        data: _activityWeightData(
          selectedDay,
          selectedWeightKg: 78.4,
          hasSelectedDayWeight: true,
        ),
      ),
      overrides: [
        ..._commonOverrides(),
        manualHealthWeightRepositoryProvider.overrideWith(
          (ref) => manualRepository,
        ),
        healthWeightServiceProvider.overrideWith(
          (ref) => FakeHealthWeightService(const <HealthWeightSample>[]),
        ),
      ],
    );

    await tester.tap(find.textContaining('78,9 kg').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(DiaryWeightDialogKeys.weightDialogField),
      '79,1',
    );
    await tester.tap(
      find.byKey(DiaryWeightDialogKeys.weightDialogSaveButton),
    );
    await tester.pumpAndSettle();

    expect(manualRepository.entries.single.day, previousDay);
    expect(manualRepository.entries.single.weightKg, 79.1);
  });

  testWidgets('weight details can delete app-owned health sample', (
    tester,
  ) async {
    final healthSample = HealthWeightSample(
      recordedAt: selectedDay.add(const Duration(hours: 8)),
      weightKg: 77.1,
      uuid: 'selected-health-weight',
      sourcePackageName: 'de.yamt.app',
      isFromThisApp: true,
    );
    final healthWeightService = FakeHealthWeightService([healthSample]);

    await _pumpDiaryWidget(
      tester,
      DiaryWeightDetailsCard(
        selectedDay: selectedDay,
        data: _activityWeightData(
          selectedDay,
          selectedWeightKg: 77.1,
          hasSelectedDayWeight: true,
          selectedDayHealthSample: healthSample,
        ),
      ),
      overrides: [
        ..._commonOverrides(),
        healthWeightServiceProvider.overrideWith(
          (ref) => healthWeightService,
        ),
        manualHealthWeightRepositoryProvider.overrideWith(
          (ref) =>
              FakeManualHealthWeightRepository(<ManualHealthWeightEntry>[]),
        ),
      ],
    );

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();

    expect(healthWeightService.deletedSamples, [healthSample]);
  });

  testWidgets('weight details content renders empty state', (tester) async {
    await _pumpDiaryWidget(
      tester,
      DiaryWeightDetailsContent(
        days: const <DiaryWeightDayData>[],
        onAdd: () {},
        onEdit: (_) {},
        onDelete: (_) {},
      ),
      overrides: _commonOverrides(),
    );

    expect(find.text('Keine Gewichte'), findsOneWidget);
  });

  testWidgets('health metric card requests history access', (tester) async {
    final healthService = FakeHealthConnectionService(
      _historyRequiredHealthStatus,
    );

    await _pumpDiaryWidget(
      tester,
      const DiaryHealthConnectMetricCard(
        accessState: HealthDataAccessState.permissionRequired,
      ),
      overrides: [
        ..._commonOverrides(),
        healthConnectionServiceProvider.overrideWith(
          (ref) => healthService,
        ),
      ],
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(healthService.requestHistoryAuthorizationCallCount, 1);
  });

  test('diary weight actions refresh only successful mutations', () async {
    final otherDay = selectedDay.subtract(const Duration(days: 1));
    final appSample = HealthWeightSample(
      recordedAt: selectedDay.add(const Duration(hours: 8)),
      weightKg: 77.1,
      uuid: 'app-owned-weight',
      sourcePackageName: 'de.yamt.app',
      isFromThisApp: true,
    );
    final externalSample = HealthWeightSample(
      recordedAt: selectedDay.add(const Duration(hours: 9)),
      weightKg: 77.4,
      uuid: 'external-weight',
      sourcePackageName: 'external.app',
    );
    final savedWeights = <double>[];
    final deletedDays = <DateTime>[];
    final deletedSamples = <HealthWeightSample>[];
    final refreshedDays = <DateTime?>[];
    final actions = DiaryWeightActions(
      saveManualWeight: ({required day, required weightKg}) async {
        savedWeights.add(weightKg);
        return weightKg > 0;
      },
      deleteManualWeight: (day) async {
        deletedDays.add(day);
        return true;
      },
      deleteHealthWeightSample: (sample) async {
        deletedSamples.add(sample);
        return true;
      },
      refreshDependents: ({required selectedDay, day}) async {
        refreshedDays.add(day);
      },
    );

    expect(
      await actions.saveManualWeight(
        selectedDay: selectedDay,
        day: otherDay,
        weightKg: 82.3,
      ),
      isTrue,
    );
    expect(savedWeights, [82.3]);
    expect(refreshedDays, [otherDay]);

    refreshedDays.clear();
    expect(
      await actions.saveManualWeight(
        selectedDay: selectedDay,
        day: selectedDay,
        weightKg: -1,
      ),
      isFalse,
    );
    expect(refreshedDays, isEmpty);

    expect(
      await actions.deleteWeight(
        selectedDay: selectedDay,
        day: otherDay,
        hasManualWeight: true,
        healthSample: appSample,
      ),
      isTrue,
    );
    expect(deletedDays, [otherDay]);
    expect(refreshedDays, [otherDay]);

    refreshedDays.clear();
    expect(
      await actions.deleteWeight(
        selectedDay: selectedDay,
        day: selectedDay,
        hasManualWeight: false,
        healthSample: appSample,
      ),
      isTrue,
    );
    expect(deletedSamples, [appSample]);
    expect(refreshedDays, [selectedDay]);

    refreshedDays.clear();
    expect(await actions.deleteAppOwnedHealthWeight(null), isFalse);
    expect(
      await actions.deleteAppOwnedHealthWeight(externalSample),
      isFalse,
    );
    expect(deletedSamples, [appSample]);
    expect(refreshedDays, isEmpty);
  });

  test('diary weight actions wait for refresh before completing', () async {
    final refreshCompleter = Completer<void>();
    var refreshCompleted = false;
    final actions = DiaryWeightActions(
      saveManualWeight: ({required day, required weightKg}) async => true,
      deleteManualWeight: (day) async => true,
      deleteHealthWeightSample: (sample) async => true,
      refreshDependents: ({required selectedDay, day}) async {
        await refreshCompleter.future;
        refreshCompleted = true;
      },
    );

    final saveFuture = actions.saveManualWeight(
      selectedDay: selectedDay,
      day: selectedDay,
      weightKg: 82.3,
    );
    await Future<void>.delayed(Duration.zero);

    expect(refreshCompleted, isFalse);

    refreshCompleter.complete();
    await expectLater(saveFuture, completion(isTrue));
    expect(refreshCompleted, isTrue);
  });

  test(
    'activity weight data provider combines health and manual weights',
    () async {
      final selectedDay = DateTime(2026, 4, 27);
      final previousDay = selectedDay.subtract(const Duration(days: 1));
      final olderTrendDay = selectedDay.subtract(const Duration(days: 2));
      final workout = _workout(
        selectedDay,
        activityLabel: 'Spaziergang',
        durationMinutes: 30,
        totalCalories: 150,
        sourceName: 'Health Connect',
      );
      final healthWeightSample = HealthWeightSample(
        recordedAt: selectedDay.add(const Duration(hours: 7)),
        weightKg: 77.1,
        uuid: 'selected-health-weight',
        sourcePackageName: 'de.yamt.app',
        isFromThisApp: true,
      );
      final olderTrendSample = HealthWeightSample(
        recordedAt: olderTrendDay.add(const Duration(hours: 7)),
        weightKg: 79.4,
        uuid: 'older-trend-weight',
        sourcePackageName: 'external.app',
      );
      final newerTrendSample = HealthWeightSample(
        recordedAt: olderTrendDay.add(const Duration(hours: 18)),
        weightKg: 78.9,
        uuid: 'newer-trend-weight',
        sourcePackageName: 'external.app',
      );
      final container = ProviderContainer(
        overrides: [
          ..._commonOverrides(),
          calorieGoalControllerProvider.overrideWith(
            () => _FakeCalorieGoalController(
              CalorieGoalSettings.single(
                dailyKcalGoal: 2200,
                calculatorProfile: const CalorieCalculatorProfile.defaults(),
                effectiveDate: selectedDay,
              ),
            ),
          ),
          healthConnectionServiceProvider.overrideWith(
            (ref) => FakeHealthConnectionService(_readyHealthStatus),
          ),
          diaryHealthServiceProvider.overrideWith(
            (ref) => FakeDiaryHealthService({
              diaryDayKey(selectedDay): DiaryHealthDayData(
                totalSteps: 4000,
                workouts: [workout],
              ),
            }),
          ),
          healthWeightServiceProvider.overrideWith(
            (ref) => FakeHealthWeightService([
              healthWeightSample,
              olderTrendSample,
              newerTrendSample,
            ]),
          ),
          manualHealthWeightRepositoryProvider.overrideWith(
            (ref) => FakeManualHealthWeightRepository([
              ManualHealthWeightEntry(day: selectedDay, weightKg: 76.8),
              ManualHealthWeightEntry(day: previousDay, weightKg: 77.4),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(
        diaryActivityWeightDataProvider(selectedDay).future,
      );

      expect(data.healthAccessState, HealthDataAccessState.ready);
      expect(data.activityKcal, 250);
      expect(data.activeMinutes, 30);
      expect(data.profileWeightKg, 80);
      expect(data.selectedWeightKg, 76.8);
      expect(data.hasSelectedDayWeight, isTrue);
      expect(data.activityTrend.last, 250);
      expect(data.weightTrend[4], 78.9);
      expect(data.weightTrend[5], 77.4);
      expect(data.weightTrend.last, 76.8);
      expect(data.weightDays.last.canDeleteWeight, isTrue);
      expect(data.weightDays[4].canDeleteWeight, isFalse);
    },
  );
}

class _FakeCalorieGoalController extends CalorieGoalController {
  _FakeCalorieGoalController(this.settings);

  final CalorieGoalSettings settings;

  @override
  CalorieGoalSettings build() => settings;
}

const _readyHealthStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.granted,
);

const _historyRequiredHealthStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.notGranted,
);

List<Override> _commonOverrides() {
  return [
    appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
    authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
  ];
}

Override _stepsSummaryOverride(
  DateTime selectedDay,
  DiaryActivitySummary summary,
) {
  return diaryStepsSummaryProvider(
    selectedDay,
  ).overrideWith((ref) async => summary);
}

Override _activityWeightOverride(
  DateTime selectedDay,
  DiaryActivityWeightData data,
) {
  return diaryActivityWeightDataProvider(
    selectedDay,
  ).overrideWith((ref) async => data);
}

DiaryActivitySummary _activitySummary(
  DateTime day, {
  required int totalSteps,
  required int stepsDuringWorkouts,
  required int stepsOutsideWorkouts,
  List<HealthWorkoutSession> workouts = const [],
  int stepsDuringUnassignedActiveEnergy = 0,
}) {
  return DiaryActivitySummary(
    day: day,
    stepGoal: 10000,
    accessState: HealthDataAccessState.ready,
    totalSteps: totalSteps,
    stepsDuringWorkouts: stepsDuringWorkouts,
    stepsDuringUnassignedActiveEnergy: stepsDuringUnassignedActiveEnergy,
    stepsOutsideWorkouts: stepsOutsideWorkouts,
    workouts: workouts,
  );
}

DiaryActivityWeightData _activityWeightData(
  DateTime selectedDay, {
  required bool hasSelectedDayWeight,
  int? activityKcal,
  int? activeMinutes,
  double? selectedWeightKg,
  double? profileWeightKg = 80,
  bool selectedDayHasManualWeight = false,
  HealthWeightSample? selectedDayHealthSample,
}) {
  final weightDays = List<DiaryWeightDayData>.generate(7, (index) {
    final day = selectedDay.subtract(Duration(days: 6 - index));
    if (index == 5) {
      return DiaryWeightDayData(
        day: day,
        weightKg: 78.9,
        hasManualWeight: true,
        hasAppOwnedHealthWeight: false,
        healthSample: null,
      );
    }
    if (index == 6 && hasSelectedDayWeight) {
      final healthSample =
          selectedDayHealthSample ??
          HealthWeightSample(
            recordedAt: day.add(const Duration(hours: 8)),
            weightKg: selectedWeightKg ?? 78.4,
            uuid: 'sample-${day.millisecondsSinceEpoch}',
            sourcePackageName: 'de.yamt.app',
            isFromThisApp: true,
          );
      return DiaryWeightDayData(
        day: day,
        weightKg: selectedWeightKg,
        hasManualWeight: selectedDayHasManualWeight,
        hasAppOwnedHealthWeight: healthSample.isFromThisApp,
        healthSample: healthSample,
      );
    }
    return DiaryWeightDayData(
      day: day,
      weightKg: index.isEven ? 79.6 - index * 0.2 : null,
      hasManualWeight: false,
      hasAppOwnedHealthWeight: false,
      healthSample: null,
    );
  });

  return DiaryActivityWeightData(
    healthAccessState: HealthDataAccessState.ready,
    activityKcal: activityKcal,
    activeMinutes: activeMinutes,
    profileWeightKg: profileWeightKg,
    selectedWeightKg: selectedWeightKg,
    hasSelectedDayWeight: hasSelectedDayWeight,
    activityTrend: const [320, 500, 250, 600, 450, 300, 450],
    weightTrend: weightDays.map((day) => day.weightKg).toList(growable: false),
    weightDays: weightDays,
  );
}

HealthWorkoutSession _workout(
  DateTime day, {
  required String activityLabel,
  required int durationMinutes,
  required int totalCalories,
  required String sourceName,
}) {
  return HealthWorkoutSession(
    id: activityLabel,
    start: day.add(const Duration(hours: 7)),
    endExclusive: day.add(Duration(hours: 7, minutes: durationMinutes)),
    durationMinutes: durationMinutes.toDouble(),
    activityLabel: activityLabel,
    sourceName: sourceName,
    totalCalories: totalCalories,
    totalSteps: 1500,
  );
}

Future<void> _pumpDiaryWidget(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (child is DiaryActivityWeightSection) {
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
  }
}
