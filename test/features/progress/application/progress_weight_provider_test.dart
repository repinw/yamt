import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/progress/application/progress_weight_provider.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/domain/progress_weight.dart';

import '../../../helpers/progress_source_overrides.dart';
import '../../calories/support/fake_calories_repositories.dart';

Future<ProgressWeight> _weight(ProgressScope scope) async {
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

  test('a past goal ends on its last day and has no forecast', () async {
    final weight = await _weight(const ProgressPastGoalScope(1));

    expect(weight.trend.days.first.day, DateTime(2026, 9));
    expect(weight.trend.days.last.day, DateTime(2026, 9, 9));
    expect(weight.trend.trendKgPerWeek, isNotNull);
    expect(weight.projectedGoalDate, isNull);
    expect(weight.isGoalReached, isFalse);
  });
}
