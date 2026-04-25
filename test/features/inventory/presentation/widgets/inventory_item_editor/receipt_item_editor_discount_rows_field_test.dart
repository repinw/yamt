import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_item_editor/receipt_item_editor_discount_rows_field.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _wrap({
  required List<MapEntry<String, String>> initialEntries,
  required ValueChanged<List<MapEntry<String, String>>> onChanged,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ReceiptEditorDiscountRowsField(
        initialEntries: initialEntries,
        onChanged: onChanged,
        errorText: null,
        onSubmit: () {},
      ),
    ),
  );
}

void main() {
  testWidgets('renders all initial discount rows', (tester) async {
    await tester.pumpWidget(
      _wrap(
        initialEntries: const <MapEntry<String, String>>[
          MapEntry<String, String>('Coupon', '-1.20'),
          MapEntry<String, String>('Loyalty', '-0.50'),
        ],
        onChanged: (_) {},
      ),
    );

    expect(
      find.byKey(const Key('receipt_review_discount_name_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('receipt_review_discount_name_1')),
      findsOneWidget,
    );

    final nameField0 = tester.widget<TextField>(
      find.byKey(const Key('receipt_review_discount_name_0')),
    );
    final amountField0 = tester.widget<TextField>(
      find.byKey(const Key('receipt_review_discount_amount_0')),
    );
    final nameField1 = tester.widget<TextField>(
      find.byKey(const Key('receipt_review_discount_name_1')),
    );
    final amountField1 = tester.widget<TextField>(
      find.byKey(const Key('receipt_review_discount_amount_1')),
    );

    expect(nameField0.controller?.text, 'Coupon');
    expect(amountField0.controller?.text, '-1.20');
    expect(nameField1.controller?.text, 'Loyalty');
    expect(amountField1.controller?.text, '-0.50');
  });

  testWidgets('add button appends a new empty row', (tester) async {
    List<MapEntry<String, String>>? latestChanged;

    await tester.pumpWidget(
      _wrap(
        initialEntries: const <MapEntry<String, String>>[
          MapEntry<String, String>('Coupon', '-1.20'),
        ],
        onChanged: (entries) {
          latestChanged = entries;
        },
      ),
    );

    await tester.tap(
      find.byKey(const Key('receipt_review_discount_add_button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('receipt_review_discount_name_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('receipt_review_discount_amount_1')),
      findsOneWidget,
    );
    expect(latestChanged, isNotNull);
    expect(latestChanged, hasLength(2));
    expect(latestChanged?[1].key, '');
    expect(latestChanged?[1].value, '');
  });

  testWidgets('remove button deletes the selected row only', (tester) async {
    List<MapEntry<String, String>>? latestChanged;

    await tester.pumpWidget(
      _wrap(
        initialEntries: const <MapEntry<String, String>>[
          MapEntry<String, String>('Coupon', '-1.20'),
          MapEntry<String, String>('Loyalty', '-0.50'),
        ],
        onChanged: (entries) {
          latestChanged = entries;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_discount_remove_0')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('receipt_review_discount_name_0')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('receipt_review_discount_name_1')),
      findsOneWidget,
    );
    expect(latestChanged, isNotNull);
    expect(latestChanged, hasLength(1));
    expect(latestChanged?.single.key, 'Loyalty');
    expect(latestChanged?.single.value, '-0.50');
  });

  testWidgets('text input changes fire onChanged with current entries', (
    tester,
  ) async {
    List<MapEntry<String, String>>? latestChanged;

    await tester.pumpWidget(
      _wrap(
        initialEntries: const <MapEntry<String, String>>[],
        onChanged: (entries) {
          latestChanged = entries;
        },
      ),
    );

    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_name_0')),
      'Coupon',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_amount_0')),
      '-1.25',
    );
    await tester.pumpAndSettle();

    expect(latestChanged, isNotNull);
    expect(latestChanged, hasLength(1));
    expect(latestChanged?.single.key, 'Coupon');
    expect(latestChanged?.single.value, '-1.25');
  });

  testWidgets('remove button is disabled when only one row remains', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        initialEntries: const <MapEntry<String, String>>[],
        onChanged: (_) {},
      ),
    );

    final removeButton = tester.widget<IconButton>(
      find.byKey(const Key('receipt_review_discount_remove_0')),
    );

    expect(removeButton.onPressed, isNull);
  });
}
