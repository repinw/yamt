import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_amount_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_components_list.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_when_menu.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_portion_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/root_navigator_test_utils.dart';
import '../../../../../support/prepared_meal_test_data.dart';

PreparedMeal _meal() => preparedMealTestData();

class _ActionDialogsHarness extends StatefulWidget {
  const new({required this.meal});

  final PreparedMeal meal;

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
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _ActionDialogsHarness(meal: meal),
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
}
