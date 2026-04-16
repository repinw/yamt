import 'package:yamt/l10n/app_localizations.dart';

/// Context badge type shown above statistics content.
enum StatisticsContextKind {
  /// Household.
  household,

  /// Personal.
  personal,
}

/// Top-level tabs in the statistics area.
enum StatisticsTab {
  /// Documented member.
  spending,

  /// Documented member.
  waste,

  /// Documented member.
  calories
  ;

  /// The context kind.
  StatisticsContextKind get contextKind {
    return switch (this) {
      StatisticsTab.calories => StatisticsContextKind.personal,
      StatisticsTab.spending ||
      StatisticsTab.waste => StatisticsContextKind.household,
    };
  }

  /// Localized label.
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
  /// Week.
  week(7),

  /// Month.
  month(30),

  /// Year.
  year(365),

  /// Total.
  total(null)
  ;

  const StatisticsTimeframe(this.dayCount);

  /// The day count.
  final int? dayCount;

  /// Localized label.
  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      StatisticsTimeframe.week => l10n.statisticsTimeframeWeek,
      StatisticsTimeframe.month => l10n.statisticsTimeframeMonth,
      StatisticsTimeframe.year => l10n.statisticsTimeframeYear,
      StatisticsTimeframe.total => l10n.statisticsTimeframeTotal,
    };
  }
}
