import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';

/// When the user's day starts and by when they eat each meal, in minutes
/// after midnight. With the [DiaryMealShares] they say how much of the
/// day's kcal is due at a time of day.
@immutable
class DiaryMealTimes {
  /// Creates times from the day's [start] and the [ends] of the meals in
  /// [MealType.sectionOrder], which never run backwards.
  const new({required this.start, required this.ends});

  /// The day starts at 6:00; breakfast by 9:00, lunch by 13:00, dinner by
  /// 19:00 and the snack by 21:00.
  static const DiaryMealTimes standard = DiaryMealTimes(
    start: 6 * 60,
    ends: [9 * 60, 13 * 60, 19 * 60, 21 * 60],
  );

  /// The last minute of a day.
  static const int lastMinute = 24 * 60 - 1;

  /// Minute of the day the first meal's time begins.
  final int start;

  /// Minute of the day each meal is eaten by, in section order.
  final List<int> ends;

  /// Reads times written by [encode]; null when they are broken.
  static DiaryMealTimes? decode(String value) {
    final parts = value.split(',').map(int.tryParse).toList();
    if (parts.length != MealType.sectionOrder.length + 1 ||
        parts.any((part) => part == null || part < 0 || part > lastMinute)) {
      return null;
    }
    for (var i = 1; i < parts.length; i++) {
      if (parts[i]! < parts[i - 1]!) return null;
    }
    return DiaryMealTimes(
      start: parts.first!,
      ends: [for (final part in parts.skip(1)) part!],
    );
  }

  /// The times as one line of text, for the device settings.
  String encode() => [start, ...ends].join(',');

  /// Minute of the day [meal] is eaten by.
  int endOf(MealType meal) => ends[MealType.sectionOrder.indexOf(meal)];

  /// These times with the day starting at [minute]; meals that would end
  /// before it end at it.
  DiaryMealTimes withStart(int minute) => _withEdge(0, minute);

  /// These times with [meal] eaten by [minute]; the times before and after
  /// it move along, so they stay in order.
  DiaryMealTimes withEnd(MealType meal, int minute) =>
      _withEdge(MealType.sectionOrder.indexOf(meal) + 1, minute);

  DiaryMealTimes _withEdge(int index, int minute) {
    final value = minute.clamp(0, lastMinute);
    final edges = [start, ...ends];
    for (var i = 0; i < edges.length; i++) {
      edges[i] = i == index
          ? value
          : i < index
          ? math.min(edges[i], value)
          : math.max(edges[i], value);
    }
    return DiaryMealTimes(start: edges.first, ends: edges.sublist(1));
  }

  /// The share of the day's kcal due by [minute] after midnight with
  /// [shares]: none before the start, each meal's share by its end, and
  /// rising evenly in between.
  double dueAt(int minute, DiaryMealShares shares) {
    final edges = [start, ...ends];
    var due = 0;
    for (var i = 1; i < edges.length; i++) {
      final part = shares.percents[i - 1];
      if (minute < edges[i]) {
        if (minute <= edges[i - 1]) return due / 100;
        final into = (minute - edges[i - 1]) / (edges[i] - edges[i - 1]);
        return (due + part * into) / 100;
      }
      due += part;
    }
    return due / 100;
  }

  @override
  bool operator ==(Object other) =>
      other is DiaryMealTimes &&
      other.start == start &&
      other.ends.length == ends.length &&
      Iterable<int>.generate(ends.length)
          .every((i) => other.ends[i] == ends[i]);

  @override
  int get hashCode => Object.hash(start, Object.hashAll(ends));
}
