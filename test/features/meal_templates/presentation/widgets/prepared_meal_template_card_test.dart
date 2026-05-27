import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/data/'
    'cooking_flow_session_local_store.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'prepared_meal_template_card/prepared_meal_template_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/root_navigator_test_utils.dart';
import '../../../../support/prepared_meal_test_data.dart';

void main() {
  testWidgets('template card menu opens on root navigator by default', (
    tester,
  ) async {
    final rootObserver = RecordingNavigatorObserver();
    final nestedObserver = RecordingNavigatorObserver();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cookingFlowSessionSnapshotProvider.overrideWith((ref) => null),
        ],
        child: nestedNavigatorHarness(
          rootObserver: rootObserver,
          nestedObserver: nestedObserver,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: Scaffold(
            body: PreparedMealTemplateCard(
              template: preparedMealTestData().copyWith(
                recipeUrl: 'https://example.test',
              ),
              onOpenPressed: () {},
              onEditPressed: (_) async => true,
              onDeletePressed: (_) async => true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    rootObserver.clear();
    nestedObserver.clear();
    await tester.tap(find.byTooltip('Show menu'));
    await tester.pumpAndSettle();

    expectRootPopupRoutePushed(
      rootObserver: rootObserver,
      nestedObserver: nestedObserver,
    );
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('renders portions, name and no active session', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cookingFlowSessionSnapshotProvider.overrideWith((ref) => null),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 400,
                child: PreparedMealTemplateCard(
                  template: preparedMealTestData(
                    name: 'Tacos',
                    totalPortions: 4,
                  ),
                  onOpenPressed: () {},
                  onEditPressed: (_) async => true,
                  onDeletePressed: (_) async => true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tacos'), findsOneWidget);
    expect(find.text('4 Portions'), findsOneWidget);
    expect(find.text('0 ingredients'), findsOneWidget);
    expect(find.text('Resume'), findsNothing);
  });

  testWidgets('renders resume cookflow button and triggers callback', (
    tester,
  ) async {
    var opened = false;
    const activeSession = CookingFlowSession(
      templateId: 'meal-1',
      step: CookingFlowSessionStep.cooking,
      taraText: '',
      adjustmentInputText: '',
      adjustments: [],
      summaryIngredients: [],
      grossWeightText: '',
      splitIntoPortions: false,
      portionCount: 1,
      introDraft: CookingFlowIntroDraft(),
      introShoppingHandled: false,
      introShoppingBaselineInventoryItemIds: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cookingFlowSessionSnapshotProvider.overrideWith(
            (ref) => activeSession,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 400,
                child: PreparedMealTemplateCard(
                  template: preparedMealTestData(),
                  onOpenPressed: () => opened = true,
                  onEditPressed: (_) async => true,
                  onDeletePressed: (_) async => true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('2 Portions'), findsNothing);

    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    expect(opened, isTrue);
  });

  testWidgets('triggers edit and delete actions from menu', (tester) async {
    var editCalled = false;
    var deleteCalled = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cookingFlowSessionSnapshotProvider.overrideWith((ref) => null),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 400,
                child: PreparedMealTemplateCard(
                  template: preparedMealTestData().copyWith(
                    recipeUrl: 'https://example.test',
                  ),
                  onOpenPressed: () {},
                  onEditPressed: (t) async {
                    editCalled = true;
                    return true;
                  },
                  onDeletePressed: (id) async {
                    deleteCalled = true;
                    return true;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap menu button
    await tester.tap(find.byTooltip('Show menu'));
    await tester.pumpAndSettle();

    // Tap Edit
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(editCalled, isTrue);

    // Tap menu button again
    await tester.tap(find.byTooltip('Show menu'));
    await tester.pumpAndSettle();

    // Tap Delete
    await tester.tap(find.text('Delete template'));
    await tester.pumpAndSettle();
    expect(deleteCalled, isTrue);
  });
}
