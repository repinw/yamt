import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/activity/application/diary_activity_weight_data_provider.dart';
import 'package:yamt/features/activity/application/diary_weight_actions.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
import 'package:yamt/features/activity/presentation/diary_weight_tracking_flow.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/'
    'diary_weight_dialog_keys.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('flow opens diary weight dialog and saves chosen day', (
    tester,
  ) async {
    final selectedDay = DateTime(2026, 4, 15);
    final missingWeightDay = DateTime(2026, 4, 14);
    final recorder = _WeightActionRecorder();

    await _pumpFlowHarness(
      tester,
      recorder: recorder,
      selectedDay: selectedDay,
      day: missingWeightDay,
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(DiaryWeightDialogKeys.weightDialogField),
      '82,4',
    );
    await tester.tap(find.byKey(DiaryWeightDialogKeys.weightDialogSaveButton));
    await tester.pumpAndSettle();

    expect(recorder.savedDay, missingWeightDay);
    expect(recorder.savedWeightKg, 82.4);
    expect(recorder.refreshedSelectedDay, selectedDay);
    expect(recorder.refreshedDay, missingWeightDay);
  });

  testWidgets('flow shows snackbar when save fails', (tester) async {
    final recorder = _WeightActionRecorder(saveResult: false);

    await _pumpFlowHarness(
      tester,
      recorder: recorder,
      selectedDay: DateTime(2026, 4, 15),
      day: DateTime(2026, 4, 15),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(DiaryWeightDialogKeys.weightDialogField),
      '82,4',
    );
    await tester.tap(find.byKey(DiaryWeightDialogKeys.weightDialogSaveButton));
    await tester.pumpAndSettle();

    expect(find.text('Could not save weight.'), findsOneWidget);
    expect(recorder.refreshedDay, isNull);
  });

  testWidgets('flow shows snackbar when clear fails', (tester) async {
    final recorder = _WeightActionRecorder(clearResult: false);

    await _pumpFlowHarness(
      tester,
      recorder: recorder,
      selectedDay: DateTime(2026, 4, 15),
      day: DateTime(2026, 4, 15),
      initialWeightKg: 82.4,
      weightDay: _weightDay(DateTime(2026, 4, 15), hasManualWeight: true),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryWeightDialogKeys.weightDialogClearButton));
    await tester.pumpAndSettle();

    expect(find.text('Could not clear manual weight.'), findsOneWidget);
    expect(recorder.deletedDay, DateTime(2026, 4, 15));
    expect(recorder.refreshedDay, isNull);
  });

  testWidgets('flow offers no delete for a day without own weight', (
    tester,
  ) async {
    final day = DateTime(2026, 4, 15);
    await _pumpFlowHarness(
      tester,
      recorder: _WeightActionRecorder(),
      selectedDay: day,
      day: day,
      initialWeightKg: 82.4,
      weightDay: _weightDay(day),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(DiaryWeightDialogKeys.weightDialogClearButton),
      findsNothing,
    );
  });

  testWidgets('flow still adds a weight when the weight data fails', (
    tester,
  ) async {
    final day = DateTime(2026, 4, 15);
    final recorder = _WeightActionRecorder();
    await _pumpFlowHarness(
      tester,
      recorder: recorder,
      selectedDay: day,
      day: day,
      loadError: StateError('offline'),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(DiaryWeightDialogKeys.weightDialogClearButton),
      findsNothing,
    );
    await tester.enterText(
      find.byKey(DiaryWeightDialogKeys.weightDialogField),
      '82,4',
    );
    await tester.tap(find.byKey(DiaryWeightDialogKeys.weightDialogSaveButton));
    await tester.pumpAndSettle();

    expect(recorder.savedWeightKg, 82.4);
  });

  testWidgets('a double tap opens one dialog', (tester) async {
    final day = DateTime(2026, 4, 15);
    final loaded = Completer<void>();
    await _pumpFlowHarness(
      tester,
      recorder: _WeightActionRecorder(),
      selectedDay: day,
      day: day,
      weightDay: _weightDay(day, hasManualWeight: true),
      loaded: loaded.future,
    );

    // Both taps land while the weight data still loads.
    await tester.tap(find.text('Open'));
    await tester.tap(find.text('Open'));
    loaded.complete();
    await tester.pumpAndSettle();

    expect(find.byKey(DiaryWeightDialogKeys.weightDialogField), findsOneWidget);
  });

  testWidgets('flow deletes a Health weight that this app wrote', (
    tester,
  ) async {
    final day = DateTime(2026, 4, 15);
    final sample = HealthWeightSample(
      recordedAt: DateTime(2026, 4, 15, 7),
      weightKg: 82.4,
      isFromThisApp: true,
    );
    final recorder = _WeightActionRecorder();
    await _pumpFlowHarness(
      tester,
      recorder: recorder,
      selectedDay: day,
      day: day,
      initialWeightKg: 82.4,
      weightDay: _weightDay(day, healthSample: sample),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryWeightDialogKeys.weightDialogClearButton));
    await tester.pumpAndSettle();

    expect(recorder.deletedSample, sample);
    expect(recorder.deletedDay, isNull);
    expect(recorder.refreshedDay, day);
  });
}

DiaryWeightDayData _weightDay(
  DateTime day, {
  bool hasManualWeight = false,
  HealthWeightSample? healthSample,
}) {
  return DiaryWeightDayData(
    day: day,
    weightKg: 82.4,
    hasManualWeight: hasManualWeight,
    hasAppOwnedHealthWeight: healthSample?.isFromThisApp ?? false,
    healthSample: healthSample,
  );
}

class _WeightActionRecorder {
  new({this.saveResult = true, this.clearResult = true});

  final bool saveResult;
  final bool clearResult;
  DateTime? savedDay;
  double? savedWeightKg;
  DateTime? deletedDay;
  HealthWeightSample? deletedSample;
  DateTime? refreshedSelectedDay;
  DateTime? refreshedDay;

  DiaryWeightActions toActions() {
    return DiaryWeightActions(
      saveManualWeight: ({required day, required weightKg}) async {
        savedDay = day;
        savedWeightKg = weightKg;
        return saveResult;
      },
      deleteManualWeight: (day) async {
        deletedDay = day;
        return clearResult;
      },
      deleteHealthWeightSample: (sample) async {
        deletedSample = sample;
        return clearResult;
      },
      refreshDependents: ({required selectedDay, day}) async {
        refreshedSelectedDay = selectedDay;
        refreshedDay = day;
      },
    );
  }
}

Future<void> _pumpFlowHarness(
  WidgetTester tester, {
  required _WeightActionRecorder recorder,
  required DateTime selectedDay,
  required DateTime day,
  double? initialWeightKg,
  DiaryWeightDayData? weightDay,
  Error? loadError,
  Future<void>? loaded,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        diaryWeightActionsProvider.overrideWith((ref) => recorder.toActions()),
        diaryActivityWeightDataProvider(day).overrideWith((ref) async {
          await loaded;
          if (loadError != null) {
            throw loadError;
          }
          return DiaryActivityWeightData(
            profileWeightKg: null,
            selectedWeightKg: weightDay?.weightKg,
            hasSelectedDayWeight: weightDay?.weightKg != null,
            weightTrend: const [],
            weightDays: [?weightDay],
          );
        }),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, child) {
              final flow = ref.watch(diaryWeightTrackingFlowProvider);
              return FilledButton(
                onPressed: () {
                  unawaited(
                    flow.showDialogForDay(
                      context: context,
                      selectedDay: selectedDay,
                      day: day,
                      initialWeightKg: initialWeightKg,
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    ),
  );
}
