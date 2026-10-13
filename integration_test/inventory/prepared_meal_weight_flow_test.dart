import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/prepared_meal_detail_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_meal_actions_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_weight_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/inventory_item_whole_list_writes.dart';

const _openKey = ValueKey<String>('open-meal');
const _tableKey = Key('prepared_meal_nutrition_table');
final _now = DateTime(2026, 10, 13, 7, 30);

/// Chili cooked yesterday: 4 portions, 2000 g in a 1180 g pot, 3 left.
final _chili = PreparedMeal(
  id: 'chili',
  name: 'Chili sin Carne',
  totalPortions: 4,
  remainingPortions: 3,
  totalKcal: 1840,
  totalProtein: 96,
  totalCarbs: 212,
  totalFat: 52,
  createdAt: DateTime(2026, 10, 12, 19),
  updatedAt: DateTime(2026, 10, 12, 20),
  components: const <PreparedMealComponent>[],
  finalNetWeight: 2000,
  potTareWeight: 1180,
);

/// The household's meals: every write reaches the stream later, like the
/// Firestore snapshots.
class _MealRepository implements PreparedMealRepository {
  final _changes = StreamController<List<PreparedMeal>>.broadcast();
  List<PreparedMeal> meals = [_chili];

  @override
  Stream<List<PreparedMeal>> watchAll() async* {
    yield meals;
    yield* _changes.stream;
  }

  @override
  Future<List<PreparedMeal>> readAll() async => meals;

  @override
  Future<List<PreparedMeal>> readAllForChange() => readAll();

  @override
  Future<bool> save(PreparedMeal meal) async {
    meals = [
      for (final stored in meals)
        if (stored.id == meal.id) meal else stored,
    ];
    scheduleMicrotask(() => _changes.add(meals));
    return true;
  }

  @override
  Future<bool> delete(String mealId) async {
    meals = [
      for (final stored in meals)
        if (stored.id != mealId) stored,
    ];
    scheduleMicrotask(() => _changes.add(meals));
    return true;
  }

  Future<void> close() => _changes.close();
}

class _InventoryRepository with InventoryItemWholeListWrites {
  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield const <InventoryItem>[];
  }

  @override
  Future<List<InventoryItem>> readAll() async => const <InventoryItem>[];

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;
}

class _ActivityRepository implements InventoryActivityEventRepository {
  @override
  Stream<List<InventoryActivityEvent>> watchRecent({int limit = 100}) =>
      const Stream.empty();

  @override
  Future<bool> appendAll(List<InventoryActivityEvent> events) async => true;
}

class _DiscardEventRepository implements InventoryDiscardEventRepository {
  @override
  Future<List<InventoryDiscardEvent>> readAll() async =>
      const <InventoryDiscardEvent>[];

  @override
  Future<bool> saveEvent(InventoryDiscardEvent event) async => true;

  @override
  Future<bool> deleteEvent(String eventId) async => true;
}

Widget _app(_MealRepository meals) {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => _now),
      authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
      preparedMealRepositoryProvider.overrideWithValue(meals),
      inventoryItemRepositoryProvider.overrideWithValue(_InventoryRepository()),
      inventoryActivityEventRepositoryProvider.overrideWithValue(
        _ActivityRepository(),
      ),
      inventoryActivityActorProvider.overrideWithValue(null),
      inventoryDiscardEventRepositoryProvider.overrideWithValue(
        _DiscardEventRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  // The app keeps the Vorrat meals warm for its whole life, as app.dart does.
  container.listen(preparedMealsControllerProvider, (_, _) {});
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          // Stands in for the Vorrat row, which opens the same page.
          child: Consumer(
            builder: (context, ref, _) => TextButton(
              key: _openKey,
              onPressed: () => PreparedMealDetailFlow.open(
                context: context,
                ref: ref,
                meal: _chili,
              ),
              child: const Text('Chili'),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The nutrition table's text [text].
Finder _inTable(String text) =>
    find.descendant(of: find.byKey(_tableKey), matching: find.text(text));

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  final end = tester.binding.clock.fromNowBy(const Duration(seconds: 8));
  while (finder.evaluate().isEmpty) {
    if (tester.binding.clock.now().isAfter(end)) {
      throw TestFailure('Timed out waiting for $finder.');
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the cold pot weighed the next morning changes the grams of '
      'a portion and per 100 g', (tester) async {
    final meals = _MealRepository();
    addTearDown(meals.close);
    await tester.pumpWidget(_app(meals));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_openKey));
    await tester.pumpAndSettle();
    // 1500 g left for 3 portions with 1380 kcal.
    expect(_inTable('1 Portion · 500 g'), findsOneWidget);
    expect(_inTable('92 kcal'), findsOneWidget);

    final weight = find.byKey(EatMealActionsCard.weightKey);
    await tester.ensureVisible(weight);
    await tester.pumpAndSettle();
    await tester.tap(weight);
    await tester.pumpAndSettle();

    // The pot weighs 2380 g on the scale, written the German way.
    await tester.enterText(
      find.byKey(PreparedMealWeightDialog.fieldKey),
      '2.380',
    );
    await tester.pump();
    expect(find.byKey(PreparedMealWeightDialog.netKey), findsOneWidget);
    await tester.tap(find.byKey(PreparedMealWeightDialog.saveKey));
    await tester.pumpAndSettle();
    await _pumpUntilFound(tester, _inTable('1 Portion · 400 g'));

    // 1200 g are left; the whole meal weighs 1600 g now.
    final stored = meals.meals.single;
    expect(stored.remainingNetWeight, 1200);
    expect(stored.finalNetWeight, 1600);
    expect(stored.remainingPortions, 3);
    expect(stored.totalKcal, 1840);
    expect(_inTable('115 kcal'), findsOneWidget);
    expect(find.byType(PreparedMealWeightDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
