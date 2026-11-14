import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_planned_meal.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_list_entry_tile.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_planned_meal_text.dart';
import 'package:yamt/l10n/app_localizations.dart';

// Wednesday, 18 November 2026.
final _wednesday = DateTime(2026, 11, 18, 9);

Future<void> _pump(
  WidgetTester tester,
  String language,
  Widget Function(BuildContext) build,
) => tester.pumpWidget(
  ProviderScope(
    overrides: [clockProvider.overrideWithValue(() => _wednesday)],
    child: MaterialApp(
      locale: Locale(language),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Builder(builder: build)),
    ),
  ),
);

Future<String> _text(
  WidgetTester tester,
  String language,
  ShoppingPlannedMeal plan,
) async {
  late String text;
  await _pump(tester, language, (context) {
    text = shoppingPlannedForText(context, plan, now: _wednesday);
    return const SizedBox();
  });
  return text;
}

void main() {
  testWidgets('a day of the coming week shows as its weekday, in the '
      'language of the reader', (tester) async {
    final thursday = (
      day: DateTime(2026, 11, 19),
      mealType: MealType.breakfast,
    );

    expect(await _text(tester, 'de', thursday), 'Für Do · Frühstück');
    expect(await _text(tester, 'en', thursday), 'For Thu · Breakfast');
  });

  testWidgets('a day that has passed or lies a week ahead shows its date', (
    tester,
  ) async {
    expect(
      await _text(tester, 'en', (
        day: DateTime(2026, 11, 17),
        mealType: MealType.lunch,
      )),
      'For Nov 17 · Lunch',
    );
    expect(
      await _text(tester, 'en', (
        day: DateTime(2026, 11, 25),
        mealType: MealType.lunch,
      )),
      'For Nov 25 · Lunch',
    );
  });

  testWidgets('a list entry shows its note and the planned meal', (
    tester,
  ) async {
    final item = ShoppingListItem(
      id: 'milk',
      name: 'Milk',
      normalizedName: 'milk',
      normalizedBrand: '',
      quantity: 1,
      estimatedUnitPrice: 0,
      note: '1 l',
      plannedFor: (day: DateTime(2026, 11, 19), mealType: MealType.breakfast),
    );
    await _pump(tester, 'en', (context) {
      return ShoppingListEntryTile(
        item: item,
        placement: (
          shelf: ShoppingShelf.other,
          icon: ShoppingItemIcon.other,
          isAssigned: true,
        ),
        onTap: () {},
        onLongPress: () {},
      );
    });

    expect(find.text('1 l · For Thu · Breakfast'), findsOneWidget);
  });
}
