import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';
import 'package:yamt/features/diary/presentation/diary_entry_delete_flow.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_calorie_entry_commit_store.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/inventory_item_whole_list_writes.dart';
import '../../calories/support/fake_calories_repositories.dart';

class _MockUser extends Mock implements User;

const _hostPath = '/details';
const _removeKey = Key('remove');
const _belowText = 'Below';

CalorieEntry _stockEntry({String itemId = 'inventory-1'}) {
  return CalorieEntry.create(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Skyr',
    mealType: MealType.breakfast,
    consumedAmount: 200,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 5,
    per100Fat: 1,
    sourceInventoryItemId: itemId,
    sourceInventoryAmountToRestore: 2,
    loggedAt: DateTime(2026, 2, 25, 8),
    createdAt: DateTime(2026, 2, 25, 8),
    updatedAt: DateTime(2026, 2, 25, 8),
  );
}

CalorieEntry _preparedMeal() {
  final loggedAt = DateTime(2026, 2, 25, 12);
  return CalorieEntry.bundle(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Chili',
    mealType: MealType.lunch,
    totalKcal: 420,
    totalProtein: 28,
    totalCarbs: 35,
    totalFat: 18,
    bundleSourcePreparedMealId: 'prepared-1',
    bundleConsumedPortions: 2,
    bundleTotalPortions: 4,
    bundleComponents: const [
      CalorieEntryBundleComponent(
        name: 'Beans',
        amountLabel: '150 g',
        totalKcal: 420,
        totalProtein: 28,
        totalCarbs: 35,
        totalFat: 18,
      ),
    ],
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

/// Gives stock back as [restored] says: the new stock per item, an empty
/// list when the items are gone, or null when the write fails.
class _ItemStore implements InventoryCalorieEntryCommitStore {
  new({this.restored = const []});

  final List<InventoryCalorieEntryCommitResult>? restored;
  final restoredAmounts = <Map<String, int>>[];

  @override
  Future<List<InventoryCalorieEntryCommitResult>?> saveEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  }) async => null;

  @override
  Future<List<InventoryCalorieEntryCommitResult>?> deleteEntryAndRestoreItems({
    required CalorieEntry entry,
    required Map<String, int> amountsByItemId,
  }) async {
    restoredAmounts.add(amountsByItemId);
    return restored;
  }

  @override
  Future<List<InventoryCalorieEntryCommitResult>?>
  commitEntryAndInventoryItems({
    required CalorieEntry entry,
    required List<PendingInventoryConsumption> pendingConsumptions,
  }) => throw UnimplementedError();
}

class _MealStore implements PreparedMealCalorieEntryCommitStore {
  const new(this.result);

  final CalorieEntryDeleteResult result;

  @override
  Future<CalorieEntryDeleteResult> deleteEntryAndRestorePreparedMeal({
    required CalorieEntry entry,
  }) async => result;

  @override
  Future<bool> commitEntryAndPreparedMeal({required CalorieEntry entry}) =>
      throw UnimplementedError();
}

class _Items with InventoryItemWholeListWrites {
  const new(this.ids);

  final List<String> ids;

  @override
  Future<List<InventoryItem>> readAll() async => [
    for (final id in ids)
      InventoryItem.create(
        id: id,
        name: 'Skyr',
        entryDate: DateTime(2026, 2, 20),
        storeName: 'Aldi',
        quantity: 4,
      ),
  ];

  @override
  Stream<List<InventoryItem>> watchAll() => Stream.fromFuture(readAll());

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;
}

class _Meals implements PreparedMealRepository {
  const new();

  @override
  Future<List<PreparedMeal>> readAll() async => [
    PreparedMeal(
      id: 'prepared-1',
      name: 'Chili',
      totalPortions: 4,
      remainingPortions: 2,
      totalKcal: 840,
      totalProtein: 56,
      totalCarbs: 70,
      totalFat: 36,
      createdAt: DateTime(2026, 2, 24),
      updatedAt: DateTime(2026, 2, 24),
      components: const <PreparedMealComponent>[],
    ),
  ];

  @override
  Stream<List<PreparedMeal>> watchAll() => Stream.fromFuture(readAll());

  @override
  Future<bool> save(PreparedMeal meal) async => true;

  @override
  Future<bool> delete(String mealId) async => true;

  @override
  Future<List<PreparedMeal>> readAllForChange() => readAll();
}

/// Fakes the Vorrat behind the delete: the items that exist and the
/// stores that write the delete with its stock.
List<Override> _vorrat({
  List<String> itemIds = const ['inventory-1'],
  _ItemStore? itemStore,
  CalorieEntryDeleteResult mealResult = const CalorieEntryDeleteResult.success(
    restoredToInventory: true,
  ),
}) {
  return [
    inventoryItemRepositoryProvider.overrideWithValue(_Items(itemIds)),
    preparedMealRepositoryProvider.overrideWithValue(const _Meals()),
    inventoryCalorieEntryCommitStoreProvider.overrideWithValue(
      itemStore ?? _ItemStore(),
    ),
    preparedMealCalorieEntryCommitStoreProvider.overrideWithValue(
      _MealStore(mealResult),
    ),
  ];
}

