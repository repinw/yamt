import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_sheet/ai_chef_must_use_sheet.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

InventoryItem _item(String id, String name, DateTime entry) =>
    InventoryItem.create(
      id: id,
      name: name,
      entryDate: entry,
      storeName: 'Store',
      quantity: 1,
      initialAmount: 200,
      currentAmount: 200,
      amountUnit: InventoryAmountUnit.gram,
    );

void main() {
  testWidgets('shows ages, filters, and pops the picked ids', (tester) async {
    Set<String>? result;
    final items = [
      _item('spinach', 'Spinat', DateTime(2026, 11, 3)),
      _item('quark', 'Magerquark', DateTime(2026, 11, 10)),
    ];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await AiChefMustUseSheet.show(
                  context,
                  items: items,
                  selectedIds: const {'quark'},
                  today: DateTime(2026, 11, 15, 9),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('12 Tage'), findsOneWidget);
    expect(find.text('5 Tage'), findsOneWidget);
    expect(find.text('Übernehmen (1)'), findsOneWidget);

    await tester.enterText(find.byKey(AiChefMustUseSheet.searchKey), 'spin');
    await tester.pump();
    expect(find.text('Magerquark'), findsNothing);

    await tester.tap(find.byKey(AiChefMustUseSheet.rowKey('spinach')));
    await tester.pump();
    await tester.tap(find.byKey(AiChefMustUseSheet.applyKey));
    await tester.pumpAndSettle();

    expect(result, {'quark', 'spinach'});
  });
}
