import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/inventory/data/cooked_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';

import '../../../helpers/fake_inventory_item_repository.dart';
import '../../../helpers/fake_prepared_meal_template_repository.dart';

/// The household of one test on `fake_cloud_firestore`: the real cook run
/// and cooked meal repositories, a Vorrat the services read, and the
/// cookbook templates in memory.
class CookHarness {
  new _(this.firestore, this.cipher) {
    final scope = (householdId: 'h1', firestore: firestore, cipher: cipher);
    runs = CookRunRepository(scope: scope);
    meals = CookedMealRepository(
      scope: scope,
      actor: const InventoryActivityActor(userId: 'u1', displayName: 'Ada'),
      cookRuns: runs,
    );
  }

  /// Opens the household with a fresh key.
  static Future<CookHarness> open() async => CookHarness._(
    FakeFirebaseFirestore(),
    PayloadCipher(await PayloadCipher.newDataKey()),
  );

  /// The fake database.
  final FakeFirebaseFirestore firestore;

  /// The household key.
  final PayloadCipher cipher;

  /// The cook runs.
  late final CookRunRepository runs;

  /// The cooked meal batch.
  late final CookedMealRepository meals;

  /// The Vorrat as the services read it.
  final inventory = FakeInventoryItemRepository(const []);

  /// The cookbook.
  FakePreparedMealTemplateRepository templates =
      FakePreparedMealTemplateRepository();

  DocumentReference<Map<String, dynamic>> get _household =>
      firestore.collection('households').doc('h1');

  SealedCollection get _items => SealedCollection(
    _household.collection('inventory_items'),
    cipher: cipher,
    plaintextFields: inventoryItemPlaintextFields,
  );

  SealedCollection get _meals =>
      SealedCollection(_household.collection('prepared_meals'), cipher: cipher);

  /// Puts [items] into the Vorrat, in Firestore and for the reads.
  Future<void> stock(List<InventoryItem> items) async {
    inventory.items = [...inventory.items, ...items];
    for (final item in items) {
      await _items.reference
          .doc(item.id)
          .set(await _items.seal(item.id, item.toJson()));
    }
  }

  /// Writes the items of the Vorrat that only the in-memory repository holds,
  /// such as a food the cook found while assigning, to Firestore, where the
  /// meals read the stock.
  Future<void> syncStoredItems() async {
    for (final item in inventory.items) {
      await _items.reference
          .doc(item.id)
          .set(await _items.seal(item.id, item.toJson()));
    }
  }

  /// Stores [run] and waits until it is written.
  Future<void> start(CookRun run) async {
    await runs.create(run);
    await settle();
  }

  /// Removes the run [id] from Firestore, as another device ending it does.
  Future<void> removeRun(String id) =>
      _household.collection('cook_runs').doc(id).delete();

  /// Lets background batches land.
  Future<void> settle() async {
    await runs.pending;
    await pumpEventQueue();
  }

  /// The item [id] as Firestore holds it; `null` when it is gone.
  Future<InventoryItem?> storedItem(String id) async {
    final data = await _items.open(await _items.reference.doc(id).get());
    return data == null ? null : InventoryItem.fromJson(data);
  }

  /// The prepared meal [id]; `null` when it does not exist.
  Future<PreparedMeal?> storedMeal(String id) async {
    final data = await _meals.open(await _meals.reference.doc(id).get());
    return data == null ? null : PreparedMeal.fromJson(data);
  }

  /// How many prepared meals exist.
  Future<int> mealCount() async => (await _meals.reference.get()).docs.length;

  /// How many stock events exist.
  Future<int> eventCount() async =>
      (await _household.collection('inventory_activity_events').get())
          .docs
          .length;

  /// The run [id] as Firestore holds it; `null` when it is gone.
  Future<CookRun?> storedRun(String id) => runs.load(id);
}
