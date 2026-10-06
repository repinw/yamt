import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/calorie_entry_editor_page.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_pending_consumption_store.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_item_eat_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';

const _eatKey = Key('eat_with_editor');

final _loggedAt = DateTime(2026, 4, 6, 12, 30);

final InventoryItem _milk = InventoryItem.create(
  id: 'milk',
  name: 'Milch',
  entryDate: DateTime(2026, 4, 2),
  storeName: 'Aldi',
  quantity: 1,
  initialAmount: 1000,
  currentAmount: 1000,
  amountUnit: InventoryAmountUnit.gram,
  nutrition: const GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 64,
    per100Protein: 3.4,
    per100Carbs: 4.8,
    per100Fat: 3.5,
  ),
);

class _MockFirebaseAuth extends Mock implements FirebaseAuth;

class _MockUser extends Mock implements User;

/// Holds the Vorrat in memory and streams every change asynchronously.
class _MemoryInventoryItemRepository implements InventoryItemRepository {
  new(List<InventoryItem> items) : items = List.of(items);

  List<InventoryItem> items;
  final _changes = StreamController<List<InventoryItem>>.broadcast();

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;

  @override
  Future<List<InventoryItem>> readAll() async => List.of(items);

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    this.items = List.of(items);
    _changes.add(List.of(items));
    return true;
  }

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield List.of(items);
    yield* _changes.stream;
  }
}

/// Writes the entry to the diary and takes the stock, like the Firestore
/// batch does.
class _MemoryCommitStore implements InventoryCalorieEntryCommitStore {
  const new(this.inventory, this.diary);

  final _MemoryInventoryItemRepository inventory;
  final FakeCalorieLogRepository diary;

  @override
  Future<List<InventoryCalorieEntryCommitResult>?>
  commitEntryAndInventoryItems({
    required CalorieEntry entry,
    required List<PendingInventoryConsumption> pendingConsumptions,
  }) async {
    final pending = pendingConsumptions.single;
    final item = inventory.items.singleWhere((it) => it.id == pending.itemId);
    final reduced = item.reducedBy(pending.amount)!;
    await inventory.saveAll([reduced]);
    await diary.saveEntry(entry);
    return [
      InventoryCalorieEntryCommitResult(
        itemId: reduced.id,
        quantity: reduced.quantity,
        currentAmount: reduced.currentAmount,
      ),
    ];
  }
}

typedef _Harness = ({
  _MemoryInventoryItemRepository inventory,
  FakeCalorieLogRepository diary,
});

/// Eats 120 ml of [_milk], which counts in grams, so the eat flow needs the
/// calorie editor.
Future<_Harness> _pumpApp(WidgetTester tester) async {
  final user = _MockUser();
  when(() => user.uid).thenReturn('user-1');
  final auth = _MockFirebaseAuth();
  when(() => auth.currentUser).thenReturn(user);
  final inventory = _MemoryInventoryItemRepository([_milk]);
  final diary = FakeCalorieLogRepository();
  addTearDown(diary.dispose);
  final container = ProviderContainer(
    overrides: [
      firebaseAuthProvider.overrideWithValue(auth),
      authStateChangesProvider.overrideWithValue(AsyncData<User?>(user)),
      inventoryItemRepositoryProvider.overrideWithValue(inventory),
      calorieLogRepositoryProvider.overrideWithValue(diary),
      inventoryCalorieEntryCommitStoreProvider.overrideWithValue(
        _MemoryCommitStore(inventory, diary),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _EatPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(_eatKey));
  await tester.pumpAndSettle();
  expect(find.byType(CalorieEntryEditorPage), findsOneWidget);
  return (inventory: inventory, diary: diary);
}

class _EatPage extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: _eatKey,
          onPressed: () {
            final container = ProviderScope.containerOf(context, listen: false);
            final pending = container
                .read(inventoryPendingConsumptionStoreProvider)
                .stage(_milk, 120)!;
            unawaited(
              InventoryItemEatFlow.complete(
                context: context,
                container: container,
                item: _milk,
                request: InventoryItemEatRequest(
                  inventoryAmount: 120,
                  loggedAt: _loggedAt,
                  mealType: MealType.lunch,
                  calorieAmount: 120,
                  calorieUnit: ConsumedUnit.milliliters,
                ),
                pending: pending,
              ),
            );
          },
          child: const Text('Essen'),
        ),
      ),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('saving in the editor logs the entry and takes the stock', (
    tester,
  ) async {
    final app = await _pumpApp(tester);

    await tester.tap(find.byKey(CalorieEntryEditorKeys.saveButton));
    await tester.pumpAndSettle();

    final entry = app.diary.entries.single;
    expect(entry.name, 'Milch');
    expect(entry.consumedAmount, 120);
    expect(entry.consumedUnit, ConsumedUnit.milliliters);
    expect(entry.sourceInventoryItemId, 'milk');
    expect(app.inventory.items.single.currentAmount, 880);
    expect(find.byType(CalorieEntryEditorPage), findsNothing);
  });

  testWidgets('leaving the editor keeps the stock', (tester) async {
    final app = await _pumpApp(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(app.diary.entries, isEmpty);
    expect(app.inventory.items.single.currentAmount, 1000);
  });
}
