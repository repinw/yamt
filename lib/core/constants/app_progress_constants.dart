/// Sizes of the Fortschritt tab: day bars, charts, and legends.
abstract final class AppProgress {
  /// Height of one quarter segment of a day bar.
  static const double dayBarHeight = 10;

  /// Gap between the quarter segments of a day bar.
  static const double dayBarGap = 3;

  /// Number of quarter segments in a day bar.
  static const int dayBarSegments = 4;

  /// Width of the weekday label in a day row.
  static const double dayLabelWidth = 24;

  /// Width of the day type emoji in a day row.
  static const double dayTypeWidth = 20;

  /// Width of the kcal value at the end of a day row.
  static const double dayValueWidth = 52;

  /// Height of a bar in the training and rest day comparison.
  static const double compareBarHeight = 12;

  /// Width of the value at the end of a comparison bar.
  static const double compareValueWidth = 76;

  /// Height of the weight and the TDEE chart.
  static const double chartHeight = 132;

  /// Smallest kcal range that the TDEE chart spans.
  static const double tdeeMinRangeKcal = 200;

  /// Edge length of a weigh-in square in the weight chart.
  static const double weighInSize = 5;

  /// Edge length of the square that marks the latest value in a chart.
  static const double latestPointSize = 10;

  /// Edge length of a check-in square in the TDEE chart.
  static const double checkInPointSize = 8;

  /// Width of the trend line in a chart.
  static const double trendStroke = 2.5;

  /// Width of the base line of a chart.
  static const double baseStroke = 2;

  /// Width of a thin line in a chart, such as a tick or a grid line.
  static const double thinStroke = 1;

  /// Length of a dash in a dashed chart line.
  static const double dash = 4;

  /// Space above a chart's values for the goal marker labels.
  static const double markerLabelSpace = 16;

  /// Gap between a goal marker line and its label.
  static const double markerLabelGap = 4;

  /// Most days for which a chart draws one tick per day.
  static const int dailyTickMaxDays = 60;

  /// Most days for which a chart draws one long tick per week.
  static const int weeklyTickMaxDays = 180;

  /// Length of a long tick on the chart base line.
  static const double longTick = 10;

  /// Length of a short tick on the chart base line.
  static const double shortTick = 5;

  /// Space under the chart base line for its ticks.
  static const double chartBottomInset = 10;

  /// Edge length of a color swatch in a legend.
  static const double legendSwatch = 8;

  /// Width of one stripe of the over-goal hatch.
  static const double hatchStripe = 3;

  /// Gap between two stripes of the over-goal hatch.
  static const double hatchGap = 2;

  /// Factor over the larger value that a comparison bar scale reaches.
  static const double compareHeadroom = 1.08;

  /// Opacity of the rest day bar in the comparison.
  static const double restBarOpacity = 0.5;

  /// Opacity of a day that is still ahead.
  static const double futureOpacity = 0.4;
}
