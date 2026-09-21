import 'package:yamt/features/calories/domain/calorie_entry.dart';

/// In-memory cache for calorie entries to serve immediate reads.
class CalorieEntryCache {
  /// Creates an empty entry cache.
  new();

  final _cache = <String, CalorieEntry>{};

  /// Returns the cached entry for [entryId], or `null` if not cached.
  CalorieEntry? get(String entryId) => _cache[entryId];

  /// Stores a single entry in the cache.
  void put(CalorieEntry entry) {
    _cache[entry.id] = entry;
  }

  /// Stores multiple entries in the cache and returns the same list.
  List<CalorieEntry> rememberAll(List<CalorieEntry> entries) {
    for (final entry in entries) {
      _cache[entry.id] = entry;
    }
    return entries;
  }

  /// Removes the entry for [entryId] from the cache.
  void remove(String entryId) {
    _cache.remove(entryId);
  }

  /// Clears all entries from the cache.
  void clear() {
    _cache.clear();
  }
}
