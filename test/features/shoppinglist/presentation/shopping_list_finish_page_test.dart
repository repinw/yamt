import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_trip_summary.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_list_finish_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

ShoppingListItem _saved(String name) => ShoppingListItem(
  id: name,
  name: name,
  normalizedName: name.toLowerCase(),
  normalizedBrand: '',
  quantity: 1,
  estimatedUnitPrice: 0,
  isDone: true,
  isFavorite: true,
);

void main() {
  testWidgets('saved names read as a list in the language', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ShoppingListFinishPage(
          trip: ShoppingTripSummary([
            _saved('Milch'),
            _saved('Brot'),
            _saved('Eier'),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Milch, Brot und Eier bleiben'), findsOneWidget);
  });
}
