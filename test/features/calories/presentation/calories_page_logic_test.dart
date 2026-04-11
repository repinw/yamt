import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yamt/features/calories/presentation/calories_page.dart';
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

    final resolved = resolveDisplayedWeekOverview(loading, goalKcal: 2200);

    expect(resolved, same(previous));
  });

  test('resolveDisplayedWeekOverview falls back without previous value', () {
    final resolved = resolveDisplayedWeekOverview(
      const AsyncLoading<CalorieWeekOverview>(),
      goalKcal: 2200,
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
}
