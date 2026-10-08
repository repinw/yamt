import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/cookbook_new/presentation/cooked_meal_page.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooked_meal_header.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('a combined meal cooked elsewhere can be closed again', (
    tester,
  ) async {
    final meals = StreamController<List<PreparedMeal>>();
    addTearDown(meals.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryQuickEatMealsProvider.overrideWith((ref) => meals.stream),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CookedMealPage(mealId: 'combo'),
        ),
      ),
    );
    meals.add([_combined(inPot: true)]);
    await tester.pumpAndSettle();
    final route = ModalRoute.of(tester.element(find.byType(CookedMealPage)))!;
    // In the pot, closing asks to discard instead of popping at once.
    expect(route.popDisposition, RoutePopDisposition.doNotPop);

    meals.add([_combined(inPot: false)]);
    await tester.pumpAndSettle();

    expect(route.popDisposition, isNot(RoutePopDisposition.doNotPop));
    expect(_closeButton(tester).onPressed, isNotNull);
  });

  testWidgets('a meal that never arrives says so after the wait', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryQuickEatMealsProvider.overrideWith(
            (ref) => Stream.value(const <PreparedMeal>[]),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CookedMealPage(mealId: 'missing'),
        ),
      ),
    );
    await tester.pump();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CookedMealPage)),
    )!;
    expect(find.text(l10n.cookedLoadFailed), findsNothing);
    // A meal on its way may be combined, so the page cannot close yet.
    expect(_closeButton(tester).onPressed, isNull);

    await tester.pump(const Duration(seconds: 5));

    expect(find.text(l10n.cookedLoadFailed), findsOneWidget);
    expect(find.byType(CookedMealPage), findsOneWidget);
    expect(_closeButton(tester).onPressed, isNotNull);
  });
}

PreparedMeal _combined({required bool inPot}) {
  final now = DateTime.utc(2026, 10, 8);
  return PreparedMeal(
    id: 'combo',
    name: 'Oats',
    totalPortions: 1,
    remainingPortions: 1,
    totalKcal: 300,
    totalProtein: 10,
    totalCarbs: 50,
    totalFat: 5,
    createdAt: now,
    updatedAt: now,
    components: const <PreparedMealComponent>[],
    inPot: inPot ? true : null,
  );
}

IconButton _closeButton(WidgetTester tester) =>
    tester.widget<IconButton>(find.byKey(CookedMealHeader.closeKey));
