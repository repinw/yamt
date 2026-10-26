import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_hub_page.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_result.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_amount_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_components_list.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_food_estimate_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_item_actions_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/auth_user_data_key_session.dart';
import '../../../helpers/fake_inventory_item_repository.dart';

const _estimate = FoodEstimate(
  name: 'Rice bowl',
  portionGrams: 200,
  kcalLean: 150,
  kcalRich: 300,
  per100: GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
    per100Kcal: 100,
    per100Protein: 4,
    per100Carbs: 18,
    per100Fat: 2,
  ),
  ingredients: [
    FoodEstimateIngredient(name: 'Rice', grams: 150, kcal: 120),
    FoodEstimateIngredient(name: 'Oil', grams: 50, kcal: 80),
  ],
);

final InventoryItem _bowl = () {
  final item = InventoryItem.create(
    id: 'item-bowl',
    name: 'Rice bowl',
    entryDate: DateTime.utc(2026, 10, 2),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 400,
    currentAmount: 400,
    amountUnit: InventoryAmountUnit.gram,
    weight: '400 g',
    nutrition: _estimate.per100,
    aiEstimated: true,
  );
  return item.copyWith(
    productSnapshot: item.productSnapshot.copyWith(
      aiEstimate: const SavedFoodEstimate(
        estimate: _estimate,
        level: FoodEstimateLevel.normal,
        description: 'with chili oil',
        photoUrls: ['gs://yamt/users/u1/food_photos/p1.jpg'],
      ),
    ),
  );
}();

/// Opens the hub on a route; its result lands in [results].
Future<void> _openHub(
  WidgetTester tester,
  FakeInventoryItemRepository repository, {
  List<Object?>? results,
}) async {
  // Signed out: the hub's shopping list and serving reads stay empty.
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 12, 12)),
      userProfileProvider.overrideWith((ref) => Stream.value(null)),
      authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
      userDataKeySessionProvider.overrideWith(AuthUserDataKeySession.new),
      firebaseFirestoreProvider.overrideWith((ref) => null),
      inventoryItemRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  // The app keeps the Vorrat warm, so a chip's save outlives its tap.
  container.listen(inventoryItemsControllerProvider, (_, _) {});
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<Object?>(
                MaterialPageRoute(
                  builder: (_) => InventoryItemHubPage(
                    item: _bowl,
                    onAction: (_, _) => Future.value(false),
                  ),
                ),
              );
              results?.add(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

String _amount(WidgetTester tester) => tester
    .widget<TextField>(find.byKey(EatAmountRuler.fieldKey))
    .controller!
    .text;

void main() {
  testWidgets('a level chip saves the level and rescales the eaten food, '
      'keeping the amount (#763)', (tester) async {
    final repository = FakeInventoryItemRepository([_bowl]);
    await _openHub(tester, repository);
    await tester.enterText(find.byKey(EatAmountRuler.fieldKey), '100');
    await tester.pumpAndSettle();
    await _tapKey(tester, EatComponentsList.toggleKey);
    expect(find.text('60 kcal'), findsOneWidget);

    await _tapKey(
      tester,
      EatFoodEstimateHeader.levelKey(FoodEstimateLevel.rich),
    );

    final saved = repository.items.single;
    expect(saved.productSnapshot.aiEstimate!.level, FoodEstimateLevel.rich);
    expect(saved.nutrition, _estimate.per100At(FoodEstimateLevel.rich));
    expect(_amount(tester), '100');
    await _tapKey(tester, EatComponentsList.toggleKey);
    // Rice: 75 g of 150 g at 1.5 times the normal energy.
    expect(find.text('90 kcal'), findsOneWidget);
    expect(find.text('60 kcal'), findsOneWidget);
  });

  testWidgets('a level that fails to save stays as it was (#763)', (
    tester,
  ) async {
    final repository = FakeInventoryItemRepository([_bowl])..saves = false;
    await _openHub(tester, repository);

    await _tapKey(
      tester,
      EatFoodEstimateHeader.levelKey(FoodEstimateLevel.lean),
    );

    expect(
      repository.items.single.productSnapshot.aiEstimate!.level,
      FoodEstimateLevel.normal,
    );
    expect(
      find.text(
        lookupAppLocalizations(const Locale('en')).inventoryItemActionFailed,
      ),
      findsOneWidget,
    );
    final normal = tester.widget<TextButton>(
      find.descendant(
        of: find.byKey(
          EatFoodEstimateHeader.levelKey(FoodEstimateLevel.normal),
        ),
        matching: find.byType(TextButton),
      ),
    );
    expect(normal.onPressed, isNull);
  });

  testWidgets('eating waits until the picked level is saved (#763)', (
    tester,
  ) async {
    final saving = Completer<void>();
    final repository = FakeInventoryItemRepository([_bowl])..hold = saving;
    final results = <Object?>[];
    await _openHub(tester, repository, results: results);
    final confirm = find.byKey(
      const Key('inventory_item_amount_dialog_confirm_button'),
    );

    await _tapKey(
      tester,
      EatFoodEstimateHeader.levelKey(FoodEstimateLevel.rich),
    );
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(results, isEmpty);
    expect(find.byType(InventoryItemHubPage), findsOneWidget);

    saving.complete();
    await tester.pumpAndSettle();
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(results.single, isA<InventoryItemHubEat>());
  });

  testWidgets('the item card offers to estimate the AI food again (#763)', (
    tester,
  ) async {
    await _openHub(tester, FakeInventoryItemRepository([_bowl]));

    expect(find.byKey(EatItemActionsCard.reanalyzeKey), findsOneWidget);
  });
}
