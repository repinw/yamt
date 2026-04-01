import 'package:flutter/material.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Context badge type shown above statistics content.
enum StatisticsContextKind { household, personal }

/// Top-level tabs in the statistics area.
enum StatisticsTab {
  spending('spending'),
  waste('waste'),
  calories('calories');

  const StatisticsTab(this.routeKey);

  final String routeKey;

  StatisticsContextKind get contextKind {
    return switch (this) {
      StatisticsTab.calories => StatisticsContextKind.personal,
      StatisticsTab.spending ||
      StatisticsTab.waste => StatisticsContextKind.household,
    };
  }

  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      StatisticsTab.spending => l10n.statisticsTabSpending,
      StatisticsTab.waste => l10n.statisticsTabWaste,
      StatisticsTab.calories => l10n.statisticsTabCalories,
    };
  }
}

/// Global timeframe filter used across the statistics flow.
enum StatisticsTimeframe {
  week('7d', 7),
  month('30d', 30),
  year('365d', 365),
  total('all', null);

  const StatisticsTimeframe(this.routeKey, this.dayCount);

  final String routeKey;
  final int? dayCount;

  static StatisticsTimeframe fromRouteKey(String? value) {
    for (final timeframe in values) {
      if (timeframe.routeKey == value) {
        return timeframe;
      }
    }
    return StatisticsTimeframe.week;
  }

  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      StatisticsTimeframe.week => l10n.statisticsTimeframeWeek,
      StatisticsTimeframe.month => l10n.statisticsTimeframeMonth,
      StatisticsTimeframe.year => l10n.statisticsTimeframeYear,
      StatisticsTimeframe.total => l10n.statisticsTimeframeTotal,
    };
  }

  DateTime startDate({required DateTime now, DateTime? firstAvailableDate}) {
    final today = DateUtils.dateOnly(now);
    if (this == StatisticsTimeframe.total) {
      final resolvedFirstDay = DateUtils.dateOnly(
        firstAvailableDate ?? today.subtract(const Duration(days: 6)),
      );
      return resolvedFirstDay.isAfter(today) ? today : resolvedFirstDay;
    }

    final days = dayCount ?? 7;
    return today.subtract(Duration(days: days - 1));
  }
}
