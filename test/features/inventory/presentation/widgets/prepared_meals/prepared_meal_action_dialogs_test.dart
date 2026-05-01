import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_action_dialogs.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../support/prepared_meal_test_data.dart';

PreparedMeal _meal() => preparedMealTestData();

class _ActionDialogsHarness extends StatefulWidget {
  const _ActionDialogsHarness({required this.meal, this.pickLoggedDay});

  final PreparedMeal meal;
  final Future<DateTime?> Function({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  })?
  pickLoggedDay;

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
              final result = await showPreparedMealEatDialog(
                context,
                widget.meal,
                pickLoggedDay: widget.pickLoggedDay,
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

void main() {
  testWidgets('eat sheet shows validation for invalid portions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _ActionDialogsHarness(meal: _meal()),
      ),
    );

    await tester.tap(find.text('Open eat'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('prepared_meal_portions_field')),
      '99',
    );
    await tester.tap(find.byKey(const Key('prepared_meal_eat_confirm_button')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Please enter a valid portion count within the available range.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('prepared_meal_portions_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('prepared_meal_logged_at_compact')),
      findsOneWidget,
    );
  });

  testWidgets('eat sheet clear button uses broom and focuses portions field', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _ActionDialogsHarness(meal: _meal()),
      ),
    );

    await tester.tap(find.text('Open eat'));
    await tester.pumpAndSettle();

    final portionsField = find.byKey(const Key('prepared_meal_portions_field'));
    expect(find.byIcon(Icons.cleaning_services_outlined), findsOneWidget);

    await tester.enterText(portionsField, '2');
    await tester.tap(
      find.byKey(const Key('prepared_meal_portions_clear_button')),
    );
    await tester.pump();

    final textField = tester.widget<TextField>(portionsField);
    expect(textField.controller?.text, isEmpty);
    expect(textField.focusNode?.hasFocus, isTrue);
  });

  testWidgets('eat sheet quick chips update portions and nutrition metrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _ActionDialogsHarness(meal: _meal()),
      ),
    );

    await tester.tap(find.text('Open eat'));
    await tester.pumpAndSettle();

    final caloriesValue = find.byKey(
      const Key('prepared_meal_nutrition_value_0'),
    );
    expect(tester.widget<Text>(caloriesValue).data, '133');

    await tester.tap(find.text('All'));
    await tester.pump();

    final portionsField = tester.widget<TextField>(
      find.byKey(const Key('prepared_meal_portions_field')),
    );
    expect(portionsField.controller?.text, '2');
    expect(tester.widget<Text>(caloriesValue).data, '267');
  });

  testWidgets('eat dialog returns selected meal day on confirm', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(
      DateTime.now(),
    ).toIso8601String().substring(0, 10);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _ActionDialogsHarness(meal: _meal()),
      ),
    );

    await tester.tap(find.text('Open eat'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('prepared_meal_eat_confirm_button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('eat:1:'), findsOneWidget);
    expect(find.textContaining(':$today'), findsOneWidget);
  });

  testWidgets('eat dialog keeps selected day when date picker is cancelled', (
    tester,
  ) async {
    var pickerCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _ActionDialogsHarness(
          meal: _meal(),
          pickLoggedDay:
              ({
                required context,
                required initialDate,
                required firstDate,
                required lastDate,
              }) async {
                pickerCalls += 1;
                return null;
              },
        ),
      ),
    );

    await tester.tap(find.text('Open eat'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('prepared_meal_logged_at_compact')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('prepared_meal_logged_at_button')));
    await tester.pumpAndSettle();

    expect(pickerCalls, 1);
    expect(
      find.byKey(const Key('prepared_meal_logged_at_compact')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('prepared_meal_eat_confirm_button')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        ':${DateTime.now().toIso8601String().substring(0, 10)}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('eat dialog ignores future dates and passes today as limit', (
    tester,
  ) async {
    DateTime? capturedLastDate;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _ActionDialogsHarness(
          meal: _meal(),
          pickLoggedDay:
              ({
                required context,
                required initialDate,
                required firstDate,
                required lastDate,
              }) async {
                capturedLastDate = lastDate;
                return lastDate.add(const Duration(days: 1));
              },
        ),
      ),
    );

    await tester.tap(find.text('Open eat'));
    await tester.pumpAndSettle();

    final today = DateUtils.dateOnly(DateTime.now());
    expect(
      find.byKey(const Key('prepared_meal_logged_at_compact')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('prepared_meal_logged_at_button')));
    await tester.pumpAndSettle();

    expect(capturedLastDate, today);
    expect(
      find.byKey(const Key('prepared_meal_logged_at_compact')),
      findsOneWidget,
    );
  });

  testWidgets('portion dialog returns selected amount on confirm', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _ActionDialogsHarness(meal: _meal()),
      ),
    );

    await tester.tap(find.text('Open portions'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('portions:1'), findsOneWidget);
  });

  testWidgets('portion dialog can fill all remaining portions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _ActionDialogsHarness(meal: _meal()),
      ),
    );

    await tester.tap(find.text('Open portions'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('prepared_meal_portion_dialog_fill_button')),
    );
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, '2');

    await tester.tap(find.text('Confirm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('portions:2'), findsOneWidget);
  });
}
