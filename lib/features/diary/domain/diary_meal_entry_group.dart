import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';

/// Identical foods eaten in one meal, e.g. the same oats logged five times.
class DiaryMealEntryGroup {
  /// Creates a group of at least one entry.
  const new(this.entries) : assert(entries.length > 0, 'Group is empty.');

  /// Logged entries in logging order.
  final List<DiaryMealEntry> entries;

  /// Whether more than one entry was merged.
  bool get isMerged => entries.length > 1;

  /// One entry with summed kcal, macros, amount, and portions. It keeps the
  /// id, name, image, and unit of the first entry.
  DiaryMealEntry get combined {
    final first = entries.first;
    if (!isMerged) {
      return first;
    }
    double sum(double Function(DiaryMealEntry entry) value) =>
        entries.fold<double>(0, (total, entry) => total + value(entry));
    final amounts = entries.map((entry) => entry.consumedAmount);
    final portions = entries.map((entry) => entry.bundleConsumedPortions);
    return DiaryMealEntry(
      id: first.id,
      mealType: first.mealType,
      name: first.name,
      imageUrl: first.imageUrl,
      imageAssetId: first.imageAssetId,
      totalKcal: sum((entry) => entry.totalKcal),
      totalProtein: sum((entry) => entry.totalProtein),
      totalCarbs: sum((entry) => entry.totalCarbs),
      totalFat: sum((entry) => entry.totalFat),
      consumedAmount: amounts.contains(null)
          ? null
          : amounts.fold<double>(0, (total, amount) => total + amount!),
      consumedUnit: first.consumedUnit,
      bundleConsumedPortions: portions.contains(null)
          ? null
          : portions.fold<num>(0, (total, count) => total + count!),
      bundleTotalPortions: first.bundleTotalPortions,
    );
  }
}

/// Groups entries that show the same food: same name, image, unit, and
/// portion size. Groups keep the order in which each food was first logged.
List<DiaryMealEntryGroup> groupDiaryMealEntries(List<DiaryMealEntry> entries) {
  final groups =
      <(String, String?, String?, ConsumedUnit?, int?), List<DiaryMealEntry>>{};
  for (final entry in entries) {
    final key = (
      entry.name,
      entry.imageUrl,
      entry.imageAssetId,
      entry.consumedUnit,
      entry.bundleTotalPortions,
    );
    (groups[key] ??= <DiaryMealEntry>[]).add(entry);
  }
  return [
    for (final group in groups.values)
      DiaryMealEntryGroup(List<DiaryMealEntry>.unmodifiable(group)),
  ];
}