/// Page below the details stand-in, which it opens on its first frame.
class _Below extends StatefulWidget {
  const new();

  @override
  State<_Below> createState() => _BelowState();
}

class _BelowState extends State<_Below> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(context.push<void>(_hostPath));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text(_belowText));
  }
}

/// Details page stand-in that removes [entry] through the flow.
class _DetailsHost extends StatelessWidget {
  const new({required this.entry});

  final CalorieEntry entry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          key: _removeKey,
          onPressed: () =>
              unawaited(DiaryEntryDeleteFlow.remove(context, entry: entry)),
          child: const Text('Remove'),
        ),
      ),
    );
  }
}

Future<FakeCalorieLogRepository> _open(
  WidgetTester tester,
  CalorieEntry entry, {
  List<Override> overrides = const <Override>[],
}) async {
  final logRepository = FakeCalorieLogRepository(initialEntries: [entry]);
  final settingsRepository = FakeCalorieSettingsRepository();
  addTearDown(logRepository.dispose);
  addTearDown(settingsRepository.dispose);
  final user = _MockUser();
  when(() => user.uid).thenReturn('user-1');
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _Below()),
      GoRoute(
        path: _hostPath,
        builder: (context, state) => _DetailsHost(entry: entry),
      ),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWith((ref) => Stream<User?>.value(user)),
      firebaseFirestoreProvider.overrideWith((ref) => null),
      userProfileProvider.overrideWith((ref) => Stream.value(null)),
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return logRepository;
}

Future<void> _remove(WidgetTester tester) async {
  await tester.tap(find.byKey(_removeKey));
  await tester.pumpAndSettle();
}

bool _isHostOpen() => find.byType(_DetailsHost).evaluate().isNotEmpty;

void main() {
  testWidgets('deletes only the diary entry when chosen in the dialog', (
    tester,
  ) async {
    final itemStore = _ItemStore();
    final repository = await _open(
      tester,
      _stockEntry(),
      overrides: _vorrat(itemStore: itemStore),
    );

    await _remove(tester);

    expect(
      find.text('Would you like to return this food to the inventory?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete from diary only'));
    await tester.pumpAndSettle();

    expect(repository.entries, isEmpty);
    expect(itemStore.restoredAmounts, isEmpty);
    expect(_isHostOpen(), isFalse);
    expect(find.text('Entry removed'), findsOneWidget);
  });

  testWidgets('keeps the entry when the stock cannot return', (tester) async {
    final repository = await _open(
      tester,
      _stockEntry(),
      overrides: _vorrat(itemStore: _ItemStore(restored: null)),
    );

    await _remove(tester);
    await tester.tap(find.text('Return to inventory'));
    await tester.pumpAndSettle();

    expect(
      find.text('The food could not be added back to inventory.'),
      findsOneWidget,
    );
    expect(repository.entries, hasLength(1));
    expect(_isHostOpen(), isTrue);
  });

  testWidgets('offers the diary-only delete when the stock item is gone', (
    tester,
  ) async {
    final repository = await _open(
      tester,
      _stockEntry(itemId: 'missing-item'),
      overrides: _vorrat(itemIds: const []),
    );

    await _remove(tester);

    expect(find.text('Food no longer in inventory'), findsOneWidget);
    expect(
      find.text(
        '"Skyr" is no longer in inventory, so it cannot be returned. '
        'Delete it from the diary only?',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete from diary'));
    await tester.pumpAndSettle();

    expect(repository.entries, isEmpty);
    expect(_isHostOpen(), isFalse);
  });

  testWidgets('asks again when the stock item disappears while returning', (
    tester,
  ) async {
    // The item exists when the page asks, but is gone when the delete
    // writes.
    final repository = await _open(
      tester,
      _stockEntry(),
      overrides: _vorrat(itemStore: _ItemStore()),
    );

    await _remove(tester);
    await tester.tap(find.text('Return to inventory'));
    await tester.pumpAndSettle();

    expect(find.text('Food no longer in inventory'), findsOneWidget);

    await tester.tap(find.text('Delete from diary'));
    await tester.pumpAndSettle();

    expect(repository.entries, isEmpty);
    expect(_isHostOpen(), isFalse);
  });

  testWidgets('keeps a prepared meal entry when its portions cannot return', (
    tester,
  ) async {
    final repository = await _open(
      tester,
      _preparedMeal(),
      overrides: _vorrat(
        mealResult: const CalorieEntryDeleteResult.failure(
          CalorieEntryDeleteFailureReason.restoreFailed,
        ),
      ),
    );

    await _remove(tester);
    await tester.tap(find.text('Return to inventory'));
    await tester.pumpAndSettle();

    expect(
      find.text('The meal could not be returned to inventory.'),
      findsOneWidget,
    );
    expect(repository.entries, hasLength(1));
    expect(_isHostOpen(), isTrue);
    expect(find.text(_belowText), findsNothing);
  });
}
