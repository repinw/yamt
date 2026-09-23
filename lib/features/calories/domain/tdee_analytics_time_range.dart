/// Available time ranges for filtering TDEE analytics.
enum TdeeAnalyticsTimeRange {
  /// Last 7 days.
  days7(7),

  /// Last 14 days.
  days14(14),

  /// Last 21 days.
  days21(21),

  /// Last 28 days (full learned TDEE window).
  days28(28),

  /// Last 30 days / month.
  month(30),

  /// Entire duration of selected cycle or all cycles.
  all(null);

  new(this.dayCount);

  /// Number of days or null for all.
  final int? dayCount;
}
