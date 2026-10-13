import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'prepared_meal_edit_draft.dart';
import 'package:yamt/features/inventory/presentation/prepared_meal_edit_page.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'prepared_meal_edit_open_rows.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/inventory_item_whole_list_writes.dart';

final _now = DateTime.utc(2026, 10, 10, 19);

void main() {
  testWidgets('removing a food keeps its row as an open row', (tester) async {
    final results = await _openEditor(
      tester,
      _meal(open: const ['Salz'], ignored: const ['Pfeffer']),
    );
    expect(find.byKey(PreparedMealEditOpenRows.openKey('Salz')), findsOne);
    expect(
      find.byKey(PreparedMealEditOpenRows.ignoredKey('Pfeffer')),
      findsOne,
    );

    await _tap(tester, find.byKey(PreparedMealEditPage.removeKey('rice')));

    expect(find.byKey(const ValueKey<String>('rice')), findsNothing);
    expect(
      find.byKey(PreparedMealEditOpenRows.openKey('150 g Reis')),
      findsOne,
    );

    await _tap(tester, find.byKey(PreparedMealEditPage.saveKey));

    final result = results.single!;
    expect(result.items, isEmpty);
    expect(result.deletedRows, isEmpty);
  });

  testWidgets('the x of an open or ignored row deletes it', (tester) async {
    final results = await _openEditor(
      tester,
      _meal(open: const ['Salz'], ignored: const ['Pfeffer']),
    );

    await _tap(tester, find.byKey(PreparedMealEditOpenRows.deleteKey('Salz')));
    await _tap(
      tester,
      find.byKey(PreparedMealEditOpenRows.deleteKey('Pfeffer')),
    );

    expect(find.byKey(PreparedMealEditOpenRows.openKey('Salz')), findsNothing);
    expect(
      find.byKey(PreparedMealEditOpenRows.ignoredKey('Pfeffer')),
      findsNothing,
    );
    await _tap(tester, find.byKey(PreparedMealEditPage.saveKey));

    final result = results.single!;
    expect(result.items.single.itemId, 'rice');
    expect(result.deletedRows, ['Salz', 'Pfeffer']);
  });

  testWidgets('a meal needs a food or an open row to be saved', (tester) async {
    await _openEditor(tester, _meal());

    await _tap(tester, find.byKey(PreparedMealEditPage.removeKey('rice')));
    expect(_saveButton(tester).onPressed, isNotNull);

    await _tap(
      tester,
      find.byKey(PreparedMealEditOpenRows.deleteKey('150 g Reis')),
    );
    expect(_saveButton(tester).onPressed, isNull);
  });

  testWidgets('once a portion is gone, foods and rows stay', (tester) async {
    await _openEditor(
      tester,
      _meal(open: const ['Salz']).copyWith(remainingPortions: 0.5),
    );

    expect(find.byKey(PreparedMealEditOpenRows.openKey('Salz')), findsOne);
    expect(
      find.byKey(PreparedMealEditOpenRows.deleteKey('Salz')),
      findsNothing,
    );
    expect(find.byKey(PreparedMealEditPage.removeKey('rice')), findsNothing);
  });
}

FilledButton _saveButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(PreparedMealEditPage.saveKey));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Opens the editor of [meal]; the list gets what it saves.
Future<List<PreparedMealEditResult?>> _openEditor(
  WidgetTester tester,
  PreparedMeal meal,
) async {
  final results = <PreparedMealEditResult?>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Signed out: the Vorrat controller reads only the fake.
        authStateChangesProvider.overrideWithValue(
          const AsyncData<User?>(null),
        ),
        userProfileProvider.overrideWithValue(const AsyncData(null)),
        firebaseFirestoreProvider.overrideWith((ref) => null),
        inventoryItemRepositoryProvider.overrideWithValue(_Items()),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => results.add(
                await showPreparedMealEditPage(context, meal: meal),
              ),
              child: const Text('edit'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('edit'));
  await tester.pumpAndSettle();
  return results;
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

PreparedMeal _meal({
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
    components: [
      PreparedMealComponent(
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
      ),
    ],
    pendingRecipeIngredients: open,
    ignoredPendingRecipeIngredients: ignored,
  );
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
