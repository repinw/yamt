import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_sheet_footer.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('disables save button while saving', (tester) async {
    await tester.pumpWidget(
      _wrapFooter(isSaving: true, hasPendingChanges: true),
    );

    final saveButton = tester.widget<FilledButton>(
      find.byKey(CalorieEntryEditorKeys.saveButton),
    );

    expect(saveButton.onPressed, isNull);
  });

  testWidgets('disables save button without pending changes', (tester) async {
    await tester.pumpWidget(
      _wrapFooter(isSaving: false, hasPendingChanges: false),
    );

    final saveButton = tester.widget<FilledButton>(
      find.byKey(CalorieEntryEditorKeys.saveButton),
    );

    expect(saveButton.onPressed, isNull);
  });

  testWidgets('hides return button when return is unavailable', (tester) async {
    await tester.pumpWidget(
      _wrapFooter(canReturn: false, isSaving: false, hasPendingChanges: true),
    );

    expect(
      find.byKey(CalorieEntryDetailKeys.returnToInventoryButton),
      findsNothing,
    );
  });
}

Widget _wrapFooter({
  required bool isSaving,
  required bool hasPendingChanges,
  bool canReturn = true,
}) {
  return MaterialApp(
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: CalorieEntryDetailsSheetFooter(
        canReturn: canReturn,
        isSaving: isSaving,
        hasPendingChanges: hasPendingChanges,
        onSave: () {},
        onReturnToInventory: () {},
      ),
    ),
  );
}
