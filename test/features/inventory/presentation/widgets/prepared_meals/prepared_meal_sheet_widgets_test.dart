import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_sheet_widgets.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
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
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }
}
