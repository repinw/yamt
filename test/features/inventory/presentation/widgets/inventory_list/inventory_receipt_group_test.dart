import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_group.dart';
import 'package:yamt/l10n/app_localizations_en.dart';

InventoryItem _item(
  String id, {
  required String store,
  String? receiptId,
  DateTime? receiptDate,
  String name = 'Milk',
  int quantity = 1,
  double unitPrice = 1.0,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-02-20T08:00:00Z'),
    storeName: store,
    quantity: quantity,
    initialQuantity: quantity,
    unitPrice: unitPrice,
    receiptId: receiptId,
    receiptDate: receiptDate,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  test('groups receipt items by receipt id and fallback store key', () {
    final groups = groupInventoryItemsByReceipt(<InventoryItem>[
      _item('a', store: 'Kaufland', receiptId: 'r-1'),
      _item('b', store: 'Aldi', receiptId: 'r-1'),
      _item('c', store: 'Rewe'),
      _item('d', store: 'rewe'),
    ]);

    expect(groups, hasLength(2));
    expect(groups.first.receiptId, 'r-1');
    expect(groups.first.items, hasLength(2));
    expect(groups.last.hasReceipt, isFalse);
    expect(groups.last.items, hasLength(2));
  });

  test(
    'sorts receipt groups before non-receipt and by newest receipt date',
    () {
      final groups = groupInventoryItemsByReceipt(<InventoryItem>[
        _item(
          'a',
          store: 'Store A',
          receiptId: 'old',
          receiptDate: DateTime.parse('2026-02-10T10:00:00Z'),
        ),
        _item(
          'b',
          store: 'Store B',
          receiptId: 'new',
          receiptDate: DateTime.parse('2026-02-15T10:00:00Z'),
        ),
        _item('c', store: 'Store C'),
      ]);

      expect(groups.map((group) => group.receiptId).toList(), <String?>[
        'new',
        'old',
        null,
      ]);
    },
  );

  test('title prefers receipt date and subtitle formats store/count/total', () {
    final l10n = AppLocalizationsEn();
    final dateFormat = DateFormat.yMMMd('en');
    final currency = NumberFormat.currency(locale: 'en', symbol: '€');
    final groups = groupInventoryItemsByReceipt(<InventoryItem>[
      _item(
        'a',
        store: 'Kaufland',
        receiptId: 'abc123456',
        receiptDate: DateTime.parse('2026-02-11T10:00:00Z'),
        quantity: 2,
        unitPrice: 1.5,
      ),
      _item(
        'b',
        store: 'Kaufland',
        receiptId: 'abc123456',
        receiptDate: DateTime.parse('2026-02-11T10:00:00Z'),
        quantity: 1,
        unitPrice: 2.0,
      ),
    ]);

    final group = groups.single;
    final title = group.title(l10n: l10n, dateFormat: dateFormat);
    final subtitle = group.subtitle(l10n: l10n, currency: currency);

    expect(title, 'Receipt Feb 11, 2026');
    expect(subtitle, contains('Kaufland'));
    expect(subtitle, contains('2 items'));
    expect(subtitle, contains('€5.00'));
  });

  test('title falls back to shortened receipt id without receipt date', () {
    final l10n = AppLocalizationsEn();
    final dateFormat = DateFormat.yMMMd('en');
    final groups = groupInventoryItemsByReceipt(<InventoryItem>[
      _item('a', store: 'Store', receiptId: 'abc123999'),
    ]);

    final title = groups.single.title(l10n: l10n, dateFormat: dateFormat);
    expect(title, 'Receipt #abc123');
  });
}
