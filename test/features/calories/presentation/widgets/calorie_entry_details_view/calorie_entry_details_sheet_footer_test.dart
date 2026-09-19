import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_sheet_footer.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('has no save button', (tester) async {
    await tester.pumpWidget(_wrapFooter(isSaving: false));

    expect(find.byKey(CalorieEntryEditorKeys.saveButton), findsNothing);
  });

  testWidgets('fires eat again and remove callbacks', (tester) async {
    var eatAgainCount = 0;
    var removeCount = 0;
    await tester.pumpWidget(
      _wrapFooter(
        isSaving: false,
        onEatAgain: () => eatAgainCount += 1,
        onReturnToInventory: () => removeCount += 1,
      ),
    );

    await tester.tap(find.byKey(CalorieEntryDetailKeys.eatAgainButton));
    await tester.tap(
      find.byKey(CalorieEntryDetailKeys.returnToInventoryButton),
    );

    expect(eatAgainCount, 1);
    expect(removeCount, 1);
  });

  testWidgets('disables actions while saving', (tester) async {
    await tester.pumpWidget(_wrapFooter(isSaving: true));

    final eatAgain = tester.widget<ButtonStyleButton>(
      find.descendant(
        of: find.byKey(CalorieEntryDetailKeys.eatAgainButton),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        matchRoot: true,
      ),
    );
    expect(eatAgain.onPressed, isNull);
  });

  testWidgets('keeps remove when eat again is unavailable', (tester) async {
    await tester.pumpWidget(_wrapFooter(canEatAgain: false, isSaving: false));

    expect(
      find.byKey(CalorieEntryDetailKeys.returnToInventoryButton),
      findsOneWidget,
    );
    expect(find.byKey(CalorieEntryDetailKeys.eatAgainButton), findsNothing);
  });
}

Widget _wrapFooter({
  required bool isSaving,
  bool canEatAgain = true,
  VoidCallback? onEatAgain,
  VoidCallback? onReturnToInventory,
}) {
  return MaterialApp(
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: CalorieEntryDetailsSheetFooter(
        canEatAgain: canEatAgain,
        isSaving: isSaving,
        onEatAgain: onEatAgain ?? () {},
        onReturnToInventory: onReturnToInventory ?? () {},
      ),
    ),
  );
}
