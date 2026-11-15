import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/text_voice_search_bar/text_voice_search_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../helpers/fake_voice_search_service.dart';

void main() {
  const fieldKey = Key('search_field');
  const clearKey = Key('search_clear');

  testWidgets('the clear button shows a plain close icon', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TextVoiceSearchBar(
            controller: controller,
            label: 'Suche',
            fieldKey: fieldKey,
            clearButtonKey: clearKey,
            voiceSearchService: FakeVoiceSearchService(),
          ),
        ),
      ),
    );

    expect(find.byKey(clearKey), findsNothing);

    await tester.enterText(find.byKey(fieldKey), 'Reis');
    await tester.pump();

    expect(find.byKey(clearKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(clearKey),
        matching: find.byIcon(Icons.close_rounded),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.cleaning_services_outlined), findsNothing);
  });
}
