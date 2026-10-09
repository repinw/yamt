import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_entry_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_pick_flow.dart';

InventoryReceiptManualProductResult _result() {
  return InventoryReceiptManualProductResult(
    item: InventoryItem.create(
      id: 'manual-item',
      name: 'Muesli',
      entryDate: DateTime.utc(2026, 4, 13),
      storeName: 'Manual',
      quantity: 1,
    ),
    action: InventoryReceiptManualProductAction.addToInventory,
    requiresGlobalPersistence: false,
  );
}

/// Runs [action] with a context from a pumped page.
Future<void> _run(
  WidgetTester tester,
  Future<void> Function(BuildContext context) action,
) async {
  late BuildContext pageContext;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          pageContext = context;
          return const SizedBox();
        },
      ),
    ),
  );
  await action(pageContext);
}

void main() {
  testWidgets('a picker closes the hub with the food and saves nothing', (
    tester,
  ) async {
    final result = _result();
    final closedWith = <Object?>[];
    final saving = <bool>[];
    InventoryReceiptManualProductResult? canceled;

    await _run(tester, (context) async {
      canceled = await completeProductSearchHubPick(
        context: context,
        args: ProductSearchHubRouteArgs.selection(item: _result().item),
        sourceKey: 'source',
        result: result,
        setSaving: saving.add,
        close: ([closeResult]) => closedWith.add(closeResult),
      );
    });

    expect(closedWith, [same(result)]);
    expect(saving, isEmpty);
    expect(canceled, isNull);
  });

  testWidgets('a created food is completed once when nothing is canceled', (
    tester,
  ) async {
    final completed = <String>[];

    await _run(tester, (context) async {
      await completeProductSearchHubCreatedEntry(
        context: context,
        args: ProductSearchHubRouteArgs.selection(item: _result().item),
        entry: ProductSearchHubEditedResult(
          sourceKey: 'created',
          result: _result(),
        ),
        complete: ({required sourceKey, required result}) async {
          completed.add(sourceKey);
          return null;
        },
      );
    });

    expect(completed, ['created']);
  });
}
