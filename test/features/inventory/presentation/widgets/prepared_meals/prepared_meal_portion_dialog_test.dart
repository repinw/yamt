import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_sheet.dart';
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

void main() {
  testWidgets('portion dialog opens on root navigator by default', (
    tester,
  ) async {
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
    await tester.tap(find.text('Open portions'));
    await tester.pumpAndSettle();

    expectRootPopupRoutePushed(
      rootObserver: rootObserver,
      nestedObserver: nestedObserver,
    );
    expect(find.text('Throw away portions'), findsOneWidget);
  });

  testWidgets('portion dialog returns selected amount on confirm', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _ActionDialogsHarness(meal: _meal()),
        ),
      ),
    );

    await tester.tap(find.text('Open portions'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('portions:1'), findsOneWidget);
  });

  testWidgets('portion dialog defaults to fractional remaining portions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _ActionDialogsHarness(
            meal: _meal().copyWith(remainingPortions: 0.5),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open portions'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, '0,5');

    await tester.tap(find.text('Bestätigen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('portions:0.5'), findsOneWidget);
  });

  testWidgets('portion dialog can fill all remaining portions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _ActionDialogsHarness(meal: _meal()),
        ),
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
