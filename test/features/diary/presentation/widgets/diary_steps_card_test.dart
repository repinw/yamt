import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_steps_card.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  final selectedDay = DateTime(2026, 4, 27);

  testWidgets('renders step count and progress ratio', (tester) async {
    await _pumpStepsCard(
      tester,
      selectedDay: selectedDay,
      summary: _summary(selectedDay, totalSteps: 6500),
    );

    expect(find.text('Steps'), findsOneWidget);
    expect(
      find.textContaining('6,500 / 10,000', findRichText: true),
      findsOneWidget,
    );

    final trackRect = tester.getRect(
      find.byKey(DiaryStepsCardKeys.progressTrack),
    );
    final fillRect = tester.getRect(
      find.byKey(DiaryStepsCardKeys.progressFill),
    );
    expect(fillRect.width / trackRect.width, closeTo(0.65, 0.02));
  });

  testWidgets('renders locked state when health access is not ready', (
    tester,
  ) async {
    await _pumpStepsCard(
      tester,
      selectedDay: selectedDay,
      summary: DiaryActivitySummary.locked(
        day: selectedDay,
        accessState: HealthDataAccessState.permissionRequired,
      ),
    );

    expect(find.text('Steps'), findsOneWidget);
    expect(find.textContaining('/ 10,000', findRichText: true), findsOneWidget);

    final fillRect = tester.getRect(
      find.byKey(DiaryStepsCardKeys.progressFill),
    );
    expect(fillRect.width, 0);
  });
}

Future<void> _pumpStepsCard(
  WidgetTester tester, {
  required DateTime selectedDay,
  required DiaryActivitySummary summary,
}) async {
  await _pumpDiaryWidget(
    tester,
    DiaryStepsCard(selectedDay: selectedDay),
    overrides: [
      diaryStepsSummaryProvider(
        selectedDay,
      ).overrideWith((ref) async => summary),
    ],
  );
}

DiaryActivitySummary _summary(DateTime day, {required int totalSteps}) {
  return DiaryActivitySummary(
    day: day,
    stepGoal: 10000,
    accessState: HealthDataAccessState.ready,
    totalSteps: totalSteps,
    stepsDuringWorkouts: 1200,
    stepsOutsideWorkouts: totalSteps - 1200,
    workouts: const [],
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
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
