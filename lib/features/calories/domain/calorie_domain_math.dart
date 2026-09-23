/// Shared numeric helpers for calorie domain calculations.
abstract final class CalorieDomainMath {
  /// Returns the arithmetic mean, or zero for empty input.
  static double average(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }
    return values.fold<double>(0, (sum, value) => sum + value) / values.length;
  }

  /// Returns the median, or zero for empty input.
  static double median(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }
    final sorted = List<double>.from(values)..sort();
    final middleIndex = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[middleIndex];
    }
    return (sorted[middleIndex - 1] + sorted[middleIndex]) / 2;
  }

  /// Returns the Theil-Sen slope: the median of all pairwise slopes.
  ///
  /// One outlier changes only a few pairwise slopes, so it barely moves the
  /// result. Returns zero when no two points have different x values.
  static double theilSenSlope(List<({double x, double y})> points) {
    final slopes = <double>[
      for (var i = 0; i < points.length; i++)
        for (var j = i + 1; j < points.length; j++)
          if (points[j].x != points[i].x)
            (points[j].y - points[i].y) / (points[j].x - points[i].x),
    ];
    return median(slopes);
  }
}
