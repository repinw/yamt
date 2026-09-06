import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_mappers.dart';
import 'package:yamt/features/diary/domain/diary_macro_targets.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_food_log_feedback_controller.dart';

import '../../support/diary_dashboard_test_support.dart';

void main() {
  final day = DateTime(2026, 9, 5);
  CalorieEntry food(String id, double protein) => CalorieEntry.create(
    id: id,
    userId: 'user',
    name: id,
    mealType: MealType.lunch,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 200,
    per100Protein: protein,
    per100Carbs: 12,
    per100Fat: 4,
    loggedAt: day,
  );
  const goals = DiaryMacroTargets(protein: 100, carbs: 200, fat: 70);

  test(
    'computes before from committed IDs and uses the dashboard targets',
    () async {
      final oldFood = food('old', 50);
      final newFood = food('new', 25);
      final all = [oldFood, newFood];
      final controller = FakeDiaryDayDashboardController(
        diaryDashboardLoadedStateForTest(
          selectedDay: day,
          selectedDayEntries: all,
          nutritionBars: buildDiaryDashboardNutritionBars(
            all,
            2000,
            macroTargets: goals,
          ),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          diaryDayDashboardControllerProvider(
            day,
          ).overrideWith(() => controller),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        diaryFoodLogFeedbackControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container
          .read(diaryFoodLogFeedbackControllerProvider.notifier)
          .enqueue([
            [newFood],
          ]);
      final feedback = container
          .read(diaryFoodLogFeedbackControllerProvider)
          .single;
      expect(feedback.before!.protein, 50);
      expect(feedback.after!.protein, 75);
      expect(feedback.after!.goals, same(goals));
      container
          .read(diaryFoodLogFeedbackControllerProvider.notifier)
          .dismiss(feedback);
      expect(container.read(diaryFoodLogFeedbackControllerProvider), isEmpty);
    },
  );

  test(
    'cached or incomplete daily data yields amounts without invented progress',
    () async {
      final newFood = food('new', 25);
      for (final cached in [false, true]) {
        final controller = FakeDiaryDayDashboardController(
          diaryDashboardLoadedStateForTest(
            selectedDay: day,
            selectedDayEntries: cached ? [newFood] : [],
            isFromCache: cached,
          ),
        );
        final container = ProviderContainer(
          overrides: [
            diaryDayDashboardControllerProvider(
              day,
            ).overrideWith(() => controller),
          ],
        );
        final subscription = container.listen(
          diaryFoodLogFeedbackControllerProvider,
          (_, _) {},
        );
        await container
            .read(diaryFoodLogFeedbackControllerProvider.notifier)
            .enqueue([
              [newFood],
            ]);
        final feedback = container
            .read(diaryFoodLogFeedbackControllerProvider)
            .single;
        expect(feedback.entries.single.totalProtein, 25);
        expect(feedback.before, isNull);
        expect(feedback.after, isNull);
        subscription.close();
        container.dispose();
      }
    },
  );

  test(
    'dashboard with error yields amounts without invented progress',
    () async {
      final newFood = food('new', 25);
      final controller = FakeDiaryDayDashboardController(
        DiaryDayDashboardState(
          data: diaryDashboardLoadedStateForTest(
            selectedDay: day,
            selectedDayEntries: [newFood],
          ).data,
          isFromCache: false,
          isRefreshing: false,
          error: Exception('Backend failure'),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          diaryDayDashboardControllerProvider(
            day,
          ).overrideWith(() => controller),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        diaryFoodLogFeedbackControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      await container
          .read(diaryFoodLogFeedbackControllerProvider.notifier)
          .enqueue([
            [newFood],
          ]);
      final feedback = container
          .read(diaryFoodLogFeedbackControllerProvider)
          .single;
      expect(feedback.entries.single.totalProtein, 25);
      expect(feedback.before, isNull);
      expect(feedback.after, isNull);
    },
  );

  test(
    'dashboard refresh timeout yields amounts without throwing',
    () async {
      final newFood = food('new', 25);
      final controller = _TimeoutThrowingDashboardController(
        diaryDashboardLoadedStateForTest(
          selectedDay: day,
          selectedDayEntries: [newFood],
        ),
      );
      final container = ProviderContainer(
        overrides: [
          diaryDayDashboardControllerProvider(
            day,
          ).overrideWith(() => controller),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        diaryFoodLogFeedbackControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      await container
          .read(diaryFoodLogFeedbackControllerProvider.notifier)
          .enqueue([
            [newFood],
          ]);
      final feedback = container
          .read(diaryFoodLogFeedbackControllerProvider)
          .single;
      expect(feedback.entries.single.totalProtein, 25);
      expect(feedback.before, isNull);
      expect(feedback.after, isNull);
    },
  );

  test(
    'uses refreshAfterMutation instead of retry on the dashboard controller',
    () async {
      final newFood = food('new', 25);
      var refreshAfterMutationCallCount = 0;
      var retryCallCount = 0;
      final controller = _TrackingDashboardController(
        initialState: diaryDashboardLoadedStateForTest(
          selectedDay: day,
          selectedDayEntries: [newFood],
        ),
        onRefreshAfterMutationCalled: () => refreshAfterMutationCallCount += 1,
        onRetryCalled: () => retryCallCount += 1,
      );
      final container = ProviderContainer(
        overrides: [
          diaryDayDashboardControllerProvider(
            day,
          ).overrideWith(() => controller),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        diaryFoodLogFeedbackControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      await container
          .read(diaryFoodLogFeedbackControllerProvider.notifier)
          .enqueue([
            [newFood],
          ]);
      expect(refreshAfterMutationCallCount, 1);
      expect(retryCallCount, 0);
    },
  );
}

class _TimeoutThrowingDashboardController
    extends FakeDiaryDayDashboardController {
  _TimeoutThrowingDashboardController(super.initialState);

  @override
  Future<DiaryDayDashboardState> refreshAfterMutation() async {
    throw TimeoutException('Timed out');
  }
}

class _TrackingDashboardController extends FakeDiaryDayDashboardController {
  _TrackingDashboardController({
    required DiaryDayDashboardState initialState,
    required this.onRefreshAfterMutationCalled,
    required this.onRetryCalled,
  }) : super(initialState);

  final void Function() onRefreshAfterMutationCalled;
  final void Function() onRetryCalled;

  @override
  Future<void> retry() async {
    onRetryCalled();
    await super.retry();
  }

  @override
  Future<DiaryDayDashboardState> refreshAfterMutation() async {
    onRefreshAfterMutationCalled();
    return super.refreshAfterMutation();
  }
}
