import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_plan_need.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_plan_needs_flow.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_plan_needs_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../support/fake_shopping_list_repository.dart';

void main() {
  final needs = [
    ShoppingPlanNeed(
      name: 'Milch',
      day: DateTime(2026, 10, 19),
      mealType: MealType.breakfast,
      amount: null,
      inMilliliters: false,
      isPartial: false,
    ),
  ];

  Future<Future<bool> Function()> offer(
    WidgetTester tester, {
    bool offerNeverAsk = false,
    FakeShoppingListRepository? repository,
  }) async {
    Future<bool>? answer;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (repository != null)
            shoppingListRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => answer = ShoppingPlanNeedsFlow.offer(
                  context,
                  needs,
                  isCancelled: () => false,
                  offerNeverAsk: offerNeverAsk,
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
    return () => answer!;
  }

  testWidgets('"Don\'t ask again" closes the question and reports it', (
    tester,
  ) async {
    final answer = await offer(tester, offerNeverAsk: true);

    await tester.tap(find.byKey(ShoppingPlanNeedsDialog.neverAskKey));
    await tester.pumpAndSettle();

    expect(await answer(), isTrue);
    expect(find.byType(ShoppingPlanNeedsDialog), findsNothing);
  });

  testWidgets('the question offers no "Don\'t ask again" by default', (
    tester,
  ) async {
    final answer = await offer(tester);

    expect(find.byType(ShoppingPlanNeedsDialog), findsOneWidget);
    expect(find.byKey(ShoppingPlanNeedsDialog.neverAskKey), findsNothing);
    await tester.tap(find.byKey(ShoppingPlanNeedsDialog.skipKey));
    await tester.pumpAndSettle();
    expect(await answer(), isFalse);
  });

  testWidgets('an added need carries the planned meal it is for', (
    tester,
  ) async {
    final repository = FakeShoppingListRepository();
    addTearDown(repository.dispose);
    final answer = await offer(tester, repository: repository);

    await tester.tap(find.byKey(ShoppingPlanNeedsDialog.addKey));
    await tester.pumpAndSettle();

    expect(await answer(), isFalse);
    final milk = repository.savedItems.single;
    expect(
      (milk.name, milk.note, milk.plannedFor),
      (
        'Milch',
        null,
        (day: DateTime(2026, 10, 19), mealType: MealType.breakfast),
      ),
    );
  });
}
