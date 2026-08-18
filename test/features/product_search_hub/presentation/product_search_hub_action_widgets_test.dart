import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_saved_selection.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_action_grid/product_search_hub_action_grid.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_search_actions/product_search_hub_search_actions.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_selection_overlay/'
    'product_search_hub_selection_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('action grid tolerates cramped constraints', (tester) async {
    await tester.pumpWidget(
      _buildMaterialHarness(
        child: const SizedBox(
          width: 20,
          child: ProductSearchHubActionGrid(showDiarySourceActions: true),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const Key('product_search_hub_barcode_action')),
      findsOneWidget,
    );
  });

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

  testWidgets('selection sheet closes after removing last product', (
    tester,
  ) async {
    var selections = [
      ProductSearchHubSavedSelection(
        item: _item(id: 'milk', name: 'Milk'),
        sourceKey: 'milk',
      ),
    ];

    await tester.pumpWidget(
      _buildRouterHarness(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              key: const Key('open_selection_sheet'),
              onPressed: () {
                unawaited(
                  showProductSearchHubSelectionSheet(
                    context: context,
                    selections: () => selections,
                    isSaving: () => false,
                    onRemoveSelection: (selection) async {
                      selections = const <ProductSearchHubSavedSelection>[];
                    },
                  ),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open_selection_sheet')));
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('product_search_hub_cart_remove_milk')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsNothing);
  });
}

Widget _buildMaterialHarness({required Widget child}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

Widget _buildRouterHarness({required Widget child}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(body: Center(child: child)),
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

InventoryItem _item({
  required String id,
  required String name,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.utc(2026),
    storeName: 'Store',
    quantity: 1,
    origin: InventoryItemOrigin.manualAdd,
  );
}
