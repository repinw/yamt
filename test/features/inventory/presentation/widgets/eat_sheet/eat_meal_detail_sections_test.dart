import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'prepared_meal_actions.dart';
import 'package:yamt/features/inventory/presentation/prepared_meal_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_meal_ingredients_box.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_pending_fill_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/inventory_item_whole_list_writes.dart';

final _now = DateTime.utc(2026, 10, 10, 19);

void main() {
  testWidgets('the x takes a food out and its row is open again', (
    tester,
  ) async {
    final meals = _Meals(_meal());
    final unassigned = <PreparedMealComponent>[];
    await _openDetail(
      tester,
      meals,
      _actions(
        unassign: (mealId, component) async {
          unassigned.add(component);
          meals.emit(_meal(components: const [], open: const ['150 g Reis']));
          return true;
        },
      ),
    );

    await _tap(tester, find.byKey(EatMealIngredientsBox.unassignKey('rice')));

    expect(unassigned.single, _rice());
    expect(find.byKey(EatMealIngredientsBox.unassignKey('rice')), findsNothing);
    expect(
      find.byKey(EatMealIngredientsBox.openRowKey('150 g Reis')),
      findsOneWidget,
    );
    expect(
      find.byKey(EatMealIngredientsBox.fillKey('150 g Reis')),
      findsOneWidget,
    );
  });

  testWidgets('the foods stay once a portion is gone', (tester) async {
    await _openDetail(
      tester,
      _Meals(_meal().copyWith(totalPortions: 2, remainingPortions: 1)),
      _actions(),
    );

    expect(
      find.byKey(const ValueKey('eat_meal_ingredient_rice')),
      findsOneWidget,
    );
    expect(find.byKey(EatMealIngredientsBox.unassignKey('rice')), findsNothing);
  });

  testWidgets('an ignored row stays, struck through, and opens again', (
    tester,
  ) async {
    final meals = _Meals(_meal(open: const ['Salz']));
    final unignored = <String>[];
    await _openDetail(
      tester,
      meals,
      _actions(
        ignore: (mealId, row) async {
          meals.emit(_meal(ignored: [row]));
          return true;
        },
        unignore: (mealId, row) async {
          unignored.add(row);
          return true;
        },
      ),
    );

    await _tap(tester, find.byKey(const ValueKey('eat_meal_ignore_Salz')));

    final row = find.byKey(EatMealIngredientsBox.ignoredRowKey('Salz'));
    expect(row, findsOneWidget);
    expect(find.byKey(EatMealIngredientsBox.openRowKey('Salz')), findsNothing);
    final name = tester.widget<Text>(
      find.descendant(of: row, matching: find.text('Salz')),
    );
    expect(name.style?.decoration, TextDecoration.lineThrough);

    await _tap(tester, find.byKey(EatMealIngredientsBox.unignoreKey('Salz')));
    expect(unignored, ['Salz']);
  });

  testWidgets('an ignored row can still be filled', (tester) async {
    await _openDetail(
      tester,
      _Meals(_meal(ignored: const ['Salz'])),
      _actions(),
    );

    await _tap(tester, find.byKey(EatMealIngredientsBox.fillKey('Salz')));

    expect(find.byType(PreparedMealPendingFillSheet), findsOneWidget);
    expect(find.byKey(PreparedMealPendingFillSheet.stockKey), findsOneWidget);
    // It is ignored already.
    expect(find.byKey(PreparedMealPendingFillSheet.ignoreKey), findsNothing);
  });
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Opens the detail page of the meal that [meals] holds.
Future<void> _openDetail(
  WidgetTester tester,
  _Meals meals,
  PreparedMealActions actions,
) async {
  addTearDown(meals.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => _now),
        // Signed out: the Vorrat controllers read only the fakes.
        authStateChangesProvider.overrideWithValue(
          const AsyncData<User?>(null),
        ),
        userProfileProvider.overrideWithValue(const AsyncData(null)),
        firebaseFirestoreProvider.overrideWith((ref) => null),
        preparedMealRepositoryProvider.overrideWithValue(meals),
        inventoryItemRepositoryProvider.overrideWithValue(_Items()),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => PreparedMealEatFlow.eat(
                context: context,
                meal: meals.meal,
                actions: actions,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

PreparedMealActions _actions({
  PreparedMealUnassignCallback? unassign,
  PreparedMealIngredientIgnoreCallback? ignore,
  PreparedMealIngredientIgnoreCallback? unignore,
}) {
  return PreparedMealActions(
    throwAway: (_, _, _) async => true,
    fillPendingIngredient: (_, _, _) async => true,
    fillPendingIngredientWithItem: (_, _, _, _) async => true,
    ignorePendingIngredient: ignore ?? (_, _) async => true,
    unignorePendingIngredient: unignore ?? (_, _) async => true,
    unassign: unassign ?? (_, _) async => true,
    unbundle: (_) async => true,
    changeWeight: (_, _) async => true,
    edit: (_, _, _) async => true,
    saveTemplate: (_, _) async => true,
  );
}

InventoryItem _riceItem() => InventoryItem.create(
  id: 'rice',
  name: 'Reis',
  entryDate: _now,
  storeName: 'Store',
  quantity: 1,
  initialAmount: 1000,
  currentAmount: 850,
  amountUnit: InventoryAmountUnit.gram,
);

PreparedMealComponent _rice() => PreparedMealComponent(
  inventoryItemId: 'rice',
  name: 'Reis',
  brand: null,
  imageUrl: null,
  usedAmount: 150,
  usedUnit: InventoryAmountUnit.gram,
  totalKcal: 195,
  totalProtein: 4,
  totalCarbs: 42,
  totalFat: 1,
  sourceItemSnapshot: _riceItem(),
  pendingRecipeIngredient: '150 g Reis',
);

PreparedMeal _meal({
  List<PreparedMealComponent>? components,
  List<String> open = const [],
  List<String> ignored = const [],
}) {
  return PreparedMeal(
    id: 'pan',
    name: 'Reispfanne',
    totalPortions: 1,
    remainingPortions: 1,
    totalKcal: 195,
    totalProtein: 4,
    totalCarbs: 42,
    totalFat: 1,
    createdAt: _now,
    updatedAt: _now,
    components: components ?? [_rice()],
    pendingRecipeIngredients: open,
    ignoredPendingRecipeIngredients: ignored,
  );
}

/// The stored meal, which [emit] changes as a save would.
class _Meals implements PreparedMealRepository {
  new(this.meal);

  final _changes = StreamController<List<PreparedMeal>>.broadcast();
  PreparedMeal meal;

  void emit(PreparedMeal next) {
    meal = next;
    _changes.add([next]);
  }

  Future<void> dispose() => _changes.close();

  @override
  Stream<List<PreparedMeal>> watchAll() {
    return Stream<List<PreparedMeal>>.multi((controller) {
      controller.add([meal]);
      final subscription = _changes.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<List<PreparedMeal>> readAll() async => [meal];

  @override
  Future<List<PreparedMeal>> readAllForChange() => readAll();

  @override
  Future<bool> save(PreparedMeal meal) async => true;

  @override
  Future<bool> delete(String mealId) async => true;
}

class _Items with InventoryItemWholeListWrites {
  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield [_riceItem()];
  }

  @override
  Future<List<InventoryItem>> readAll() async => [_riceItem()];

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;
}
