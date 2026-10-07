import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/diary/presentation/diary_inventory_food_picker.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_inventory_food_picker/diary_inventory_food_tile.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _openKey = Key('open-picker');

void main() {
  final ready = _meal('ready', 'Chili');
  final pot = _meal('pot', 'Linsensuppe').copyWith(inPot: true);
  final openRows = _meal(
    'rows',
    'Curry',
  ).copyWith(pendingRecipeIngredients: ['Salz', 'Reis']);

  testWidgets('shows open meals greyed out with their note', (tester) async {
    String? picked;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            key: _openKey,
            onPressed: () async {
              final selection =
                  await showModalBottomSheet<DiaryInventoryFoodSelection>(
                    context: context,
                    builder: (_) => DiaryInventoryFoodPicker(
                      items: const <InventoryItem>[],
                      meals: [ready],
                      openMeals: [pot, openRows],
                    ),
                  );
              picked = switch (selection) {
                DiaryOpenPreparedMealSelection(:final meal) =>
                  'open:${meal.id}',
                DiaryPreparedMealFoodSelection(:final meal) =>
                  'meal:${meal.id}',
                _ => null,
              };
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(_openKey));
    await tester.pumpAndSettle();

    DiaryInventoryFoodTile tile(String id) =>
        tester.widget(find.byKey(DiaryInventoryFoodPicker.mealKey(id)));
    expect(tile('ready').isMuted, isFalse);
    expect(tile('pot').isMuted, isTrue);
    expect(tile('pot').subtitle, 'Im Topf');
    expect(tile('rows').subtitle, '2 Zeilen offen');

    await tester.tap(find.byKey(DiaryInventoryFoodPicker.mealKey('pot')));
    await tester.pumpAndSettle();

    expect(picked, 'open:pot');
  });
}

Widget _app(Widget home) => ProviderScope(
  child: MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: home),
  ),
);

PreparedMeal _meal(String id, String name) => PreparedMeal(
  id: id,
  name: name,
  totalPortions: 2,
  remainingPortions: 2,
  totalKcal: 600,
  totalProtein: 30,
  totalCarbs: 60,
  totalFat: 20,
  createdAt: DateTime(2026, 10, 7),
  updatedAt: DateTime(2026, 10, 7),
  components: const <PreparedMealComponent>[],
);
