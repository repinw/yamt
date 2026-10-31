import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_balance_loaded_metrics.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_card_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_budget_card_data_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_provider.dart';

final _day = DateTime(2026, 4, 27);

class _LoadingDashboard extends DiaryDayDashboardController {
  @override
  DiaryDayDashboardState build(DateTime selectedDay) =>
      const DiaryDayDashboardState(
        data: null,
        isFromCache: false,
        isRefreshing: true,
        error: null,
      );
}

DiaryBalanceCardData _card({bool isPauseDay = false}) =>
    DiaryBalanceCardData.loaded(
      loadedMetrics: DiaryBalanceLoadedMetrics(
        selectedDay: _day,
        daily: const DiaryDailyBalanceMetrics(
          bufferAdjustmentKcal: 0,
          realEatenKcal: 0,
          eatenKcal: 0,
          realDayLeftKcal: 2000,
          dayLeftKcal: 2000,
          targetKcal: 2000,
        ),
        state: DiaryBalanceLoadedState(
          isPauseDay: isPauseDay,
          showGameControls: false,
          runWeekNumber: 1,
        ),
        runWeekStart: _day,
      ),
    );

ProviderContainer _container({DiaryBalanceCardData? card, double? paceShare}) {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => DateTime(2026, 4, 27, 12)),
      diaryDayDashboardControllerProvider(_day)
          .overrideWith(_LoadingDashboard.new),
      diaryBalanceCardProvider(_day).overrideWithValue(card),
      diaryPaceShareProvider(_day).overrideWithValue(paceShare),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('is null while the balance loads', () {
    final container = _container(paceShare: 0.5);

    expect(container.read(diaryBudgetCardDataProvider(_day)), isNull);
  });

  test('passes the pace share through as kcal of the target', () {
    final container = _container(card: _card(), paceShare: 0.25);

    final data = container.read(diaryBudgetCardDataProvider(_day))!;

    expect(data.paceKcal, 500);
    expect(data.day, _day);
    expect(data.macros, isEmpty);
  });

  test('has no pace without a share', () {
    final container = _container(card: _card());

    expect(container.read(diaryBudgetCardDataProvider(_day))!.paceKcal, isNull);
  });

  test('has no pace on a pause day', () {
    final container = _container(card: _card(isPauseDay: true), paceShare: 0.5);

    final data = container.read(diaryBudgetCardDataProvider(_day))!;

    expect(data.isPauseDay, isTrue);
    expect(data.paceKcal, isNull);
  });
}
