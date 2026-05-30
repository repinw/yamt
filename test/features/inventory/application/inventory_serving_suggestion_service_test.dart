import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_serving_suggestion_service.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_serving_suggestion.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_serving_suggestion_repository_contract.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

typedef _RecordCall = ({
  String foodFingerprint,
  String? globalFoodItemId,
  double amount,
  ConsumedUnit unit,
  DateTime selectedAt,
  String? label,
});

class _FakeGlobalFoodServingSuggestionRepository
    implements GlobalFoodServingSuggestionRepository {
  GlobalFoodServingSuggestionSet nextSuggestions =
      const GlobalFoodServingSuggestionSet.empty();
  Exception? recordFailure;
  final readCalls =
      <({String foodFingerprint, String? globalFoodItemId, int limit})>[];
  final recordCalls = <_RecordCall>[];

  @override
  Future<GlobalFoodServingSuggestionSet> readSuggestions({
    required String foodFingerprint,
    String? globalFoodItemId,
    int limit = 5,
  }) async {
    readCalls.add((
      foodFingerprint: foodFingerprint,
      globalFoodItemId: globalFoodItemId,
      limit: limit,
    ));
    return nextSuggestions;
  }

  @override
  Future<void> recordSelection({
    required String foodFingerprint,
    required double amount,
    required ConsumedUnit unit,
    required DateTime selectedAt,
    String? globalFoodItemId,
    String? label,
  }) async {
    final failure = recordFailure;
    if (failure != null) {
      throw failure;
    }
    recordCalls.add((
      foodFingerprint: foodFingerprint,
      globalFoodItemId: globalFoodItemId,
      amount: amount,
      unit: unit,
      selectedAt: selectedAt,
      label: label,
    ));
  }
}

InventoryItem _item() {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Cheese',
    brand: 'Acme',
    entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    foodFingerprint: 'cheese__acme',
    globalFoodItemId: 'off-cheese',
  );
}

void main() {
  test('readSuggestions delegates item identifiers and limit', () async {
    final repository = _FakeGlobalFoodServingSuggestionRepository()
      ..nextSuggestions = const GlobalFoodServingSuggestionSet(
        personalSuggestion: ServingSizeSuggestion(
          amount: 25,
          unit: ConsumedUnit.grams,
          label: 'Slice',
        ),
      );
    final service = InventoryServingSuggestionService(repository);

    final suggestions = await service.readSuggestions(_item(), limit: 3);

    expect(suggestions.personalSuggestion?.amount, 25);
    expect(repository.readCalls, hasLength(1));
    expect(repository.readCalls.single.foodFingerprint, 'cheese__acme');
    expect(repository.readCalls.single.globalFoodItemId, 'off-cheese');
    expect(repository.readCalls.single.limit, 3);
  });

  test(
    'recordCreatedPortion delegates item identifiers and portion data',
    () async {
      final repository = _FakeGlobalFoodServingSuggestionRepository();
      final service = InventoryServingSuggestionService(repository);
      final selectedAt = DateTime.parse('2026-04-10T10:00:00.000Z');

      await service.recordCreatedPortion(
        item: _item(),
        amount: 25,
        unit: ConsumedUnit.grams,
        label: 'Slice',
        selectedAt: selectedAt,
      );

      expect(repository.recordCalls, hasLength(1));
      expect(repository.recordCalls.single.foodFingerprint, 'cheese__acme');
      expect(repository.recordCalls.single.globalFoodItemId, 'off-cheese');
      expect(repository.recordCalls.single.amount, 25);
      expect(repository.recordCalls.single.unit, ConsumedUnit.grams);
      expect(repository.recordCalls.single.label, 'Slice');
      expect(repository.recordCalls.single.selectedAt, selectedAt);
    },
  );

  test('recordCreatedPortion surfaces repository failures', () async {
    final failure = Exception('no write permission');
    final repository = _FakeGlobalFoodServingSuggestionRepository()
      ..recordFailure = failure;
    final service = InventoryServingSuggestionService(repository);

    expect(
      service.recordCreatedPortion(
        item: _item(),
        amount: 25,
        unit: ConsumedUnit.grams,
        selectedAt: DateTime.parse('2026-04-10T10:00:00.000Z'),
      ),
      throwsA(same(failure)),
    );
  });

  test(
    'recordSelection delegates explicit identifiers and portion data',
    () async {
      final repository = _FakeGlobalFoodServingSuggestionRepository();
      final service = InventoryServingSuggestionService(repository);
      final selectedAt = DateTime.parse('2026-04-10T10:00:00.000Z');

      await service.recordSelection(
        foodFingerprint: 'cheese__acme',
        globalFoodItemId: 'off-cheese',
        amount: 25,
        unit: ConsumedUnit.grams,
        label: 'Slice',
        selectedAt: selectedAt,
      );

      expect(repository.recordCalls, hasLength(1));
      expect(repository.recordCalls.single.foodFingerprint, 'cheese__acme');
      expect(repository.recordCalls.single.globalFoodItemId, 'off-cheese');
      expect(repository.recordCalls.single.amount, 25);
      expect(repository.recordCalls.single.unit, ConsumedUnit.grams);
      expect(repository.recordCalls.single.label, 'Slice');
      expect(repository.recordCalls.single.selectedAt, selectedAt);
    },
  );

  test('recordSelection catches and logs repository failures', () async {
    final failure = Exception('network unavailable');
    final repository = _FakeGlobalFoodServingSuggestionRepository()
      ..recordFailure = failure;
    String? loggedMessage;
    String? loggedName;
    Object? loggedError;
    StackTrace? loggedStackTrace;
    void logger(
      String message, {
      String name = '',
      Object? error,
      StackTrace? stackTrace,
    }) {
      loggedMessage = message;
      loggedName = name;
      loggedError = error;
      loggedStackTrace = stackTrace;
    }

    final service = InventoryServingSuggestionService(
      repository,
      logger: logger,
    );

    await service.recordSelection(
      foodFingerprint: 'cheese__acme',
      globalFoodItemId: 'off-cheese',
      amount: 25,
      unit: ConsumedUnit.grams,
      selectedAt: DateTime.parse('2026-04-10T10:00:00.000Z'),
    );

    expect(repository.recordCalls, isEmpty);
    expect(
      loggedMessage,
      'Failed to record inventory serving suggestion.',
    );
    expect(loggedName, 'InventoryServingSuggestionService');
    expect(loggedError, same(failure));
    expect(loggedStackTrace, isNotNull);
  });
}
