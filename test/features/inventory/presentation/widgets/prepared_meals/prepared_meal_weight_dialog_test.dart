import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_weight_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../support/prepared_meal_test_data.dart';

/// 3 portions, 2 left, cooked at 900 g.
PreparedMeal _meal({int? tare, num remaining = 2}) =>
    preparedMealTestData(remainingPortions: remaining)
        .copyWith(finalNetWeight: 900, potTareWeight: tare);

/// Opens the dialog for [meal] and records what it returns.
Future<List<int?>> _open(WidgetTester tester, PreparedMeal meal) async {
  final results = <int?>[];
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await showPreparedMealWeightDialog(context: context, meal: meal),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

FilledButton _save(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(PreparedMealWeightDialog.saveKey));

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(PreparedMealWeightDialog.fieldKey), text);
  await tester.pump();
}

void main() {
  testWidgets('a pot meal weighs the pot and takes the empty pot off', (
    tester,
  ) async {
    final results = await _open(tester, _meal(tare: 1180));

    expect(find.text('Pot on the scale'), findsOneWidget);
    expect(find.text('So far 1780 g'), findsOneWidget);
    expect(_save(tester).onPressed, isNull);

    await _type(tester, '1000');
    expect(find.text('Not heavier than the empty container'), findsOneWidget);
    expect(_save(tester).onPressed, isNull);

    await _type(tester, '1730');
    expect(find.byKey(PreparedMealWeightDialog.netKey), findsOneWidget);
    expect(find.text('− empty pot 1180 g = 550 g in the pot'), findsOneWidget);

    await tester.tap(find.byKey(PreparedMealWeightDialog.saveKey));
    await tester.pumpAndSettle();

    expect(results, [550]);
    expect(find.byType(PreparedMealWeightDialog), findsNothing);
  });

  testWidgets('a meal without a pot weighs the food, decimals rounded', (
    tester,
  ) async {
    final results = await _open(tester, _meal());

    expect(find.text('Weight of the food'), findsOneWidget);
    expect(find.byKey(PreparedMealWeightDialog.netKey), findsNothing);

    await _type(tester, '0');
    expect(find.text('Enter a weight in grams.'), findsOneWidget);
    expect(_save(tester).onPressed, isNull);

    await _type(tester, '550,6');
    expect(find.text('Enter a weight in grams.'), findsNothing);
    await tester.tap(find.byKey(PreparedMealWeightDialog.saveKey));
    await tester.pumpAndSettle();

    expect(results, [551]);
  });

  testWidgets('says whether it weighs the whole dish or what is left', (
    tester,
  ) async {
    await _open(tester, _meal(remaining: 3));
    expect(find.textContaining('Weigh the whole dish'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await _open(tester, _meal());
    expect(
      find.textContaining('Weigh what is left: 2 of 3 portions.'),
      findsOneWidget,
    );
    expect(find.textContaining('Diary entries stay as they are.'), findsOne);
  });

  testWidgets('cancel returns nothing', (tester) async {
    final results = await _open(tester, _meal());

    await _type(tester, '500');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(results, [null]);
  });
}
