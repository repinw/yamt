import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_sheet_widgets.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('validates name field and clears text', (tester) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: 'Meal');
    final changedValues = <String>[];

    await tester.pumpWidget(
      _TestApp(
        child: PreparedMealSheetContainer(
          formKey: formKey,
          children: [
            PreparedMealNameField(
              controller: controller,
              textInputAction: TextInputAction.done,
              onChanged: changedValues.add,
            ),
          ],
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isTrue);

    await tester.tap(find.byTooltip('Clear name'));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(changedValues, <String>['']);
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Please enter a meal name.'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('primary action fires and cancel closes route', (tester) async {
    var primaryTapCount = 0;

    await tester.pumpWidget(
      _TestApp(
        child: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  builder: (context) {
                    return PreparedMealSheetContainer(
                      formKey: GlobalKey<FormState>(),
                      children: [
                        const Text('Sheet body'),
                        PreparedMealSheetActions(
                          primaryLabel: 'Save',
                          onPrimaryPressed: () {
                            primaryTapCount += 1;
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(primaryTapCount, 1);
    expect(find.text('Sheet body'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Sheet body'), findsNothing);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }
}
