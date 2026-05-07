import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_manual_add_product_page.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('renders launcher product page', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryItemRepositoryProvider.overrideWithValue(
            const _EmptyInventoryItemRepository(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: InventoryManualAddProductPage(
            item: _item(),
            initialIntent: InventoryReceiptManualProductInitialIntent.launcher,
            onSaved: (_) async {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const Key('receipt_review_manual_launcher_search_field')),
      findsOneWidget,
    );
  });
}

InventoryItem _item() {
  return InventoryItem.create(
    id: 'item-1',
    name: '',
    entryDate: DateTime.parse('2026-04-13T10:00:00Z'),
    storeName: 'Added manually',
    quantity: 1,
    origin: InventoryItemOrigin.manualAdd,
  );
}

class _EmptyInventoryItemRepository implements InventoryItemRepository {
  const _EmptyInventoryItemRepository();

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return const <InventoryItem>[];
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Stream<List<InventoryItem>> watchAll() {
    return Stream<List<InventoryItem>>.value(const <InventoryItem>[]);
  }
}
