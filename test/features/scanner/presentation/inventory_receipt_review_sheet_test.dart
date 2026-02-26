import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:yamt/features/inventory/domain/fridge_item.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_review_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

FridgeItem _item({
  required String id,
  required bool isDeposit,
  required bool isDiscount,
  String? name,
  DateTime? receiptDate,
  String storeName = 'Store',
  String? brand,
  int quantity = 1,
  double unitPrice = 1.0,
  Map<String, double> discounts = const <String, double>{},
}) {
  return FridgeItem(
    id: id,
    name: name ?? 'Item $id',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: storeName,
    quantity: quantity,
    unitPrice: unitPrice,
    brand: brand,
    discounts: discounts,
    isDeposit: isDeposit,
    isDiscount: isDiscount,
    receiptDate: receiptDate,
  );
}

Widget _wrap({
  required List<FridgeItem> items,
  required VoidCallback onCancelTap,
  required Future<void> Function(List<FridgeItem> items) onSaveTap,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: InventoryReceiptReviewSheet(
        items: items,
        onCancelTap: onCancelTap,
        onSaveTap: onSaveTap,
      ),
    ),
  );
}

void main() {
  testWidgets('price overview shows total, savable and excluded sums', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
          _item(id: 'deposit', isDeposit: true, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    expect(find.text('Price overview'), findsOneWidget);
    expect(find.text('Total receipt'), findsOneWidget);
    expect(find.text('Saved to inventory'), findsOneWidget);
    expect(find.text('Excluded lines'), findsOneWidget);
  });

  testWidgets('item preview shows line price instead of store/date', (
    tester,
  ) async {
    final receiptDate = DateTime.parse('2026-01-05');
    const quantity = 3;
    const unitPrice = 1.5;

    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            quantity: quantity,
            unitPrice: unitPrice,
            receiptDate: receiptDate,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final currency = NumberFormat.currency(locale: locale, symbol: '€');
    final expectedPrice = currency.format(quantity * unitPrice);
    final expectedSubtitle = '${quantity}x · $expectedPrice';

    expect(find.text(expectedSubtitle), findsOneWidget);
  });

  testWidgets('receipt metadata is shown above price overview', (tester) async {
    final receiptDate = DateTime.parse('2026-01-05');
    const storeName = 'My Store';

    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            storeName: storeName,
            receiptDate: receiptDate,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final expectedDate = DateFormat.yMMMd(locale).format(receiptDate);

    final storeFinder = find.text(storeName);
    final dateFinder = find.text(expectedDate);
    final priceTitleFinder = find.text('Price overview');

    expect(storeFinder, findsOneWidget);
    expect(dateFinder, findsOneWidget);
    expect(priceTitleFinder, findsOneWidget);

    final metadataY = tester.getTopLeft(storeFinder).dy;
    final priceOverviewY = tester.getTopLeft(priceTitleFinder).dy;
    expect(metadataY, lessThan(priceOverviewY));
  });

  testWidgets(
    'edited item keeps receipt date and hides store/date editor fields',
    (tester) async {
      List<FridgeItem>? savedItems;
      final receiptDate = DateTime.parse('2026-01-05');

      await tester.pumpWidget(
        _wrap(
          items: <FridgeItem>[
            _item(
              id: 'food',
              isDeposit: false,
              isDiscount: false,
              receiptDate: receiptDate,
            ),
          ],
          onCancelTap: () {},
          onSaveTap: (items) async {
            savedItems = items;
          },
        ),
      );

      await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('receipt_review_field_name')),
        'Edited item',
      );
      await tester.pumpAndSettle();

      final storeField = find.byKey(
        const Key('receipt_review_field_store_name'),
      );
      expect(storeField, findsNothing);
      expect(
        find.byKey(const Key('receipt_review_clear_receipt_date_button')),
        findsNothing,
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(InventoryReceiptReviewSheet)),
      )!;
      expect(
        find.text(l10n.inventoryReceiptReviewSelectDateAction),
        findsNothing,
      );

      final applyButton = find.byKey(
        const Key('receipt_review_apply_item_button'),
      );
      await tester.ensureVisible(applyButton);
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const Key('receipt_review_save_button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(savedItems, isNotNull);
      expect(savedItems, hasLength(1));
      expect(savedItems!.single.name, 'Edited item');
      expect(savedItems!.single.receiptDate, receiptDate);
    },
  );

  testWidgets('save action is disabled when all items are review-only', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(id: 'deposit', isDeposit: true, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('receipt_review_save_button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('invalid item number input shows inline validation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_quantity')),
      'abc',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter valid numbers.'), findsNWidgets(2));
  });

  testWidgets('correcting number input clears inline validation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    final quantityField = find.byKey(
      const Key('receipt_review_field_quantity'),
    );
    await tester.enterText(quantityField, 'abc');
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter valid numbers.'), findsNWidgets(2));

    await tester.enterText(quantityField, '2');
    await tester.pumpAndSettle();

    expect(find.text('Please enter valid numbers.'), findsNothing);
  });

  testWidgets('changing quantity revalidates weight error immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_quantity')),
      'abc',
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_weight')),
      '500',
    );
    await tester.pumpAndSettle();

    expect(find.text('Please add a unit (e.g. g or ml).'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_quantity')),
      '2',
    );
    await tester.pumpAndSettle();

    expect(find.text('Please add a unit (e.g. g or ml).'), findsOneWidget);
  });

  testWidgets('clearing prefilled brand persists as null', (tester) async {
    List<FridgeItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            brand: 'House Brand',
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    final brandField = find.byKey(const Key('receipt_review_field_brand'));
    await tester.ensureVisible(brandField);
    await tester.enterText(brandField, '');
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    final saveButton = find.byKey(const Key('receipt_review_save_button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(1));
    expect(savedItems!.single.brand, isNull);
  });

  testWidgets('editor hides keyboard when tapping outside text field', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    final nameField = find.byKey(const Key('receipt_review_field_name'));
    await tester.showKeyboard(nameField);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    final l10n = AppLocalizations.of(tester.element(nameField))!;
    await tester.tap(find.text(l10n.inventoryReceiptReviewEditTitle));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);
    expect(
      find.byKey(const Key('receipt_review_apply_item_button')),
      findsOneWidget,
    );
  });

  testWidgets('editor submits on keyboard done action', (tester) async {
    List<FridgeItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    final nameField = find.byKey(const Key('receipt_review_field_name'));
    await tester.enterText(nameField, 'Submitted from keyboard');
    await tester.pump();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('receipt_review_field_name')), findsNothing);

    final saveButton = find.byKey(const Key('receipt_review_save_button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(1));
    expect(savedItems!.single.name, 'Submitted from keyboard');
  });

  testWidgets('weight without unit shows inline validation', (tester) async {
    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_weight')),
      '500',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('Please add a unit (e.g. g or ml).'), findsOneWidget);
  });

  testWidgets('invalid discounts input shows inline validation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_name_0')),
      'coupon',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_amount_0')),
      'abc',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('Use JSON or key=value pairs.'), findsOneWidget);
  });

  testWidgets('discount lines merge into previous item and remain visible', (
    tester,
  ) async {
    List<FridgeItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
          _item(
            id: 'discount',
            name: 'Coupon',
            isDeposit: false,
            isDiscount: true,
            unitPrice: -1.20,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    expect(
      find.byKey(const Key('receipt_review_edit_button_0')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('receipt_review_edit_button_1')), findsNothing);
    expect(
      find.byKey(const Key('receipt_review_discount_row_0_0')),
      findsOneWidget,
    );
    expect(find.textContaining('Coupon'), findsOneWidget);

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(1));
    expect(savedItems!.single.discounts['Coupon'], -1.20);
  });

  testWidgets('rabatt row without isDiscount flag merges into previous item', (
    tester,
  ) async {
    List<FridgeItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(
            id: 'mandarine',
            name: 'Mandarinen',
            isDeposit: false,
            isDiscount: false,
            unitPrice: 2.00,
          ),
          _item(
            id: 'gurke',
            name: 'Gurken',
            isDeposit: false,
            isDiscount: false,
            unitPrice: 1.50,
          ),
          _item(
            id: 'rabatt',
            name: 'Rabatt',
            isDeposit: false,
            isDiscount: false,
            unitPrice: -0.50,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    expect(
      find.byKey(const Key('receipt_review_edit_button_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('receipt_review_edit_button_1')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('receipt_review_edit_button_2')), findsNothing);
    expect(
      find.byKey(const Key('receipt_review_discount_row_1_0')),
      findsOneWidget,
    );
    expect(find.textContaining('Rabatt'), findsOneWidget);

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(2));
    expect(savedItems![1].discounts['Rabatt'], -0.50);
  });

  testWidgets('rabatt row merges even when mapped as deposit', (tester) async {
    List<FridgeItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(
            id: 'mandarine',
            name: 'Mandarinen',
            isDeposit: false,
            isDiscount: false,
            unitPrice: 2.00,
          ),
          _item(
            id: 'gurke',
            name: 'Gurken',
            isDeposit: false,
            isDiscount: false,
            unitPrice: 1.50,
          ),
          _item(
            id: 'rabatt',
            name: 'Rabatt',
            isDeposit: true,
            isDiscount: false,
            unitPrice: -0.50,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    expect(
      find.byKey(const Key('receipt_review_discount_row_1_0')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(2));
    expect(savedItems![1].discounts['Rabatt'], -0.50);
  });

  testWidgets('leergut row does not merge into previous item discount list', (
    tester,
  ) async {
    List<FridgeItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(
            id: 'mandarine',
            name: 'Mandarinen',
            isDeposit: false,
            isDiscount: false,
            unitPrice: 2.00,
          ),
          _item(
            id: 'gurke',
            name: 'Gurken',
            isDeposit: false,
            isDiscount: false,
            unitPrice: 1.50,
          ),
          _item(
            id: 'leergut',
            name: 'Leergut',
            isDeposit: false,
            isDiscount: false,
            unitPrice: -0.50,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    expect(
      find.byKey(const Key('receipt_review_discount_row_1_0')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(3));
    expect(savedItems![1].discounts, isEmpty);
    expect(savedItems![2].isDeposit, isTrue);
    expect(savedItems![2].isDiscount, isFalse);
  });

  testWidgets('added discount entries appear as gray rows below item', (
    tester,
  ) async {
    List<FridgeItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_name_0')),
      'Loyalty',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_amount_0')),
      '-0.50',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('receipt_review_discount_row_0_0')),
      findsOneWidget,
    );
    expect(find.textContaining('Loyalty'), findsOneWidget);

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems!.single.discounts, <String, double>{'Loyalty': -0.5});
  });

  testWidgets('positive discount input is normalized to negative amount', (
    tester,
  ) async {
    List<FridgeItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_name_0')),
      'Coupon',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_amount_0')),
      '1.50',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems!.single.discounts['Coupon'], -1.5);
  });

  testWidgets('clearing discount in editor removes discount row from list', (
    tester,
  ) async {
    List<FridgeItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(
            id: 'gurke',
            name: 'Gurken',
            isDeposit: false,
            isDiscount: false,
            discounts: const <String, double>{'Rabatt': -0.50},
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    expect(
      find.byKey(const Key('receipt_review_discount_row_0_0')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_name_0')),
      '',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_amount_0')),
      '',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('receipt_review_discount_row_0_0')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems!.single.discounts, isEmpty);
  });

  testWidgets(
    'added discount on first item is rendered between first and second',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          items: <FridgeItem>[
            _item(
              id: 'mandarine',
              name: 'Mandarinen',
              isDeposit: false,
              isDiscount: false,
            ),
            _item(
              id: 'gurke',
              name: 'Gurken',
              isDeposit: false,
              isDiscount: false,
            ),
          ],
          onCancelTap: () {},
          onSaveTap: (_) async {},
        ),
      );

      await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('receipt_review_discount_name_0')),
        'Coupon',
      );
      await tester.enterText(
        find.byKey(const Key('receipt_review_discount_amount_0')),
        '-0.50',
      );
      await tester.pumpAndSettle();

      final applyButton = find.byKey(
        const Key('receipt_review_apply_item_button'),
      );
      await tester.ensureVisible(applyButton);
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      final discountRow = find.byKey(
        const Key('receipt_review_discount_row_0_0'),
      );
      expect(discountRow, findsOneWidget);

      final firstItemY = tester.getTopLeft(find.text('Mandarinen')).dy;
      final discountRowY = tester.getTopLeft(discountRow).dy;
      final secondItemY = tester.getTopLeft(find.text('Gurken')).dy;
      expect(firstItemY, lessThan(discountRowY));
      expect(discountRowY, lessThan(secondItemY));
    },
  );

  testWidgets('weight without suffix saves when gram fallback is selected', (
    tester,
  ) async {
    List<FridgeItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <FridgeItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_weight')),
      '500',
    );
    await tester.pumpAndSettle();

    final unitDropdown = find.byKey(
      const Key('receipt_review_field_weight_unit_fallback'),
    );
    await tester.ensureVisible(unitDropdown);
    await tester.tap(unitDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gram (g)').last);
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('Please add a unit (e.g. g or ml).'), findsNothing);

    final saveButton = find.byKey(const Key('receipt_review_save_button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(1));
    expect(savedItems!.single.initialAmount, 500);
    expect(savedItems!.single.currentAmount, 500);
    expect(savedItems!.single.amountUnit, FridgeAmountUnit.gram);
  });
}
