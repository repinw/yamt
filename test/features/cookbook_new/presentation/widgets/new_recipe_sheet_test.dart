import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'new_recipe_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _openKey = ValueKey<String>('open-sheet');

Widget _app(List<NewRecipeChoice?> chosen) => MaterialApp(
  locale: const Locale('de'),
  localizationsDelegates: appLocalizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          key: _openKey,
          onPressed: () async => chosen.add(await NewRecipeSheet.show(context)),
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(_openKey));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('offers every way to start a recipe', (tester) async {
    await tester.pumpWidget(_app([]));
    await _open(tester);

    expect(find.byType(NewRecipeSheet), findsOneWidget);
    for (final choice in NewRecipeChoice.values) {
      expect(
        find.byKey(NewRecipeSheet.entryKey(choice)),
        findsOneWidget,
        reason: choice.name,
      );
    }
  });

  for (final choice in NewRecipeChoice.values) {
    testWidgets('tapping "${choice.name}" closes the sheet with it', (
      tester,
    ) async {
      final chosen = <NewRecipeChoice?>[];
      await tester.pumpWidget(_app(chosen));
      await _open(tester);

      final entry = find.byKey(NewRecipeSheet.entryKey(choice));
      await tester.ensureVisible(entry);
      await tester.pumpAndSettle();
      await tester.tap(entry);
      await tester.pumpAndSettle();

      expect(chosen, [choice]);
      expect(find.byType(NewRecipeSheet), findsNothing);
    });
  }

  testWidgets('closing the sheet without a choice returns null', (
    tester,
  ) async {
    final chosen = <NewRecipeChoice?>[];
    await tester.pumpWidget(_app(chosen));
    await _open(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(chosen, [null]);
    expect(find.byType(NewRecipeSheet), findsNothing);
  });
}
