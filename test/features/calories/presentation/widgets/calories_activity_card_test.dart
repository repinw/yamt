import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_activity_card.dart';
import 'package:yamt/features/calories/provider/'
    'diary_activity_summary_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('activity card shows connected health summary', (tester) async {
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
              workouts: const <HealthWorkoutSession>[],
            ),
          ),
        ],
        child: const CaloriesActivityCard(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('6,400'), findsOneWidget);
    expect(find.text('1,800'), findsOneWidget);
    expect(find.text('4600') /* sentinel */, findsNothing);
    expect(find.text('184 kcal'), findsOneWidget);
  });

  testWidgets('activity card shows connect prompt when access missing', (
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
        child: const CaloriesActivityCard(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Connect health'), findsOneWidget);

    await tester.tap(find.text('Connect health'));
    await tester.pump();

    expect(controller.requestAuthorizationCallCount, 1);
  });

  testWidgets('activity card uses controller loading state for prompt', (
    tester,
  ) async {
    final pendingStatus = Completer<HealthConnectionStatus>();
    await tester.pumpWidget(
      _TestApp(
        overrides: [
          diaryActivitySummaryProvider.overrideWith(
            (ref) async => DiaryActivitySummary.locked(
              day: DateTime(2026, 4, 15),
              accessState: HealthDataAccessState.permissionRequired,
            ),
          ),
          healthConnectionControllerProvider.overrideWith(
            () => _FakeHealthConnectionController(
              status: _permissionRequiredStatus,
              pendingBuild: pendingStatus,
            ),
          ),
        ],
        child: const CaloriesActivityCard(),
      ),
    );
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}

const _permissionRequiredStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.notGranted,
  historyAccess: HealthHistoryAccess.notGranted,
);

class _FakeHealthConnectionController extends HealthConnectionController {
  _FakeHealthConnectionController({required this.status, this.pendingBuild});

  final HealthConnectionStatus status;
  final Completer<HealthConnectionStatus>? pendingBuild;
  int requestAuthorizationCallCount = 0;

  @override
  FutureOr<HealthConnectionStatus> build() {
    final pendingBuild = this.pendingBuild;
    if (pendingBuild != null) {
      return pendingBuild.future;
    }
    return status;
  }

  @override
  Future<HealthConnectionStatus> requestAuthorization() async {
    requestAuthorizationCallCount += 1;
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
