import 'package:yamt/l10n/app_localizations.dart';

/// Context badge type shown above statistics content.
enum StatisticsContextKind { household, personal }

/// Top-level tabs in the statistics area.
enum StatisticsTab {
  spending,
  waste,
  calories;

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

/// Global timeframe filter used across the statistics area.
enum StatisticsTimeframe {
  week(7),
  month(30),
  year(365),
  total(null);

  const StatisticsTimeframe(this.dayCount);

  final int? dayCount;

  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      StatisticsTimeframe.week => l10n.statisticsTimeframeWeek,
      StatisticsTimeframe.month => l10n.statisticsTimeframeMonth,
      StatisticsTimeframe.year => l10n.statisticsTimeframeYear,
      StatisticsTimeframe.total => l10n.statisticsTimeframeTotal,
    };
  }
}
