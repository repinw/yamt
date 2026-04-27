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
}
