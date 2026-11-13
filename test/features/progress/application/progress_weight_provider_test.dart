import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/progress/application/progress_weight_provider.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/domain/progress_weight.dart';

import '../../../helpers/progress_source_overrides.dart';
import '../../calories/support/fake_calories_repositories.dart';

Future<ProgressWeight> _weight(
  ProgressScope scope, {
  List<ManualHealthWeightEntry> extraWeighIns = const [],
}) async {
  final settings = FakeCalorieSettingsRepository(
    initialSettings: progressTwoGoalSettings(),
  );
  addTearDown(settings.dispose);
  final calorieLog = FakeCalorieLogRepository();
  addTearDown(calorieLog.dispose);
  final container = ProviderContainer(
    overrides: progressSourceOverrides(
      settingsRepository: settings,
      calorieLog: calorieLog,
      extraWeighIns: extraWeighIns,
    ),
  );
  addTearDown(container.dispose);
  final subscription = container.listen(
    progressWeightProvider(scope),
    (_, _) {},
  );
  addTearDown(subscription.close);
  return await container.read(progressWeightProvider(scope).future);
}

void main() {
  test('the current goal ends today and forecasts the goal', () async {
    final weight = await _weight(ProgressScope.goal);

    expect(weight.trend.days.last.day, DateTime(2026, 9, 24));
    expect(weight.projectedGoalDate, isNotNull);
  });

  test('the rate of the current goal counts from its start', () async {
    final weight = await _weight(ProgressScope.goal);

    expect(weight.rate!.since, DateTime(2026, 9, 10));
    expect(weight.rate!.until, DateTime(2026, 9, 24));
    expect(weight.rate!.kgPerWeek, lessThan(0));
  });

  test('the rate of all goals counts from the first weigh-in', () async {
    final weight = await _weight(ProgressScope.all);

    // The first goal starts on 1 September, the weigh-ins on 6 September.
    expect(weight.rate!.since, DateTime(2026, 9, 6));
    expect(weight.rate!.until, DateTime(2026, 9, 24));
    expect(weight.rate!.kgPerWeek, lessThan(0));
  });

  test('the rate of a past goal covers only that goal', () async {
    final weight = await _weight(
      const ProgressPastGoalScope(1),
      extraWeighIns: [
        ManualHealthWeightEntry(day: DateTime(2026, 8, 25), weightKg: 85),
      ],
    );

    expect(weight.rate!.since, DateTime(2026, 9));
    expect(weight.rate!.until, DateTime(2026, 9, 9));
    expect(weight.rate!.kgPerWeek, lessThan(0));
  });

  test('a past goal ends on its last day and has no forecast', () async {
    final weight = await _weight(const ProgressPastGoalScope(1));

    expect(weight.trend.days.first.day, DateTime(2026, 9));
    expect(weight.trend.days.last.day, DateTime(2026, 9, 9));
    // Its weigh-ins start on 6 September: too few days for a rate.
    expect(weight.rate, isNull);
    expect(weight.projectedGoalDate, isNull);
    expect(weight.isGoalReached, isFalse);
  });
}
