import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/activity/application/diary_weight_actions.dart';
import 'package:yamt/features/activity/presentation/diary_weight_tracking_flow.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/'
    'diary_weight_dialog_keys.dart';
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
      hasManualWeight: true,
      canClearWeight: true,
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryWeightDialogKeys.weightDialogClearButton));
    await tester.pumpAndSettle();

    expect(find.text('Could not clear manual weight.'), findsOneWidget);
    expect(recorder.deletedDay, DateTime(2026, 4, 15));
    expect(recorder.refreshedDay, isNull);
  });
}

class _WeightActionRecorder {
  _WeightActionRecorder({
    this.saveResult = true,
    this.clearResult = true,
  });

  final bool saveResult;
  final bool clearResult;
  DateTime? savedDay;
  double? savedWeightKg;
  DateTime? deletedDay;
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
      deleteHealthWeightSample: (sample) async => clearResult,
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
  bool hasManualWeight = false,
  bool canClearWeight = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        diaryWeightActionsProvider.overrideWith(
          (ref) => recorder.toActions(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
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
                      hasManualWeight: hasManualWeight,
                      canClearWeight: canClearWeight,
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
