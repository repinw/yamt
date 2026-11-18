import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_sheet/ai_chef_loading_view.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('keeps the same height for a short and a long quote', (
    tester,
  ) async {
    // Narrow enough that a long quote wraps to two lines and a short one
    // does not.
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final heights = <double>{};
    // Each new key picks a quote at random; 16 of them meet the short and
    // the long quotes.
    for (var round = 0; round < 16; round++) {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Align(
            alignment: Alignment.bottomCenter,
            child: Material(child: AiChefLoadingView(key: ValueKey(round))),
          ),
        ),
      );
      heights.add(tester.getSize(find.byType(AiChefLoadingView)).height);
    }

    expect(heights, hasLength(1));
  });

  testWidgets('fills the width, whatever the quote', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Loose like a modal sheet, which is only as wide as its content.
        home: Align(
          alignment: Alignment.bottomCenter,
          child: Material(child: AiChefLoadingView()),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(AiChefLoadingView)).width,
      tester.view.physicalSize.width / tester.view.devicePixelRatio,
    );
  });
}
