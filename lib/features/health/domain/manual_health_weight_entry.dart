import 'package:yamt/features/calories/domain/diary_day_window.dart';

/// Defines manual health weight entry.
class ManualHealthWeightEntry {
  /// Creates an instance.
  ManualHealthWeightEntry({required DateTime day, required this.weightKg})
    : day = DateTime(day.year, day.month, day.day);

  /// The day.
  final DateTime day;

  /// The weight kg.
  final double weightKg;

  /// To json.
  Map<String, Object> toJson() {
    return <String, Object>{
      'day': _formatStorageDay(day),
      'weightKg': weightKg,
    };
  }

  /// From json.
  static ManualHealthWeightEntry? fromJson(Map<String, dynamic> json) {
    final rawDay = json['day'];
    final rawWeight = json['weightKg'];
    if (rawDay is! String || rawWeight is! num) {
      return null;
    }

    final day = _parseStorageDay(rawDay);
    if (day == null || rawWeight <= 0) {
      return null;
    }

    return ManualHealthWeightEntry(day: day, weightKg: rawWeight.toDouble());
  }
}

String _formatStorageDay(DateTime day) {
  final normalizedDay = normalizeDiaryDay(day);
  final month = normalizedDay.month.toString().padLeft(2, '0');
  final date = normalizedDay.day.toString().padLeft(2, '0');
  return '${normalizedDay.year}-$month-$date';
}

DateTime? _parseStorageDay(String rawDay) {
  final parts = rawDay.split('-');
  if (parts.length != 3) {
    return null;
  }

  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }

  return DateTime(year, month, day);
}
