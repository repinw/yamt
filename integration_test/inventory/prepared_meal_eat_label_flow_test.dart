import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/inventory/data/prepared_meal_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/presentation/prepared_meal_eat_flow.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_label_table.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_pot_weighing_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'prepared_meal_eat_sheet_body.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/fake_prepared_meal_repository.dart';

const _openKey = Key('open_meal_eat_page');
const _cancelKey = Key('prepared_meal_eat_cancel_button');
final _now = DateTime(2026, 10, 13, 12);

/// A cooked soup of 2 portions: 400 kcal, 8 g fat, 40 g carbs and 20 g
/// protein, weighed at "Gekocht" when [cookedWeight] is given.
PreparedMeal _soup({int? cookedWeight}) {
  return PreparedMeal(
    id: 'soup',
    name: 'Linsensuppe',
    totalPortions: 2,
    remainingPortions: 2,
    totalKcal: 400,
    totalProtein: 20,
    totalCarbs: 40,
    totalFat: 8,
    createdAt: _now,
    updatedAt: _now,
    components: const <PreparedMealComponent>[],
    finalNetWeight: cookedWeight,
    potTareWeight: cookedWeight == null ? null : 1180,
  );
}

Widget _harness(FakePreparedMealRepository meals) {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => _now),
      preparedMealRepositoryProvider.overrideWithValue(meals),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              key: _openKey,
              onPressed: () => PreparedMealEatFlow.eat(
                context: context,
                meal: meals.meals.single,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String description,
}) async {
  for (var step = 0; step < 100; step++) {
    if (condition()) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  throw TestFailure('Timed out waiting for $description.');
}

Future<void> _openEatPage(WidgetTester tester, PreparedMeal meal) async {
  final meals = FakePreparedMealRepository(meals: [meal]);
  await tester.pumpWidget(_harness(meals));
  await tester.pump();
  await tester.tap(find.byKey(_openKey));
  await _pumpUntil(
    tester,
    () => _tableFinder.evaluate().isNotEmpty,
    description: 'the nutrition table of the eat page',
  );
}

final Finder _tableFinder = find.byKey(
  PreparedMealEatSheetBody.nutritionTableKey,
);

EatLabelTable _table(WidgetTester tester) {
  return tester.widget<EatLabelTable>(_tableFinder);
}

/// The per-100 and the eaten value of the energy row.
(String?, String) _energy(WidgetTester tester) {
  final energy = _table(tester).rows.first;
  return (energy.per100, energy.eaten);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('a cooked meal without its weight shows only the portion '
      'column', (tester) async {
    await _openEatPage(tester, _soup());

    expect(_table(tester).per100Header, isNull);
    expect(_energy(tester), (null, '837 kJ\n200 kcal'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a weighed meal shows "Je 100 g" beside the portion, and the '
      'pot on the scale updates it', (tester) async {
    await _openEatPage(tester, _soup(cookedWeight: 800));

    expect(_table(tester).per100Header, isNotNull);
    // 400 kcal in 800 g; one portion is half of it.
    expect(_energy(tester), ('209 kJ\n50 kcal', '837 kJ\n200 kcal'));
    expect(_table(tester).rows.last.per100, '2,5 g');

    // Water evaporated: 1000 g are in the pot now.
    final gross = find.byKey(EatPotWeighingSection.grossKey);
    await tester.ensureVisible(gross);
    await tester.enterText(gross, '2180');
    await _pumpUntil(
      tester,
      () => _energy(tester).$1 == '167 kJ\n40 kcal',
      description: 'the values per 100 g of the weighed pot',
    );

    expect(_energy(tester), ('167 kJ\n40 kcal', '837 kJ\n200 kcal'));
    expect(_table(tester).rows.last.per100, '2 g');

    await tester.ensureVisible(find.byKey(_cancelKey));
    await tester.tap(find.byKey(_cancelKey));
    await _pumpUntil(
      tester,
      () => _tableFinder.evaluate().isEmpty,
      description: 'the eat page to close',
    );
    expect(tester.takeException(), isNull);
  });
}
