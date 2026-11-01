import 'package:meta/meta.dart';
import 'package:yamt/core/domain/meal_type.dart';

/// How the day's kcal target splits over the meals, in whole percent per
/// meal of [MealType.sectionOrder]. The parts add up to 100; a meal at 0 has
/// no part of the day.
@immutable
class DiaryMealShares {
  /// Creates shares from [percents], one per meal of
  /// [MealType.sectionOrder].
  const new(this.percents);

  /// Breakfast 25, lunch 35, dinner 30, snack 10.
  static const DiaryMealShares standard = DiaryMealShares([25, 35, 30, 10]);

  /// Whole percent per meal of [MealType.sectionOrder].
  final List<int> percents;

  /// Reads shares saved by [encode]; null when [value] is not four parts of
  /// at least 0 that add up to 100.
  static DiaryMealShares? decode(String value) {
    final parts = value.split(',').map(int.tryParse).toList();
    if (parts.length != MealType.sectionOrder.length ||
        parts.any((part) => part == null || part < 0) ||
        parts.fold(0, (sum, part) => sum + part!) != 100) {
      return null;
    }
    return DiaryMealShares([for (final part in parts) part!]);
  }

  /// The shares as text for [decode].
  String encode() => percents.join(',');

  /// The share of [meal] as a fraction of the day.
  double of(MealType meal) =>
      percents[MealType.sectionOrder.indexOf(meal)] / 100;

  /// [totalKcal] split by the shares in whole kcal, in section order. The
  /// parts add up to the rounded total: the kcal lost to rounding go to
  /// the parts with the largest remainders.
  List<int> splitKcal(double totalKcal) {
    final total = totalKcal.round();
    final exact = [for (final percent in percents) total * percent / 100];
    final parts = [for (final value in exact) value.floor()];
    final byRemainder = Iterable<int>.generate(parts.length).toList()
      ..sort((a, b) => (exact[b] - parts[b]).compareTo(exact[a] - parts[a]));
    var missing = total - parts.fold(0, (sum, part) => sum + part);
    for (final i in byRemainder) {
      if (missing <= 0) break;
      parts[i]++;
      missing--;
    }
    return parts;
  }

  /// Where each boundary between two meals sits, in percent of the day.
  List<int> get boundaries => [
    for (var i = 1; i < percents.length; i++)
      percents.take(i).fold(0, (sum, part) => sum + part),
  ];

  /// The boundary nearest to [percent], which a drag from there moves. Of
  /// boundaries on the same spot, a drag to the right takes the last and a
  /// drag to the left the first, so a meal at 0 opens in both directions.
  int boundaryAt(int percent, {required bool rightward}) {
    final borders = boundaries;
    var nearest = 0;
    for (var i = 1; i < borders.length; i++) {
      final distance = (borders[i] - percent).abs();
      final best = (borders[nearest] - percent).abs();
      if (distance < best || (distance == best && rightward)) nearest = i;
    }
    return nearest;
  }

  /// The shares with boundary [index] moved to [percent], kept between the
  /// boundaries next to it. A boundary moved onto its neighbour leaves the
  /// meal between them at 0.
  DiaryMealShares moveBoundary(int index, int percent) {
    final edges = [0, ...boundaries, 100];
    edges[index + 1] = percent.clamp(edges[index], edges[index + 2]);
    return DiaryMealShares([
      for (var i = 1; i < edges.length; i++) edges[i] - edges[i - 1],
    ]);
  }

  @override
  bool operator ==(Object other) =>
      other is DiaryMealShares &&
      other.percents.length == percents.length &&
      Iterable<int>.generate(percents.length)
          .every((i) => other.percents[i] == percents[i]);

  @override
  int get hashCode => Object.hashAll(percents);
}
