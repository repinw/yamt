import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/inventory/data/fridge_item_repository.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';

class _FakeAppPreferences implements AppPreferences {
  _FakeAppPreferences({Map<String, Object>? initialValues})
    : _values = initialValues ?? <String, Object>{};

  final Map<String, Object> _values;

  @override
  String? getStringSync(String key) {
    return _values[key] as String?;
  }

  @override
  int? getIntSync(String key) {
    return _values[key] as int?;
  }

  @override
  Future<String?> getString(String key) async {
    return _values[key] as String?;
  }

  @override
  Future<int?> getInt(String key) async {
    return _values[key] as int?;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _values[key] = value;
    return true;
  }
}

class _DelayedFakeAppPreferences extends _FakeAppPreferences {
  _DelayedFakeAppPreferences();

  @override
  Future<String?> getString(String key) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return super.getString(key);
  }

  @override
  Future<bool> setString(String key, String value) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return super.setString(key, value);
  }
}

FridgeItem _item(String id) {
  return FridgeItem(
    id: id,
    name: 'Milk',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    unitPrice: 1.0,
  );
}

void main() {
  test('readAll returns empty list if nothing is stored', () async {
    final repository = PreferencesFridgeItemRepository(
      preferences: _FakeAppPreferences(),
    );

    final items = await repository.readAll();

    expect(items, isEmpty);
  });

  test('appendAll persists items and keeps existing entries', () async {
    final repository = PreferencesFridgeItemRepository(
      preferences: _FakeAppPreferences(),
    );

    final firstSave = await repository.appendAll(<FridgeItem>[_item('a')]);
    final secondSave = await repository.appendAll(<FridgeItem>[_item('b')]);
    final items = await repository.readAll();

    expect(firstSave, isTrue);
    expect(secondSave, isTrue);
    expect(items, hasLength(2));
    expect(items[0].id, 'a');
    expect(items[1].id, 'b');
  });

  test('readAll returns empty list for invalid json payload', () async {
    final prefs = _FakeAppPreferences(
      initialValues: <String, Object>{
        'inventory_fridge_items_v1': '{not-valid-json',
      },
    );
    final repository = PreferencesFridgeItemRepository(preferences: prefs);

    final items = await repository.readAll();

    expect(items, isEmpty);
  });

  test(
    'readAll keeps valid entries when list contains corrupted items',
    () async {
      final validA = _item('a').toJson();
      final validB = _item('b').toJson();
      final corrupted = <String, dynamic>{'id': 123};

      final prefs = _FakeAppPreferences(
        initialValues: <String, Object>{
          'inventory_fridge_items_v1': jsonEncode(<Object?>[
            validA,
            corrupted,
            validB,
          ]),
        },
      );
      final repository = PreferencesFridgeItemRepository(preferences: prefs);

      final items = await repository.readAll();

      expect(items, hasLength(2));
      expect(items[0].id, 'a');
      expect(items[1].id, 'b');
    },
  );

  test('appendAll writes are serialized for concurrent calls', () async {
    final prefs = _DelayedFakeAppPreferences();
    final repository = PreferencesFridgeItemRepository(preferences: prefs);

    final writeA = repository.appendAll(<FridgeItem>[_item('a')]);
    final writeB = repository.appendAll(<FridgeItem>[_item('b')]);
    final results = await Future.wait(<Future<bool>>[writeA, writeB]);
    final items = await repository.readAll();

    expect(results.every((saved) => saved), isTrue);
    expect(items, hasLength(2));
    expect(items[0].id, 'a');
    expect(items[1].id, 'b');
  });
}
