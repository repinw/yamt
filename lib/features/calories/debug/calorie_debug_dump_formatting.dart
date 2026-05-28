// Debug formatting helpers are public only for file splitting.
// ignore_for_file: public_member_api_docs

import 'package:yamt/features/calories/domain/diary_day_window.dart';

class CalorieDebugDumpRow {
  const CalorieDebugDumpRow({
    required this.sortAt,
    required this.typeOrder,
    required this.cells,
  }) : assert(cells.length == 13, 'Debug dump rows must have 13 cells.');

  final DateTime sortAt;
  final int typeOrder;
  final List<String> cells;
}

String buildCalorieDebugMarkdownTable(
  List<CalorieDebugDumpRow> rows, {
  Set<String> separatorDays = const <String>{},
}) {
  const headers = [
    'date',
    'time',
    'type',
    'name',
    'kcal',
    'protein_g',
    'carbs_g',
    'fat_g',
    'amount',
    'steps',
    'weight_kg',
    'source',
    'extra',
  ];
  final buffer = StringBuffer()
    ..writeln(_tableLine(headers))
    ..writeln(_tableLine(List<String>.filled(headers.length, '---')));
  final separatedDays = <String>{};
  for (final row in rows) {
    final dayKey = diaryDayKey(row.sortAt);
    if (separatorDays.contains(dayKey) && separatedDays.add(dayKey)) {
      buffer.writeln();
    }
    buffer.writeln(_tableLine(row.cells));
  }
  return buffer.toString();
}

String formatCalorieDebugNumber(num? value) {
  if (value == null) {
    return '';
  }
  final asDouble = value.toDouble();
  if (!asDouble.isFinite) {
    return '';
  }
  if (asDouble == asDouble.roundToDouble()) {
    return asDouble.round().toString();
  }
  final rounded = (asDouble * 100).roundToDouble() / 100;
  if (rounded == rounded.roundToDouble()) {
    return rounded.round().toString();
  }
  return rounded.toStringAsFixed(2);
}

String formatCalorieDebugDay(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

String formatCalorieDebugTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  if (local.hour == 0 &&
      local.minute == 0 &&
      local.second == 0 &&
      local.millisecond == 0 &&
      local.microsecond == 0) {
    return '';
  }
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}:'
      '${local.second.toString().padLeft(2, '0')}';
}

int compareCalorieDebugRows(
  CalorieDebugDumpRow left,
  CalorieDebugDumpRow right,
) {
  final timeCompare = left.sortAt.compareTo(right.sortAt);
  if (timeCompare != 0) {
    return timeCompare;
  }
  return left.typeOrder.compareTo(right.typeOrder);
}

String _tableLine(List<String> cells) {
  return '| ${cells.map(_escapeCell).join(' | ')} |';
}

String _escapeCell(String value) {
  return value
      .replaceAll('\n', ' ')
      .replaceAll('\r', ' ')
      .replaceAll('|', r'\|');
}
