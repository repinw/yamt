import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:yamt/features/calories/application/calorie_budget_settings_provider.dart';
import 'package:yamt/features/calories/application/tdee_analytics_provider.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/diary/application/diary_day_tdee_provider.dart';

final _goalSettings = CalorieGoalSettings.single(
  dailyKcalGoal: 2000,
  calculatorProfile: null,
  effectiveDate: DateTime(2026, 4),
);

/// Daily estimates of 2300 kcal on 10 April and 2400 kcal on 20 April, and
/// a day without an estimate between them and after.
final _points = [
  TdeeAnalyticsPoint(day: DateTime(2026, 4, 10), learnedBaseTdeeKcal: 2300),
  TdeeAnalyticsPoint(day: DateTime(2026, 4, 20), learnedBaseTdeeKcal: 2400),
];

ProviderContainer _container({
  CalorieGoalSettings? settings,
  List<TdeeAnalyticsPoint>? points,
  void Function()? onAnalytics,
}) {
  final container = ProviderContainer(
    overrides: [
      calorieBudgetSettingsProvider.overrideWith(
        (ref) async => settings ?? _goalSettings,
      ),
      tdeeAnalyticsProvider.overrideWith((ref, query) async {
        onAnalytics?.call();
        return TdeeAnalyticsState(points: points ?? _points);
      }),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<DiaryDayTdee> _read(ProviderContainer container, DateTime day) {
  final provider = diaryDayTdeeProvider(day);
  final subscription = container.listen(provider, (_, _) {});
  addTearDown(subscription.close);
  return container.read(provider.future);
}

void main() {
  test('takes the last estimate on or before the day', () async {
    final container = _container();

    expect((await _read(container, DateTime(2026, 4, 15))).tdeeKcal, 2300);
    expect((await _read(container, DateTime(2026, 4, 10))).tdeeKcal, 2300);
    expect((await _read(container, DateTime(2026, 4, 20))).tdeeKcal, 2400);
  });

  test('a day after the newest estimate keeps it', () async {
    final container = _container();

    final result = await _read(container, DateTime(2026, 5, 3));

    expect(result.tdeeKcal, 2400);
  });

  test('the time of day does not matter', () async {
    final container = _container();

    final result = await _read(container, DateTime(2026, 4, 10, 23, 30));

    expect(result.tdeeKcal, 2300);
  });

  test('a day before the first estimate has none, but its goal', () async {
    final container = _container();

    final result = await _read(container, DateTime(2026, 4, 5));

    expect(result.tdeeKcal, isNull);
    expect(result.goalKcal, 2000);
  });

  test('an estimate without a value gives none', () async {
    final container = _container(
      points: [TdeeAnalyticsPoint(day: DateTime(2026, 4, 10))],
    );

    final result = await _read(container, DateTime(2026, 4, 12));

    expect(result.tdeeKcal, isNull);
    expect(result.goalKcal, 2000);
  });

  test('the goal is the one in effect on the day', () async {
    final container = _container();

    expect((await _read(container, DateTime(2026, 4, 12))).goalKcal, 2000);
  });

  test('a day before the first goal has no goal', () async {
    final container = _container();

    final result = await _read(container, DateTime(2026, 3, 25));

    expect(result.goalKcal, isNull);
    expect(result.tdeeKcal, isNull);
  });

  test('without any goal both are null and no analytics load', () async {
    var analyticsReads = 0;
    final container = _container(
      settings: const CalorieGoalSettings.empty(),
      onAnalytics: () => analyticsReads++,
    );

    final result = await _read(container, DateTime(2026, 4, 15));

    expect(result.tdeeKcal, isNull);
    expect(result.goalKcal, isNull);
    expect(analyticsReads, 0);
  });
}
