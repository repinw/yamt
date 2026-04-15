import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_workouts_card.dart';
import 'package:yamt/features/calories/provider/'
    'diary_activity_summary_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('workouts card renders workout entries', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        overrides: [
          diaryActivitySummaryProvider.overrideWith(
            (ref) async => DiaryActivitySummary(
              day: DateTime(2026, 4, 15),
              stepGoal: diaryActivityStepGoal,
              accessState: HealthDataAccessState.ready,
              totalSteps: 6400,
              stepsDuringWorkouts: 1800,
              stepsOutsideWorkouts: 4600,
              workouts: [
                HealthWorkoutSession(
                  id: 'run-1',
                  start: DateTime(2026, 4, 15, 7),
                  endExclusive: DateTime(2026, 4, 15, 8),
                  durationMinutes: 60,
                  activityLabel: 'Walking',
                  sourceName: 'Health Connect',
                  totalCalories: 500,
                  totalSteps: 3100,
                ),
              ],
            ),
          ),
        ],
        child: const CaloriesWorkoutsCard(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Workouts'), findsOneWidget);
    expect(find.text('Walking'), findsOneWidget);
    expect(find.text('🚶'), findsOneWidget);
    expect(find.text('🏋️'), findsNothing);
    expect(find.text('Source: Health Connect'), findsOneWidget);
    expect(find.text('60 min'), findsOneWidget);
    expect(find.text('500 kcal'), findsOneWidget);
  });

  testWidgets('workouts card shows empty state when no workouts found', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        overrides: [
          diaryActivitySummaryProvider.overrideWith(
            (ref) async => DiaryActivitySummary(
              day: DateTime(2026, 4, 15),
              stepGoal: diaryActivityStepGoal,
              accessState: HealthDataAccessState.ready,
              totalSteps: 6400,
              stepsDuringWorkouts: 0,
              stepsOutsideWorkouts: 6400,
              workouts: const <HealthWorkoutSession>[],
            ),
          ),
        ],
        child: const CaloriesWorkoutsCard(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No workouts found for this day.'), findsOneWidget);
  });

  testWidgets('workouts card routes connect action through controller', (
    tester,
  ) async {
    final controller = _FakeHealthConnectionController(
      status: _permissionRequiredStatus,
    );
    await tester.pumpWidget(
      _TestApp(
        overrides: [
          diaryActivitySummaryProvider.overrideWith(
            (ref) async => DiaryActivitySummary.locked(
              day: DateTime(2026, 4, 15),
              accessState: HealthDataAccessState.permissionRequired,
            ),
          ),
          healthConnectionControllerProvider.overrideWith(() => controller),
        ],
        child: const CaloriesWorkoutsCard(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Connect health'));
    await tester.pump();

    expect(controller._requestAuthorizationCallCount, 1);
  });
}

const _permissionRequiredStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.notGranted,
  historyAccess: HealthHistoryAccess.notGranted,
);

class _FakeHealthConnectionController extends HealthConnectionController {
  _FakeHealthConnectionController({required this.status});

  final HealthConnectionStatus status;
  var _requestAuthorizationCallCount = 0;

  @override
  FutureOr<HealthConnectionStatus> build() => status;

  @override
  Future<HealthConnectionStatus> requestAuthorization() async {
    _requestAuthorizationCallCount += 1;
    state = AsyncData(status);
    return status;
  }
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.overrides, required this.child});

  final List<dynamic> overrides;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: child),
      ),
    );
  }
}
