import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_dialog/ai_chef_setup_view.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('setup view captures inventory option and wishes', (
    tester,
  ) async {
    final wishesController = TextEditingController();
    addTearDown(wishesController.dispose);
    var includeInventory = true;
    var didGenerate = false;
    var didClose = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AiChefSetupView(
            wishesController: wishesController,
            includeInventory: includeInventory,
            onIncludeInventoryChanged: (value) {
              includeInventory = value;
            },
            onGenerate: () {
              didGenerate = true;
            },
            onClose: () {
              didClose = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Was soll die KI kochen?'), findsOneWidget);
    expect(find.text('Vorrat beachten'), findsOneWidget);
    expect(find.text('Wünsche'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'schnell und vegetarisch');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Rezept generieren'));
    await tester.tap(find.text('Schließen'));

    expect(includeInventory, isFalse);
    expect(wishesController.text, 'schnell und vegetarisch');
    expect(didGenerate, isTrue);
    expect(didClose, isTrue);
  });
}
