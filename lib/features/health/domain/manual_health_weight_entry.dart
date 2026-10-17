import 'package:yamt/core/domain/local_day_window.dart';

/// Defines manual health weight entry.
class ManualHealthWeightEntry {
  /// Creates an instance.
  new({required DateTime day, required this.weightKg, this.recordedAt, this.id})
    : day = DateTime(day.year, day.month, day.day);

  /// The day.
  final DateTime day;

  /// The weight kg.
  final double weightKg;

  /// When the user weighed.
  ///
  /// Temporary compatibility, added in 3.9.0: entries of 3.8.1 and older
  /// have no time and the day as [id]. A migration gives them a time once
  /// the minimum version is 3.9.0 or newer.
  final DateTime? recordedAt;

  /// The id of the stored entry, or `null` before it is stored.
  final String? id;

  /// When the user weighed, or the start of [day] without a time.
  DateTime get at => recordedAt ?? day;

  /// The document id: [id], or the day without one, as 3.8.1 stores all.
  String get storageId => id ?? manualWeightDayId(day);

  /// To json.
  Map<String, Object> toJson() {
    return <String, Object>{
      // Temporary compatibility, added in 3.9.0: 3.8.1 reads only the day.
      'day': _formatStorageDay(day),
      'weightKg': weightKg,
      if (recordedAt case final recordedAt?)
        'recordedAt': recordedAt.toUtc().toIso8601String(),
    };
  }

  /// From json of the entry stored under [id].
  static ManualHealthWeightEntry? fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final rawDay = json['day'];
    final rawWeight = json['weightKg'];
    final rawRecordedAt = json['recordedAt'];
    if (rawDay is! String ||
        rawWeight is! num ||
        (rawRecordedAt != null && rawRecordedAt is! String)) {
      return null;
    }

    final day = _parseStorageDay(rawDay);
    final recordedAt = rawRecordedAt is String
        ? DateTime.tryParse(rawRecordedAt)?.toLocal()
        : null;
    if (day == null ||
        rawWeight <= 0 ||
        (rawRecordedAt != null && recordedAt == null)) {
      return null;
    }

    return ManualHealthWeightEntry(
      // The writer's day, so the day matches the id and 3.8.1 in every zone.
      day: day,
      weightKg: rawWeight.toDouble(),
      recordedAt: recordedAt,
      id: id,
    );
  }
}

/// The document id of the weight of [day] without an own id.
String manualWeightDayId(DateTime day) => _formatStorageDay(day);

String _formatStorageDay(DateTime day) {
  final normalizedDay = normalizeLocalDay(day);
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
