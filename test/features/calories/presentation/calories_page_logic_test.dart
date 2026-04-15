import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/calories_page_logic.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_visible_window_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _positiveAccentColor = Color(0xFF0D47A1);
const _warningAccentColor = Color(0xFFB3261E);

CalorieWeekOverview _overview({
  required int dayOffset,
  required double totalConsumedKcal,
  required double totalGoalKcal,
  required double remainingKcal,
}) {
  return CalorieWeekOverview(
    days: List<CalorieWeekDayOverview>.unmodifiable([
      CalorieWeekDayOverview(
        date: DateTime(2026, 3, 27).subtract(Duration(days: dayOffset)),
        totalKcal: totalConsumedKcal,
        goalKcal: totalGoalKcal,
        entryCount: 1,
      ),
    ]),
    totalConsumedKcal: totalConsumedKcal,
    totalGoalKcal: totalGoalKcal,
    remainingKcal: remainingKcal,
    balanceStartDate: DateTime(2026, 3, 27).subtract(Duration(days: dayOffset)),
    carryoverBeforeTodayKcal: remainingKcal,
    todayFlexibleGoalKcal: totalGoalKcal,
    goalStartsInFuture: false,
    nextGoalStartDate: null,
  );
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  test('resolveDisplayedWeekOverview keeps previous value during refresh', () {
    final previous = _overview(
      dayOffset: 0,
      totalConsumedKcal: 1600,
      totalGoalKcal: 2200,
      remainingKcal: 600,
    );
    // ignore: invalid_use_of_internal_member
    final loading = const AsyncLoading<CalorieWeekOverview>().copyWithPrevious(
      AsyncData<CalorieWeekOverview>(previous),
    );

    final visibleWindowEnd = DateTime(2026, 3, 27);

    expect(
      resolveDisplayedWeekOverview(
        loading,
        goalKcal: 2200,
        visibleWindowEnd: visibleWindowEnd,
      ),
      same(previous),
    );
  });

  test('resolveDisplayedWeekOverview falls back without previous value', () {
    final visibleWindowEnd = DateTime(2026, 3, 27);
    final resolved = resolveDisplayedWeekOverview(
      const AsyncLoading<CalorieWeekOverview>(),
      goalKcal: 2200,
      visibleWindowEnd: visibleWindowEnd,
    );

    expect(resolved.days, hasLength(7));
    expect(resolved.totalConsumedKcal, 0);
    expect(resolved.totalGoalKcal, 15400);
    expect(resolved.remainingKcal, 15400);
  });

  test(
    'week balance banner content shows started today when balance starts now',
    () {
      final overview = _overview(
        dayOffset: 0,
        totalConsumedKcal: 1600,
        totalGoalKcal: 2200,
        remainingKcal: 0,
      );

      final content = resolveWeekBalanceSummaryBannerContent(
        overview: overview,
        l10n: l10n,
        referenceNow: DateTime(2026, 3, 27, 10),
        positiveAccentColor: _positiveAccentColor,
        warningColor: _warningAccentColor,
      );

      expect(content.message, l10n.caloriesWeekBalanceStartedToday);
      expect(content.accentColor, _positiveAccentColor);
      expect(
        content.backgroundColor,
        _positiveAccentColor.withValues(alpha: 0.08),
      );
    },
  );

  test(
    'week balance banner content shows saved state for positive carryover',
    () {
      final overview = _overview(
        dayOffset: 2,
        totalConsumedKcal: 1600,
        totalGoalKcal: 2200,
        remainingKcal: 420,
      );

      final content = resolveWeekBalanceSummaryBannerContent(
        overview: overview,
        l10n: l10n,
        referenceNow: DateTime(2026, 3, 27, 10),
        positiveAccentColor: _positiveAccentColor,
        warningColor: _warningAccentColor,
      );

      expect(content.message, l10n.caloriesWeekBalanceSaved(420));
      expect(content.accentColor, _positiveAccentColor);
      expect(
        content.backgroundColor,
        _positiveAccentColor.withValues(alpha: 0.08),
      );
    },
  );

  test(
    'week balance banner content shows overspent state for negative carryover',
    () {
      final overview = _overview(
        dayOffset: 2,
        totalConsumedKcal: 2600,
        totalGoalKcal: 2200,
        remainingKcal: -250,
      );

      final content = resolveWeekBalanceSummaryBannerContent(
        overview: overview,
        l10n: l10n,
        referenceNow: DateTime(2026, 3, 27, 10),
        positiveAccentColor: _positiveAccentColor,
        warningColor: _warningAccentColor,
      );

      expect(content.message, l10n.caloriesWeekBalanceOverspent(250));
      expect(content.accentColor, _warningAccentColor);
      expect(
        content.backgroundColor,
        _warningAccentColor.withValues(alpha: 0.08),
      );
    },
  );

  test('week balance banner content shows stable state for zero carryover', () {
    final overview = _overview(
      dayOffset: 2,
      totalConsumedKcal: 2200,
      totalGoalKcal: 2200,
      remainingKcal: 0,
    );

    final content = resolveWeekBalanceSummaryBannerContent(
      overview: overview,
      l10n: l10n,
      referenceNow: DateTime(2026, 3, 27, 10),
      positiveAccentColor: _positiveAccentColor,
      warningColor: _warningAccentColor,
    );

    expect(content.message, l10n.caloriesWeekBalanceStable);
    expect(content.accentColor, _positiveAccentColor);
    expect(
      content.backgroundColor,
      _positiveAccentColor.withValues(alpha: 0.08),
    );
  });

  test(
    'week balance banner content shows future-start state for upcoming goals',
    () {
      final sourceOverview = _overview(
        dayOffset: 0,
        totalConsumedKcal: 0,
        totalGoalKcal: 2200,
        remainingKcal: 0,
      );
      final overview = CalorieWeekOverview(
        days: sourceOverview.days,
        totalConsumedKcal: sourceOverview.totalConsumedKcal,
        totalGoalKcal: sourceOverview.totalGoalKcal,
        remainingKcal: sourceOverview.remainingKcal,
        balanceStartDate: sourceOverview.balanceStartDate,
        carryoverBeforeTodayKcal: sourceOverview.carryoverBeforeTodayKcal,
        todayFlexibleGoalKcal: sourceOverview.todayFlexibleGoalKcal,
        goalStartsInFuture: true,
        nextGoalStartDate: DateTime(2026, 3, 28),
      );

      final content = resolveWeekBalanceSummaryBannerContent(
        overview: overview,
        l10n: l10n,
        referenceNow: DateTime(2026, 3, 27, 10),
        positiveAccentColor: _positiveAccentColor,
        warningColor: _warningAccentColor,
      );

      final startLabel = DateFormat.yMMMd(
        l10n.localeName,
      ).format(DateTime(2026, 3, 28));
      expect(content.message, l10n.caloriesWeekBalanceStartsLater(startLabel));
    },
  );

  test(
    'visible-window settle keeps the selected day when it stays visible',
    () {
      final selectedDay = DateTime(2026, 3, 5);

      final resolved = resolveSelectedDiaryDayForVisibleWindowChange(
        previousWindowEnd: DateTime(2026, 3, 8),
        nextWindowEnd: DateTime(2026, 3, 7),
        selectedDay: selectedDay,
      );

      expect(resolved, selectedDay);
    },
  );

  test(
    'visible-window settle picks the right edge when swiping to older days',
    () {
      final resolved = resolveSelectedDiaryDayForVisibleWindowChange(
        previousWindowEnd: DateTime(2026, 3, 8),
        nextWindowEnd: DateTime(2026, 3, 7),
        selectedDay: DateTime(2026, 3, 8),
      );

      expect(resolved, DateTime(2026, 3, 7));
    },
  );

  test(
    'visible-window settle picks the left edge when swiping to newer days',
    () {
      final resolved = resolveSelectedDiaryDayForVisibleWindowChange(
        previousWindowEnd: DateTime(2026, 3, 7),
        nextWindowEnd: DateTime(2026, 3, 8),
        selectedDay: DateTime(2026, 3, 1),
      );

      expect(resolved, DateTime(2026, 3, 2));
    },
  );

  testWidgets(
    'handleVisibleWindowSettled keeps selected day when still visible',
    (tester) async {
      WidgetRef? widgetRef;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                widgetRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final ref = widgetRef!;
      ref
          .read(calorieVisibleWindowControllerProvider.notifier)
          .setWindowEnd(DateTime(2026, 3, 8));
      ref
          .read(calorieDayControllerProvider.notifier)
          .setDay(DateTime(2026, 3, 5));

      handleVisibleWindowSettled(ref, DateTime(2026, 3, 7));

      expect(
        ref.read(calorieVisibleWindowControllerProvider),
        DateTime(2026, 3, 7),
      );
      expect(ref.read(calorieDayControllerProvider), DateTime(2026, 3, 5));
    },
  );

  testWidgets(
    'handleVisibleWindowSettled moves selected day to new edge when needed',
    (tester) async {
      WidgetRef? widgetRef;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                widgetRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final ref = widgetRef!;
      ref
          .read(calorieVisibleWindowControllerProvider.notifier)
          .setWindowEnd(DateTime(2026, 3, 8));
      ref
          .read(calorieDayControllerProvider.notifier)
          .setDay(DateTime(2026, 3, 8));

      handleVisibleWindowSettled(ref, DateTime(2026, 3, 7));

      expect(
        ref.read(calorieVisibleWindowControllerProvider),
        DateTime(2026, 3, 7),
      );
      expect(ref.read(calorieDayControllerProvider), DateTime(2026, 3, 7));
    },
  );
}
