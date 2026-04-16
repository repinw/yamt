import 'package:cloud_firestore/cloud_firestore.dart';

/// Read positive int.
int? readPositiveInt(Object? value) {
  if (value is int) {
    return value > 0 ? value : null;
  }
  if (value is num) {
    final normalized = value.toInt();
    return normalized > 0 ? normalized : null;
  }
  return null;
}

/// Read positive double.
double? readPositiveDouble(Object? value) {
  if (value is num) {
    final normalized = value.toDouble();
    return normalized > 0 ? normalized : null;
  }
  if (value is String) {
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed != null && parsed > 0) {
      return parsed;
    }
  }
  return null;
}

/// Read date time.
DateTime? readDateTime(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
