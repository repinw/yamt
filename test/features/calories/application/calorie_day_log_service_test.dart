import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/calorie_day_log_service.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/application/last_planned_day_provider.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/quick_calorie_entry.dart';

import '../support/fake_planned_entry_repository.dart';

/// Fails the save of the plan with [failingId].
class _FailingPlans extends FakePlannedEntryRepository {
  new({required this.failingId});

  final String failingId;

  @override
  Future<void> savePlannedEntry(CalorieEntry entry) async {
    if (entry.id == failingId) {
      throw StateError('Plan write failed.');
    }
    await super.savePlannedEntry(entry);
  }
}

CalorieEntry _plan(String id, DateTime loggedAt) {
  return buildQuickCalorieEntry(
    id: id,
    userId: 'user-1',
    name: 'Kantine',
    mealType: MealType.lunch,
    loggedAt: loggedAt,
    now: DateTime(2026, 9, 28, 12),
    kcal: 650,
  );
}

void main() {
  final tomorrow = DateTime(2026, 9, 29, 12);
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  CalorieDayLogService service(FakePlannedEntryRepository plans) {
    return CalorieDayLogService(
      plans: plans,
      overviewRevision: container.read(
        calorieOverviewRevisionProvider.notifier,
      ),
      lastPlannedDay: container.read(lastPlannedDayProvider.notifier),
      clock: () => DateTime(2026, 9, 28, 12),
    );
  }

  int revision() => container.read(calorieOverviewRevisionProvider);

  test('food becomes a plan only after today', () {
    final dayLog = service(FakePlannedEntryRepository());

    expect(dayLog.plansOn(DateTime(2026, 9, 28, 23, 59)), isFalse);
    expect(dayLog.plansOn(DateTime(2026, 9, 27, 8)), isFalse);
    expect(dayLog.plansOn(DateTime(2026, 9, 29)), isTrue);
  });

  test('plan saves, signals and names the planned day', () async {
    final plans = FakePlannedEntryRepository();

    await service(plans).plan(_plan('plan-1', tomorrow));

    expect(plans.plans.map((plan) => plan.id), ['plan-1']);
    expect(revision(), 1);
    expect(container.read(lastPlannedDayProvider)?.day, tomorrow);
  });

  test(
    'savePlans and deletePlans signal once, without a planned day',
    () async {
      final plans = FakePlannedEntryRepository();
      final dayLog = service(plans);
      final first = _plan('plan-1', tomorrow);
      final second = _plan('plan-2', tomorrow);

      await dayLog.savePlans([first, second]);
      expect(plans.plans, hasLength(2));
      expect(revision(), 1);

      await dayLog.deletePlans([first, second]);
      expect(plans.plans, isEmpty);
      expect(revision(), 2);
      expect(container.read(lastPlannedDayProvider), isNull);
    },
  );

  test('a failed save removes the plans saved before it', () async {
    final plans = _FailingPlans(failingId: 'plan-2');

    await expectLater(
      service(plans)
          .savePlans([_plan('plan-1', tomorrow), _plan('plan-2', tomorrow)]),
      throwsStateError,
    );

    expect(plans.plans, isEmpty);
    expect(revision(), 0);
  });
}
