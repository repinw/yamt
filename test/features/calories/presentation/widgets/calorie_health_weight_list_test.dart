import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/features/calories/application/calorie_weight_state_refresh.dart';
import 'package:yamt/features/calories/domain/calorie_health_trend_snapshot.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/calorie_health_trends_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_health_weight_list.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/'
    'manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../support/fake_calories_repositories.dart';

const _permissionRequiredStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.notGranted,
  historyAccess: HealthHistoryAccess.notGranted,
);

void main() {
  testWidgets('save refreshes calorie weight dependents after success', (
    tester,
  ) async {
    final day = DateTime(2026, 3, 14);
    final repository = FakeManualHealthWeightRepository([]);
    final refreshedDays = <DateTime>[];

    await _pumpWeightList(
      tester,
      point: _point(day: day),
      repository: repository,
      refreshedDays: refreshedDays,
    );

    await tester.tap(
      find.byKey(CalorieHealthTrendsKeys.weightActionButton(diaryDayKey(day))),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(CalorieHealthTrendsKeys.weightDialogField),
      '82.3',
    );
    await tester.tap(
      find.byKey(CalorieHealthTrendsKeys.weightDialogSaveButton),
    );
    await tester.pumpAndSettle();

    expect(repository.entries.single.weightKg, 82.3);
    expect(refreshedDays, [day]);
  });

  testWidgets('save skips calorie refresh when manual save fails', (
    tester,
  ) async {
    final day = DateTime(2026, 3, 14);
    final repository = _FailingManualHealthWeightRepository();
    final refreshedDays = <DateTime>[];

    await _pumpWeightList(
      tester,
      point: _point(day: day),
      repository: repository,
      refreshedDays: refreshedDays,
    );

    await tester.tap(
      find.byKey(CalorieHealthTrendsKeys.weightActionButton(diaryDayKey(day))),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(CalorieHealthTrendsKeys.weightDialogField),
      '82.3',
    );
    await tester.tap(
      find.byKey(CalorieHealthTrendsKeys.weightDialogSaveButton),
    );
    await tester.pump();

    expect(refreshedDays, isEmpty);
    expect(find.text('Could not save weight.'), findsOneWidget);
  });

  testWidgets('clear refreshes calorie weight dependents after success', (
    tester,
  ) async {
    final day = DateTime(2026, 3, 14);
    final repository = FakeManualHealthWeightRepository([
      ManualHealthWeightEntry(day: day, weightKg: 81.2),
    ]);
    final refreshedDays = <DateTime>[];

    await _pumpWeightList(
      tester,
      point: _point(
        day: day,
        weightKg: 81.2,
        source: CalorieHealthTrendWeightSource.manual,
      ),
      repository: repository,
      refreshedDays: refreshedDays,
    );

    await tester.tap(
      find.byKey(CalorieHealthTrendsKeys.weightActionButton(diaryDayKey(day))),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(CalorieHealthTrendsKeys.weightDialogClearButton),
    );
    await tester.pumpAndSettle();

    expect(repository.deleteEntryForDayCallCount, 1);
    expect(repository.entries, isEmpty);
    expect(refreshedDays, [day]);
  });
}

Future<void> _pumpWeightList(
  WidgetTester tester, {
  required CalorieHealthTrendPoint point,
  required FakeManualHealthWeightRepository repository,
  required List<DateTime> refreshedDays,
}) async {
  await tester.pumpWidget(
    _buildTestApp(
      overrides: [
        healthConnectionServiceProvider.overrideWith(
          (ref) => FakeHealthConnectionService(_permissionRequiredStatus),
        ),
        healthWeightServiceProvider.overrideWith(
          (ref) => FakeHealthWeightService([]),
        ),
        manualHealthWeightRepositoryProvider.overrideWithValue(repository),
        calorieWeightStateRefreshProvider.overrideWithValue(
          ({required day}) async {
            refreshedDays.add(day);
          },
        ),
      ],
      child: CalorieHealthWeightList(
        snapshot: CalorieHealthTrendSnapshot(
          points: [point],
          healthAccessState: HealthDataAccessState.permissionRequired,
          healthPlatform: HealthPlatform.android,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _buildTestApp({
  required List<Override> overrides,
  required Widget child,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    ),
  );
}

CalorieHealthTrendPoint _point({
  required DateTime day,
  double? weightKg,
  CalorieHealthTrendWeightSource source = CalorieHealthTrendWeightSource.none,
}) {
  return CalorieHealthTrendPoint(
    day: day,
    intakeKcal: 0,
    burnedKcal: null,
    weightKg: weightKg,
    weightSource: source,
  );
}

class _FailingManualHealthWeightRepository
    extends FakeManualHealthWeightRepository {
  _FailingManualHealthWeightRepository() : super([]);

  @override
  Future<bool> saveEntry(ManualHealthWeightEntry entry) async {
    return false;
  }
}
