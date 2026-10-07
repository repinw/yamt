import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_search_actions/product_search_hub_search_actions.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('search actions tolerate cramped constraints', (tester) async {
    await tester.pumpWidget(
      _buildMaterialHarness(
        child: SizedBox(
          width: 4,
          child: ProductSearchHubSearchActions(
            onBarcodePressed: () {},
            onAiPressed: () {},
            onCreateOwnPressed: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const Key('product_search_hub_search_ai_action')),
      findsOneWidget,
    );
  });
}

Widget _buildMaterialHarness({required Widget child}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}
