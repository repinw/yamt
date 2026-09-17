import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_button/ai_chef_button.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('button opens recipe setup dialog', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _AiChefButtonTestHost(),
        ),
      ),
    );

    await tester.tap(find.byType(AiChefButton));
    await tester.pumpAndSettle();

    expect(find.text('Was soll die KI kochen?'), findsOneWidget);
    expect(find.text('Vorrat beachten'), findsOneWidget);
    expect(find.text('Rezept generieren'), findsOneWidget);
  });
}

class _AiChefButtonTestHost extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(actions: const [AiChefButton()]));
  }
}
