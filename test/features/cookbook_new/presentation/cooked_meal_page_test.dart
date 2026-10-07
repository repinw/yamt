import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/cookbook_new/presentation/cooked_meal_page.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
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

    await tester.pump(const Duration(seconds: 5));

    expect(find.text(l10n.cookedLoadFailed), findsOneWidget);
    expect(find.byType(CookedMealPage), findsOneWidget);
  });
}
