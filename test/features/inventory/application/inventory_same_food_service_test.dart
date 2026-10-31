import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/inventory/application/inventory_eat_service.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_same_food_service.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';

class _MockItems extends Mock implements InventoryItemRepository;

class _MockPendings extends Mock implements InventoryPendingConsumptionStore;

class _MockEatService extends Mock implements InventoryEatService;

final _day = DateTime(2026, 10, 31, 8);

const _nutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 400,
  per100Protein: 10,
  per100Carbs: 60,
  per100Fat: 12,
);

InventoryItem _oats(String id, {int currentAmount = 500, String? barcode}) =>
    InventoryItem.create(
      id: id,
      name: 'Oats',
      brand: 'Kölln',
      barcode: barcode,
      nutrition: _nutrition,
      entryDate: DateTime(2026, 9),
      storeName: 'Rewe',
      quantity: 1,
      initialAmount: 500,
      currentAmount: currentAmount,
      amountUnit: InventoryAmountUnit.gram,
    );

CalorieEntry _entry() => CalorieEntry.create(
  id: 'entry-1',
  userId: 'user-1',
  name: 'Oats',
  brand: 'Kölln',
  mealType: MealType.breakfast,
  consumedAmount: 60,
  consumedUnit: ConsumedUnit.grams,
  per100Kcal: 400,
  per100Protein: 10,
  per100Carbs: 60,
  per100Fat: 12,
  sourceInventoryItemId: 'oats-1',
  sourceInventoryAmountToRestore: 60,
  loggedAt: _day,
  createdAt: _day,
  updatedAt: _day,
);

void main() {
  late _MockItems items;
  late _MockPendings pendings;
  late _MockEatService eatService;
  late bool saverSucceeds;

  InventorySameFoodService service() => InventorySameFoodService(
    items: items,
    pendings: pendings,
    eatService: eatService,
    saver: (entry, {scannedSourceRef, persistEntry}) async {
      if (!saverSucceeds) {
        return false;
      }
      return await persistEntry!(entry);
    },
  );

  setUpAll(() {
    registerFallbackValue(_entry());
    registerFallbackValue(_oats('fallback'));
  });

  setUp(() {
    items = _MockItems();
    pendings = _MockPendings();
    eatService = _MockEatService();
    saverSucceeds = true;
    when(() => pendings.discard(any())).thenAnswer((_) async => true);
    when(() => eatService.commit(any(), any())).thenAnswer((_) async => true);
  });

  test('loads the packs with a barcode in eating order', () async {
    when(() => items.readAllForChange()).thenAnswer(
      (_) async => [
        _oats('full', barcode: '40000001'),
        _oats('opened', currentAmount: 100, barcode: '40000001'),
        _oats('other', barcode: '40000002'),
      ],
    );

    final packs = await service().loadPacksWithBarcode('40000001');

    expect(packs.map((item) => item.id), ['opened', 'full']);
  });

  test('a food without a barcode asks the Vorrat for nothing', () async {
    expect(await service().loadPacksWithBarcode(null), isEmpty);
    verifyNever(() => items.readAllForChange());
  });

  test('loads the packs to repeat an entry, its own pack included', () async {
    when(() => items.readAllForChange())
        .thenAnswer((_) async => [_oats('oats-1', currentAmount: 200)]);

    final packs = await service().loadPacksToRepeat(_entry());

    expect(packs.single.item.id, 'oats-1');
    expect(packs.single.amount, 60);
  });

  test('its own pack takes the eaten amount, not the capped stock', () async {
    when(() => items.readAllForChange())
        .thenAnswer((_) async => [_oats('oats-1')]);
    final capped = _entry().copyWith(sourceInventoryAmountToRestore: 20);

    final packs = await service().loadPacksToRepeat(capped);

    expect(packs.single.amount, 60);
  });

  test('a combined entry has no packs', () async {
    final combined = _entry().copyWith(
      bundleComponents: const [
        CalorieEntryBundleComponent(
          name: 'Oats',
          amountLabel: '60 g',
          totalKcal: 240,
          totalProtein: 6,
          totalCarbs: 36,
          totalFat: 7,
        ),
      ],
    );

    expect(await service().loadPacksToRepeat(combined), isEmpty);
    verifyNever(() => items.readAllForChange());
  });

  test('eats an entry again from a pack with its stock in one write', () async {
    final pack = _oats('oats-2');
    const pending = PendingInventoryConsumption(
      id: 'pending-1',
      itemId: 'oats-2',
      amount: 60,
    );
    when(() => pendings.stage(pack, 60)).thenReturn(pending);
    final repeated = _entry().copyWith(
      id: 'entry-2',
      sourceInventoryItemId: null,
      sourceInventoryAmountToRestore: null,
    );

    final result = await service().eatAgain(repeated, (item: pack, amount: 60));

    expect(result!.missedStock, isFalse);
    expect(result.entry.id, 'entry-2');
    expect(result.entry.sourceInventoryItemId, 'oats-2');
    expect(result.entry.sourceInventoryAmountToRestore, 60);
    verify(() => eatService.commit(result.entry, [pending])).called(1);
  });

  test('a pack with less stock than eaten is emptied and says so', () async {
    final pack = _oats('oats-2', currentAmount: 20);
    const pending = PendingInventoryConsumption(
      id: 'pending-1',
      itemId: 'oats-2',
      amount: 20,
    );
    when(() => pendings.stage(pack, 60)).thenReturn(pending);

    final result = await service().eatAgain(_entry(), (item: pack, amount: 60));

    expect(result!.missedStock, isTrue);
    expect(result.entry.sourceInventoryAmountToRestore, 20);
  });

  test('a failed save releases the reserved stock', () async {
    final pack = _oats('oats-2');
    const pending = PendingInventoryConsumption(
      id: 'pending-1',
      itemId: 'oats-2',
      amount: 60,
    );
    when(() => pendings.stage(pack, 60)).thenReturn(pending);
    saverSucceeds = false;

    final result = await service().eatAgain(_entry(), (item: pack, amount: 60));

    expect(result, isNull);
    verify(() => pendings.discard('pending-1')).called(1);
  });
}
