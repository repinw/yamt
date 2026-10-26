import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_item_reanalyze_flow.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_manual_product_search_request.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/auth_user_data_key_session.dart';
import '../../../helpers/fake_inventory_item_repository.dart';

FoodEstimate _estimate(String name, double per100Kcal) => FoodEstimate(
  name: name,
  portionGrams: 200,
  kcalLean: 150,
  kcalRich: 300,
  per100: GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
    per100Kcal: per100Kcal,
    per100Protein: 4,
    per100Carbs: 18,
    per100Fat: 2,
  ),
  ingredients: const [],
);

InventoryItem _aiFood(String name, double per100Kcal) {
  final estimate = _estimate(name, per100Kcal);
  final item = InventoryItem.create(
    id: 'item-bowl',
    name: name,
    entryDate: DateTime.utc(2026, 10, 2),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 400,
    currentAmount: 400,
    amountUnit: InventoryAmountUnit.gram,
    weight: '400 g',
    nutrition: estimate.per100,
    aiEstimated: true,
  );
  return item.copyWith(
    productSnapshot: item.productSnapshot.copyWith(
      aiEstimate: SavedFoodEstimate(
        estimate: estimate,
        level: FoodEstimateLevel.normal,
        description: '',
      ),
    ),
  );
}

final InventoryItem _bowl = _aiFood('Rice bowl', 100);
final InventoryItem _chiliBowl = _aiFood('Chili bowl', 140);

final AppLocalizations _l10n = lookupAppLocalizations(const Locale('en'));

/// Runs the flow for [_bowl]; the AI page route pops with [estimated], or
/// with nothing when null. The flow's return value lands in [results].
Future<void> _run(
  WidgetTester tester,
  FakeInventoryItemRepository repository, {
  required InventoryItem? estimated,
  required List<bool> results,
  List<Object?>? requests,
}) async {
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
  container.listen(inventoryItemsControllerProvider, (_, _) {});
  final router = GoRouter(
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (_, _) => Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () async => results.add(
                await InventoryItemReanalyzeFlow.run(
                  context: context,
                  ref: ref,
                  item: _bowl,
                  messenger: ScaffoldMessenger.of(context),
                ),
              ),
              child: const Text('reanalyze'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.homeProductSearchHub,
        builder: (context, state) {
          requests?.add(state.extra);
          return Scaffold(
            body: TextButton(
              onPressed: () => context.pop(
                estimated == null
                    ? null
                    : InventoryReceiptManualProductResult(
                        item: estimated,
                        action:
                            InventoryReceiptManualProductAction.addToInventory,
                      ),
              ),
              child: const Text('done'),
            ),
          );
        },
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.tap(find.text('reanalyze'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('done'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the new estimate replaces the food and keeps the stock, '
      'and undo brings the old food back (#763)', (tester) async {
    final repository = FakeInventoryItemRepository([_bowl]);
    final results = <bool>[];
    final requests = <Object?>[];

    await _run(
      tester,
      repository,
      estimated: _chiliBowl,
      results: results,
      requests: requests,
    );

    final request = requests.single! as InventoryManualProductSearchRequest;
    expect(request.item, _bowl);
    expect(request.startsWithAi, isTrue);
    expect(results, [true]);
    final saved = repository.items.single;
    expect(saved.name, 'Chili bowl');
    expect(saved.nutrition, _chiliBowl.nutrition);
    expect(
      saved.productSnapshot.aiEstimate,
      _chiliBowl.productSnapshot.aiEstimate,
    );
    expect(saved.currentAmount, 400);
    expect(find.text(_l10n.inventoryItemUpdatedMessage), findsOneWidget);

    await tester.tap(find.text(_l10n.commonUndoAction));
    await tester.pumpAndSettle();

    final restored = repository.items.single;
    expect(restored.name, 'Rice bowl');
    expect(restored.nutrition, _bowl.nutrition);
    expect(
      restored.productSnapshot.aiEstimate,
      _bowl.productSnapshot.aiEstimate,
    );
  });

  testWidgets('a failed save names the new estimate and keeps the food '
      '(#763)', (tester) async {
    final repository = FakeInventoryItemRepository([_bowl])..saves = false;
    final results = <bool>[];

    await _run(tester, repository, estimated: _chiliBowl, results: results);

    expect(results, [false]);
    expect(repository.items.single.name, 'Rice bowl');
    expect(find.text(_l10n.inventoryItemReanalyzeFailed), findsOneWidget);
  });

  testWidgets('going back from the AI page changes nothing (#763)', (
    tester,
  ) async {
    final repository = FakeInventoryItemRepository([_bowl]);
    final results = <bool>[];

    await _run(tester, repository, estimated: null, results: results);

    expect(results, [false]);
    expect(repository.items.single, _bowl);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a search pick without an estimate leaves the AI food (#763)', (
    tester,
  ) async {
    final repository = FakeInventoryItemRepository([_bowl]);
    final results = <bool>[];
    final picked = _chiliBowl.copyWith(
      productSnapshot: _chiliBowl.productSnapshot.copyWith(aiEstimate: null),
    );

    await _run(tester, repository, estimated: picked, results: results);

    expect(results, [false]);
    expect(repository.items.single, _bowl);
  });
}
