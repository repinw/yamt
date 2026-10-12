import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_editor_page/manual_product_search_editor_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_form_details.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/manual_product_search_route_args.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/inventory_item_whole_list_writes.dart';

void main() {
  testWidgets('push helper returns typed result without route animation', (
    tester,
  ) async {
    String? result;

    final router = _buildManualProductRouteTestRouter(
      homeBuilder: (context) {
        return Scaffold(
          body: FilledButton(
            key: const Key('open_manual_product_route'),
            onPressed: () {
              unawaited(
                pushManualProductSearchPage<String>(
                  context: context,
                  args: ManualProductSearchRouteArgs.editor(
                    config: InventoryReceiptManualProductConfig(item: _item()),
                    showEatImmediatelyOption: false,
                    initialAction:
                        InventoryReceiptManualProductAction.addToInventory,
                    showActionSelector: true,
                  ),
                ).then((value) => result = value),
              );
            },
            child: const Text('open'),
          ),
        );
      },
    );
    addTearDown(router.dispose);

    await _pumpRouter(tester, router);

    await tester.tap(find.byKey(const Key('open_manual_product_route')));
    await tester.pump();

    expect(router.state.uri.queryParameters.keys, <String>['payload']);
    expect(router.state.uri.toString().length, lessThan(160));
    expect(
      find.byType(InventoryReceiptManualProductEditorPage),
      findsOneWidget,
    );

    popManualProductSearchPage(
      tester.element(find.byType(InventoryReceiptManualProductEditorPage)),
      'done',
    );
    await tester.pumpAndSettle();

    expect(result, 'done');
  });

  testWidgets('pop helper delegates to go_router when available', (
    tester,
  ) async {
    final router = _buildManualProductRouteTestRouter(
      homeBuilder: (context) {
        return Scaffold(
          body: FilledButton(
            key: const Key('open_go_router_route'),
            onPressed: () => unawaited(
              pushManualProductSearchPage<String>(
                context: context,
                args: ManualProductSearchRouteArgs.editor(
                  config: InventoryReceiptManualProductConfig(item: _item()),
                  showEatImmediatelyOption: false,
                  initialAction:
                      InventoryReceiptManualProductAction.addToInventory,
                  showActionSelector: true,
                ),
              ),
            ),
            child: const Text('home'),
          ),
        );
      },
    );
    addTearDown(router.dispose);

    await _pumpRouter(tester, router);

    await tester.tap(find.byKey(const Key('open_go_router_route')));
    await tester.pumpAndSettle();

    expect(
      find.byType(InventoryReceiptManualProductEditorPage),
      findsOneWidget,
    );

    popManualProductSearchPage(
      tester.element(find.byType(InventoryReceiptManualProductEditorPage)),
      'done',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('open_go_router_route')), findsOneWidget);
  });

  testWidgets('a new product says "Create"; an edit says "Done" and closes '
      'without a result', (tester) async {
    final results = <String?>[];
    final router = _buildManualProductRouteTestRouter(
      homeBuilder: (context) {
        Future<void> open({required bool isEdit}) async => results.add(
          await pushManualProductSearchPage<String>(
            context: context,
            args: ManualProductSearchRouteArgs.editor(
              config: InventoryReceiptManualProductConfig(item: _item()),
              showEatImmediatelyOption: false,
              initialAction: InventoryReceiptManualProductAction.addToInventory,
              showActionSelector: false,
              isEdit: isEdit,
            ),
          ),
        );
        return Scaffold(
          body: Column(
            children: [
              FilledButton(
                key: const Key('open_create'),
                onPressed: () => unawaited(open(isEdit: false)),
                child: const Text('create'),
              ),
              FilledButton(
                key: const Key('open_edit'),
                onPressed: () => unawaited(open(isEdit: true)),
                child: const Text('edit'),
              ),
            ],
          ),
        );
      },
    );
    addTearDown(router.dispose);
    await _pumpRouter(tester, router);
    Finder label(String text) => find.descendant(
      of: find.byKey(ManualProductDetailsForm.saveKey),
      matching: find.text(text),
    );

    await tester.tap(find.byKey(const Key('open_create')));
    await tester.pumpAndSettle();
    expect(label('Create'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_edit')));
    await tester.pumpAndSettle();
    expect(label('Done'), findsOneWidget);
    await tester.ensureVisible(find.byKey(ManualProductDetailsForm.saveKey));
    await tester.tap(find.byKey(ManualProductDetailsForm.saveKey));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('open_edit')), findsOneWidget);
    expect(results, [null, null]);
  });
}

Future<void> _pumpRouter(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(
          const _EmptyInventoryItemRepository(),
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        routerConfig: router,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
}

GoRouter _buildManualProductRouteTestRouter({
  required WidgetBuilder homeBuilder,
}) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => homeBuilder(context)),
      GoRoute(
        path: AppRoutes.productSearchChildFlow,
        pageBuilder: buildManualProductSearchRoutePage,
      ),
    ],
  );
}

InventoryItem _item() {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Milk',
    entryDate: DateTime.parse('2026-04-20T12:00:00Z'),
    storeName: 'Store',
    quantity: 1,
  );
}

class _EmptyInventoryItemRepository
    with InventoryItemWholeListWrites
    implements InventoryItemRecentManualReader {
  const new();

  @override
  bool get supportsLimitedRecentManualReads => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return const <InventoryItem>[];
  }

  @override
  Future<List<InventoryItem>> readRecentManualItems({
    required int limit,
  }) async {
    return const <InventoryItem>[];
  }

  @override
  Future<bool> replaceItems(List<InventoryItem> items) async {
    return true;
  }

  @override
  Stream<List<InventoryItem>> watchAll() {
    return Stream<List<InventoryItem>>.value(const <InventoryItem>[]);
  }
}
