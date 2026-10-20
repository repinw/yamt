import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/progress/application/progress_intake_provider.dart';
import 'package:yamt/features/progress/domain/progress_intake.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';

import '../../../helpers/progress_source_overrides.dart';
import '../../calories/support/fake_calories_repositories.dart';

Future<(ProgressIntake, List<(DateTime, DateTime)>)> _intake(
  ProgressScope scope,
) async {
  final settings = FakeCalorieSettingsRepository(
    initialSettings: progressTwoGoalSettings(),
  );
  addTearDown(settings.dispose);
  final calorieLog = FakeCalorieLogRepository(
    initialEntries: progressEntries(),
  );
  addTearDown(calorieLog.dispose);
  final ranges = <(DateTime, DateTime)>[];
  calorieLog.onReadEntriesInRange = (start, end) async {
    ranges.add((start, end));
    return [
      for (final entry in calorieLog.entries)
        if (!entry.loggedAt.isBefore(start) && entry.loggedAt.isBefore(end))
          entry,
    ];
  };
  final container = ProviderContainer(
    overrides: progressSourceOverrides(
      settingsRepository: settings,
      calorieLog: calorieLog,
    ),
  );
  addTearDown(container.dispose);
  final subscription = container.listen(
    progressIntakeProvider(scope),
    (_, _) {},
  );
  addTearDown(subscription.close);
  final intake = await container.read(progressIntakeProvider(scope).future);
  return (intake, ranges);
}

void main() {
  test('the current goal reads the run of the current week', () async {
    final (intake, ranges) = await _intake(ProgressScope.goal);

    expect(intake.weekDays, hasLength(7));
    expect(ranges, contains((DateTime(2026, 9, 10), DateTime(2026, 10))));
  });

  test('a past goal reads only its own days', () async {
    final (intake, ranges) = await _intake(const ProgressPastGoalScope(1));

    expect(ranges, contains((DateTime(2026, 9), DateTime(2026, 9, 10))));
    expect(intake.weekDays, isEmpty);
    expect(intake.training.dayCount + intake.rest.dayCount, 9);
  });
}
