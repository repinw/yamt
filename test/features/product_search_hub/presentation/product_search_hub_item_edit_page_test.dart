import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_item_edit_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('opens the editor with the item and saves with "Save"', (
    tester,
  ) async {
    final items = StreamController<List<InventoryItem>>();
    addTearDown(items.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryQuickEatItemsProvider.overrideWith((ref) => items.stream),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProductSearchHubItemEditPage(itemId: 'milk'),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    items.add([
      InventoryItem.create(
        id: 'milk',
        name: 'Oat milk',
        entryDate: DateTime(2026, 9, 29),
        storeName: 'Store',
        quantity: 1,
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Oat milk'), findsWidgets);
  });
}
