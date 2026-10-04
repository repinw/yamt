import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/calorie_overview_revision_provider.dart';
import 'package:yamt/features/calories/data/closed_day_repository.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_previous_day_controller.dart';

import '../../../../helpers/memory_app_preferences.dart';

void main() {
  test('closes and reopens the day and reloads the overviews', () async {
    final repository = ClosedDayRepository(MemoryAppPreferences(), 'user-1');
    final container = ProviderContainer(
      overrides: [closedDayRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      diaryPreviousDayControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(
      diaryPreviousDayControllerProvider.notifier,
    );
    final day = DateTime(2026, 10, 4);

    expect(await controller.close(day), isTrue);
    expect(repository.readClosedDay(), day);
    expect(container.read(calorieOverviewRevisionProvider), 1);

    expect(await controller.reopen(), isTrue);
    expect(repository.readClosedDay(), isNull);
    expect(container.read(calorieOverviewRevisionProvider), 2);
  });

  test('reports a failed save and keeps the overviews', () async {
    final container = ProviderContainer(
      overrides: [
        closedDayRepositoryProvider.overrideWithValue(
          _FailingClosedDayRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      diaryPreviousDayControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    final saved = await container
        .read(diaryPreviousDayControllerProvider.notifier)
        .close(DateTime(2026, 10, 4));

    expect(saved, isFalse);
    expect(container.read(diaryPreviousDayControllerProvider).hasError, isTrue);
    expect(container.read(calorieOverviewRevisionProvider), 0);
  });
}

class _FailingClosedDayRepository extends ClosedDayRepository {
  new() : super(MemoryAppPreferences(), 'user-1');

  @override
  Future<void> saveClosedDay(DateTime day) async {
    throw StateError('disk full');
  }
}
