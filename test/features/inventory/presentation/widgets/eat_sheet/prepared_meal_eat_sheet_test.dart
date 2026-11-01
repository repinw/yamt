import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_amount_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_components_list.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_label_table.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_scaffold.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_pot_weighing_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_when_menu.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'prepared_meal_eat_sheet_body.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_portion_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/root_navigator_test_utils.dart';
import '../../../../../support/prepared_meal_test_data.dart';

PreparedMeal _meal() => preparedMealTestData();

class _ActionDialogsHarness extends StatefulWidget {
  const new({required this.meal, this.initialLoggedAt});

  final PreparedMeal meal;
  final DateTime? initialLoggedAt;

  @override
  State<_ActionDialogsHarness> createState() => _ActionDialogsHarnessState();
}

class _ActionDialogsHarnessState extends State<_ActionDialogsHarness> {
  String? _resultLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () async {
              final result = await showPreparedMealEatSheet(
                context,
                widget.meal,
                initialLoggedAt: widget.initialLoggedAt,
              );
              if (!mounted || result == null) {
                return;
              }
              final loggedDay = result.loggedDay.toIso8601String().substring(
                0,
                10,
              );
              setState(() {
                _resultLabel =
                    'eat:${result.portions}:${result.mealType.name}:$loggedDay';
              });
            },
            child: const Text('Open eat'),
          ),
          TextButton(
            onPressed: () async {
              final result = await showPreparedMealPortionDialog(
                context: context,
                meal: widget.meal,
                title: 'Throw away portions',
              );
              if (!mounted || result == null) {
                return;
              }
              setState(() {
                _resultLabel = 'portions:$result';
              });
            },
            child: const Text('Open portions'),
          ),
          if (_resultLabel != null) Text(_resultLabel!),
        ],
      ),
    );
  }
}

const _confirmKey = Key('prepared_meal_eat_confirm_button');

