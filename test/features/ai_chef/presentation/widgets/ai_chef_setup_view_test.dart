import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_sheet/ai_chef_setup_view.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('setup view captures inventory option and wishes', (
    tester,
  ) async {
    final wishesController = TextEditingController();
    addTearDown(wishesController.dispose);
    var includeInventory = true;
    var didGenerate = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
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
          ),
        ),
      ),
    );

    expect(find.text('Worauf hast du Lust?'), findsOneWidget);
    expect(find.text('Vorrat beachten'), findsOneWidget);
    expect(find.text('Wünsche'), findsOneWidget);
    expect(find.text('Rezept vorschlagen'), findsOneWidget);

    await tester.enterText(
      find.byKey(AiChefSetupView.wishesKey),
      'schnell und vegetarisch',
    );
    await tester.tap(find.byKey(AiChefSetupView.inventoryKey));
    await tester.pump();
    await tester.tap(find.byKey(AiChefSetupView.generateKey));

    expect(includeInventory, isFalse);
    expect(wishesController.text, 'schnell und vegetarisch');
    expect(didGenerate, isTrue);
  });
}
