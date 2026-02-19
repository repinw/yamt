import 'dart:convert';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';

part 'fridge_item_repository.g.dart';

const String _fridgeItemsStorageKey = 'inventory_fridge_items_v1';
const String _repositoryLogName = 'PreferencesFridgeItemRepository';

@riverpod
FridgeItemRepository fridgeItemRepository(Ref ref) {
  return PreferencesFridgeItemRepository(
    preferences: ref.read(appPreferencesProvider),
  );
}

/// Persists fridge items used by the inventory feature.
abstract interface class FridgeItemRepository {
  /// Loads all stored items. Returns an empty list if no data exists.
  Future<List<FridgeItem>> readAll();

  /// Replaces all stored items.
  Future<bool> saveAll(List<FridgeItem> items);

  /// Appends items to the existing list.
  Future<bool> appendAll(List<FridgeItem> items);
}

class PreferencesFridgeItemRepository implements FridgeItemRepository {
  PreferencesFridgeItemRepository({required AppPreferences preferences})
    : _preferences = preferences;

  final AppPreferences _preferences;

  @override
  Future<List<FridgeItem>> readAll() async {
    final raw = await _preferences.getString(_fridgeItemsStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const <FridgeItem>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        return const <FridgeItem>[];
      }

      final items = <FridgeItem>[];
      for (var index = 0; index < decoded.length; index++) {
        final entry = decoded[index];
        if (entry is! Map<String, dynamic>) {
          log(
            'Skipping non-map fridge item entry at index $index',
            name: _repositoryLogName,
          );
          continue;
        }

        try {
          items.add(FridgeItem.fromJson(entry));
        } catch (error, stackTrace) {
          log(
            'Skipping corrupted fridge item at index $index',
            name: _repositoryLogName,
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
      return items;
    } catch (error, stackTrace) {
      log(
        'Failed to decode fridge items',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <FridgeItem>[];
    }
  }

  @override
  Future<bool> saveAll(List<FridgeItem> items) {
    final encoded = jsonEncode(
      items.map((item) => item.toJson()).toList(growable: false),
    );
    return _preferences.setString(_fridgeItemsStorageKey, encoded);
  }

  @override
  Future<bool> appendAll(List<FridgeItem> items) async {
    if (items.isEmpty) {
      return true;
    }

    final existing = await readAll();
    final combined = <FridgeItem>[...existing, ...items];
    return saveAll(combined);
  }
}