Future<void> _openEat(
  WidgetTester tester,
  PreparedMeal meal, {
  Locale locale = const Locale('en'),
  DateTime? now,
  DateTime? initialLoggedAt,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [if (now != null) clockProvider.overrideWithValue(() => now)],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _ActionDialogsHarness(
          meal: meal,
          initialLoggedAt: initialLoggedAt,
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open eat'));
  await tester.pumpAndSettle();
}

String? _amountText(WidgetTester tester) {
  return tester
      .widget<TextField>(find.byKey(EatAmountRuler.fieldKey))
      .controller
      ?.text;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

EatLabelTable _table(WidgetTester tester) {
  return tester.widget<EatLabelTable>(
    find.byKey(PreparedMealEatSheetBody.nutritionTableKey),
  );
}

/// The per-100 and eaten value of each row of the nutrition table.
List<(String?, String)> _tableValues(WidgetTester tester) {
  return [for (final row in _table(tester).rows) (row.per100, row.eaten)];
}

/// The value of the nutrition label row [label], or null without the row.
String? _labelValue(WidgetTester tester, String label) {
  final name = find.descendant(
    of: find.byKey(PreparedMealEatSheetBody.nutritionTableKey),
    matching: find.text(label),
  );
  if (name.evaluate().isEmpty) {
    return null;
  }
  final row = find.ancestor(of: name, matching: find.byType(Row)).first;
  return tester
      .widgetList<Text>(find.descendant(of: row, matching: find.byType(Text)))
      .last
      .data;
}

PreparedMealComponent _ingredient(String id, GlobalFoodNutrition label) {
  return labeledIngredientTestData(
    labeledFoodTestData(id: id, name: id, grams: 1000, label: label),
    id == 'rice' ? 200 : 300,
  );
}

void main() {
  testWidgets('eat page opens on the root navigator', (tester) async {
    final rootObserver = RecordingNavigatorObserver();
    final nestedObserver = RecordingNavigatorObserver();

    await tester.pumpWidget(
      ProviderScope(
        child: nestedNavigatorHarness(
          rootObserver: rootObserver,
          nestedObserver: nestedObserver,
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: _ActionDialogsHarness(meal: _meal()),
        ),
      ),
    );

    rootObserver.clear();
    nestedObserver.clear();
    await tester.tap(find.text('Open eat'));
    await tester.pumpAndSettle();

    expectRootPageRoutePushed(
      rootObserver: rootObserver,
      nestedObserver: nestedObserver,
    );
    expect(find.byKey(EatAmountRuler.fieldKey), findsOneWidget);
  });

  testWidgets('shows the portions left and validates the amount', (
    tester,
  ) async {
    await _openEat(tester, _meal());

    expect(find.text('2 port. in stock'), findsOneWidget);

    await tester.enterText(find.byKey(EatAmountRuler.fieldKey), '99');
    await _tap(tester, find.byKey(_confirmKey));

    expect(
      find.text(
        'Please enter a valid portion count within the available range.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(EatAmountRuler.fieldKey), findsOneWidget);
  });

  testWidgets('marks set the portions and the calories follow', (tester) async {
    await _openEat(tester, _meal());

    expect(find.text('133 kcal'), findsOneWidget);

    await _tap(tester, find.text('All'));
    expect(_amountText(tester), '2');
    expect(find.text('267 kcal'), findsOneWidget);

    await _tap(tester, find.text('½'));
    expect(_amountText(tester), '0.5');
    expect(find.text('67 kcal'), findsOneWidget);
  });

  testWidgets('returns the portions and today on confirm', (tester) async {
    final today = DateUtils.dateOnly(DateTime.now())
        .toIso8601String()
        .substring(0, 10);
    await _openEat(tester, _meal());

    await tester.enterText(find.byKey(EatAmountRuler.fieldKey), '0.5');
    await _tap(tester, find.byKey(_confirmKey));

    expect(find.textContaining('eat:0.5:'), findsOneWidget);
    expect(find.textContaining(':$today'), findsOneWidget);
  });

  testWidgets('the unit switches to grams and converts back to portions', (
    tester,
  ) async {
    await _openEat(
      tester,
      _meal().copyWith(
        totalPortions: 4,
        remainingPortions: 4,
        finalNetWeight: 3000,
      ),
    );

    expect(find.text('≈ 750 g'), findsOneWidget);
    await _tap(tester, find.byKey(EatAmountRuler.unitKey));
    expect(_amountText(tester), '750');

    await tester.enterText(find.byKey(EatAmountRuler.fieldKey), '1500');
    await tester.pump();
    expect(find.text('≈ 2 port.'), findsOneWidget);
    await _tap(tester, find.byKey(_confirmKey));

    expect(find.textContaining('eat:2.0:'), findsOneWidget);
  });

  testWidgets('grams use the remaining weight, not the stored one', (
    tester,
  ) async {
    await _openEat(
      tester,
      PreparedMeal.fromJson({
        ..._meal()
            .copyWith(
              totalPortions: 4,
              remainingPortions: 0.005,
              finalNetWeight: 2253,
            )
            .toJson(),
        'remaining_net_weight': 2253,
      }),
    );

    await _tap(tester, find.byKey(EatAmountRuler.unitKey));
    await _tap(tester, find.text('All'));
    expect(_amountText(tester), '3');
    await _tap(tester, find.byKey(_confirmKey));

    expect(find.textContaining('eat:0.005:'), findsOneWidget);
  });

  testWidgets('a meal not weighed after cooking shows only the portion '
      'column', (tester) async {
    await _openEat(tester, _meal());

    expect(_table(tester).per100Header, isNull);
    expect(_tableValues(tester), [
      (null, '558 kJ\n133 kcal'),
      (null, '2.67 g'),
      (null, '13.33 g'),
      (null, '6.67 g'),
    ]);
    expect(find.text('Per 100 g'), findsNothing);
  });

  testWidgets('a weighed meal shows every nutrient per 100 g beside the '
      'portion', (tester) async {
    // 400 kcal, 8 g fat, 40 g carbs and 20 g protein in 800 g.
    await _openEat(
      tester,
      _meal().copyWith(
        totalPortions: 4,
        remainingPortions: 4,
        finalNetWeight: 800,
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(PreparedMealEatSheetBody.nutritionTableKey),
        matching: find.text('Per 100 g'),
      ),
      findsOneWidget,
    );
    expect(_table(tester).eatenHeader, '1 portion · 200 g');
    expect(_tableValues(tester), [
      ('209 kJ\n50 kcal', '418 kJ\n100 kcal'),
      ('1 g', '2 g'),
      ('5 g', '10 g'),
      ('2.5 g', '5 g'),
    ]);

    // More portions change only the portion column.
    await _tap(tester, find.text('2'));
    expect(_tableValues(tester).first, ('209 kJ\n50 kcal', '837 kJ\n200 kcal'));
  });

  testWidgets('weighing the pot on the page updates the values per 100 g', (
    tester,
  ) async {
    // 400 kcal in 800 g at "Gekocht", in a 1180 g pot.
    await _openEat(
      tester,
      _meal().copyWith(
        totalPortions: 2,
        remainingPortions: 2,
        finalNetWeight: 800,
        potTareWeight: 1180,
      ),
    );
    expect(_tableValues(tester).first, ('209 kJ\n50 kcal', '837 kJ\n200 kcal'));

    // Water evaporated: 1000 g are in the pot now.
    final gross = find.byKey(EatPotWeighingSection.grossKey);
    await tester.ensureVisible(gross);
    await tester.enterText(gross, '2180');
    await tester.pumpAndSettle();

    expect(_table(tester).per100Header, 'Per 100 g');
    expect(_tableValues(tester).first, ('167 kJ\n40 kcal', '837 kJ\n200 kcal'));
  });

  testWidgets('starts with the fractional portions left', (tester) async {
    await _openEat(
      tester,
      _meal().copyWith(remainingPortions: 0.5),
      locale: const Locale('de'),
    );

    expect(_amountText(tester), '0,5');
    await _tap(tester, find.byKey(_confirmKey));

    expect(find.textContaining('eat:0.5:'), findsOneWidget);
  });

  testWidgets('a cancelled date picker keeps today', (tester) async {
    await _openEat(tester, _meal());

    await _tap(tester, find.byKey(EatWhenMenu.buttonKey));
    await _tap(tester, find.byKey(EatWhenMenu.pickDayKey));
    await _tap(tester, find.text('Cancel'));

    expect(find.textContaining('TODAY'), findsOneWidget);
    await _tap(tester, find.byKey(_confirmKey));

    expect(
      find.textContaining(
        ':${DateTime.now().toIso8601String().substring(0, 10)}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('lists the ingredients scaled to the portions', (tester) async {
    await _openEat(tester, _meal());

    expect(find.text('1 ingredient'), findsOneWidget);
    expect(find.text('Rice'), findsNothing);

    await _tap(tester, find.byKey(EatComponentsList.toggleKey));

    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('33.3 g'), findsOneWidget);

    await _tap(tester, find.text('All'));

    expect(find.text('66.7 g'), findsOneWidget);
  });

  testWidgets('a meal in the pot cannot be logged before "Gekocht", only '
      'planned as a share of the pot', (tester) async {
    await _openEat(tester, _meal().copyWith(inPot: true));

    expect(find.text('In the pot'), findsOneWidget);
    expect(find.text('pot'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(_confirmKey)).onPressed,
      isNull,
    );
    expect(find.byKey(EatPageScaffold.planButtonKey), findsOneWidget);
  });

  testWidgets('a later day plans with the confirm button and hides Plan', (
    tester,
  ) async {
    await _openEat(
      tester,
      _meal(),
      now: DateTime(2026, 9, 26, 12),
      initialLoggedAt: DateTime(2026, 9, 27, 12),
    );

    expect(
      find.descendant(of: find.byKey(_confirmKey), matching: find.text('Plan')),
      findsOneWidget,
    );
    expect(find.byKey(EatPageScaffold.planButtonKey), findsNothing);
  });

  testWidgets('a meal with open rows cannot be eaten, only planned as a '
      'reminder', (tester) async {
    await _openEat(
      tester,
      _meal().copyWith(pendingRecipeIngredients: const ['Salz']),
    );

    expect(
      tester.widget<FilledButton>(find.byKey(_confirmKey)).onPressed,
      isNull,
    );
    expect(find.byKey(EatPageScaffold.planButtonKey), findsOneWidget);
    expect(
      find.byKey(PreparedMealEatSheetBody.reminderHintKey),
      findsOneWidget,
    );
  });

  testWidgets('the nutrition label shows every nutrient that the '
      'ingredients list, per portion', (tester) async {
    final rice = _ingredient('rice', riceLabelTestData);
    await _openEat(
      tester,
      labeledMealTestData(ingredients: [rice, rice], totalPortions: 2),
    );

    expect(_labelValue(tester, 'Energy'), '2,929 kJ\n700 kcal');
    expect(_labelValue(tester, 'Fat'), '2 g');
    expect(_labelValue(tester, 'of which saturates'), '1 g');
    expect(_labelValue(tester, 'Carbs'), '150 g');
    expect(_labelValue(tester, 'of which sugars'), '2 g');
    expect(_labelValue(tester, 'Fibre'), '4 g');
    expect(_labelValue(tester, 'Protein'), '16 g');
    expect(_labelValue(tester, 'Salt'), '0.5 g');
    expect(_labelValue(tester, 'of which polyunsaturates'), isNull);
  });

  testWidgets('a nutrient that one ingredient lacks shows as a minimum', (
    tester,
  ) async {
    await _openEat(
      tester,
      labeledMealTestData(
        ingredients: [
          _ingredient('rice', riceLabelTestData),
          _ingredient('sauce', sauceLabelTestData),
        ],
      ),
    );

    expect(_labelValue(tester, 'Fat'), '8 g');
    expect(_labelValue(tester, 'Protein'), '20.5 g');
    for (final label in [
      'of which saturates',
      'of which sugars',
      'Fibre',
      'Salt',
    ]) {
      expect(_labelValue(tester, label), startsWith('≥'), reason: label);
    }
    expect(_labelValue(tester, 'of which polyunsaturates'), isNull);
  });
}
