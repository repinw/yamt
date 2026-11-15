import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_stock_amount_flow.dart';
import 'package:yamt/features/inventory/presentation/inventory_stock_amount_page.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_stock_count.dart';
import 'package:yamt/features/inventory/presentation/widgets/stock_amount/'
    'stock_amount_inputs.dart';
import 'package:yamt/features/inventory/presentation/widgets/stock_amount/'
    'stock_amount_parts.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _openKey = ValueKey<String>('open');

InventoryItem _item({String weight = '', double? pieceWeight}) =>
    InventoryItem.create(
      id: 'item',
      name: 'Flour',
      entryDate: DateTime(2026, 11, 12),
      storeName: 'Store',
      quantity: 1,
      weight: weight,
      servingQuantity: pieceWeight,
      servingQuantityUnit: pieceWeight == null ? null : 'g',
    ).withDerivedAmount();

/// Opens the amount page the way the flow does; [counted] is what it popped.
class _Run {
  new(this.tester);

  final WidgetTester tester;
  InventoryStockCount? counted;
  bool closed = false;

  Future<void> open(
    InventoryItem item, {
    InventoryAmountUnit? lineUnit,
    int? need,
    int? pieceWeight,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            key: _openKey,
            onPressed: () async {
              counted = await countInventoryStockForRecipe(
                context,
                item: item,
                lineUnit: lineUnit,
                need: need,
                pieceWeight: pieceWeight,
              );
              closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(_openKey));
    await tester.pumpAndSettle();
  }

  Future<void> type(String text) async {
    await tester.enterText(find.byKey(StockAmountField.fieldKey), text);
    await tester.pump();
  }

  Future<void> apply() async {
    await tester.tap(find.byKey(InventoryStockAmountPage.applyKey));
    await tester.pumpAndSettle();
  }

  bool get canApply =>
      tester
          .widget<FilledButton>(find.byKey(InventoryStockAmountPage.applyKey))
          .onPressed !=
      null;

  String get typed => tester
      .widget<TextField>(find.byKey(StockAmountField.fieldKey))
      .controller!
      .text;
}

void main() {
  group('a food with a package size asks how much', () {
    testWidgets('the number starts at the pack and confirming returns it', (
      tester,
    ) async {
      final run = _Run(tester);
      await run.open(
        _item(weight: '500 g'),
        lineUnit: InventoryAmountUnit.gram,
        need: 200,
      );

      expect(run.typed, '500');
      expect(run.canApply, isTrue);
      await run.apply();

      expect(run.counted?.amount, 500);
      expect(run.counted?.item.initialAmount, 500);
    });

    testWidgets('the quick choices set the number', (tester) async {
      final run = _Run(tester);
      await run.open(_item(weight: '500 g'));

      await tester.tap(find.byKey(StockAmountChoices.choiceKey(250)));
      await tester.pump();
      expect(run.typed, '250');

      await tester.tap(find.byKey(StockAmountChoices.choiceKey(1000)));
      await tester.pump();
      expect(run.typed, '1000');
      await run.apply();

      expect(run.counted?.amount, 1000);
    });

    testWidgets('a typed amount is returned', (tester) async {
      final run = _Run(tester);
      await run.open(_item(weight: '500 g'));

      await run.type('320');
      await run.apply();

      expect(run.counted?.amount, 320);
    });

    testWidgets('empty or zero cannot be confirmed', (tester) async {
      final run = _Run(tester);
      await run.open(_item(weight: '500 g'));

      await run.type('');
      expect(run.canApply, isFalse);
      await run.type('0');
      expect(run.canApply, isFalse);
      await run.type('12');
      expect(run.canApply, isTrue);
    });

    testWidgets('the line says what the recipe takes and leaves', (
      tester,
    ) async {
      final run = _Run(tester);
      await run.open(
        _item(weight: '500 g'),
        lineUnit: InventoryAmountUnit.gram,
        need: 200,
      );

      expect(find.byKey(StockAmountNeedLine.lineKey), findsOneWidget);
      final text = tester
          .widget<Text>(find.byKey(StockAmountNeedLine.lineKey))
          .data;
      expect(text, contains('200'));
      expect(text, contains('300'));

      await run.type('150');
      expect(
        tester.widget<Text>(find.byKey(StockAmountNeedLine.lineKey)).data,
        contains('50'),
      );
    });

    testWidgets('closing the page returns nothing', (tester) async {
      final run = _Run(tester);
      await run.open(_item(weight: '500 g'));

      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();

      expect(run.closed, isTrue);
      expect(run.counted, isNull);
    });
  });

  group('a food without a package size asks for the pack weight', () {
    testWidgets('the number starts empty and cannot be confirmed', (
      tester,
    ) async {
      final run = _Run(tester);
      await run.open(_item(), lineUnit: InventoryAmountUnit.gram, need: 250);

      expect(run.typed, isEmpty);
      expect(run.canApply, isFalse);
    });

    testWidgets('the typed weight becomes one pack of the item', (
      tester,
    ) async {
      final run = _Run(tester);
      await run.open(_item(), lineUnit: InventoryAmountUnit.gram, need: 250);

      await run.type('750');
      await run.apply();

      expect(run.counted?.amount, 750);
      expect(run.counted?.item.amountUnit, InventoryAmountUnit.gram);
      expect(run.counted?.item.initialAmount, 750);
    });

    testWidgets('a line in ml asks in ml', (tester) async {
      final run = _Run(tester);
      await run.open(
        _item(),
        lineUnit: InventoryAmountUnit.milliliter,
        need: 200,
      );

      await tester.tap(find.byKey(StockAmountChoices.choiceKey(500)));
      await tester.pump();
      await run.apply();

      expect(run.counted?.amount, 500);
      expect(run.counted?.item.amountUnit, InventoryAmountUnit.milliliter);
    });
  });

  group('pieces ask how many', () {
    testWidgets('the count starts where the recipe is', (tester) async {
      final run = _Run(tester);
      await run.open(_item(), lineUnit: InventoryAmountUnit.piece, need: 3);

      expect(find.byKey(StockAmountField.fieldKey), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(StockAmountCountRow.countKey)).data,
        contains('3'),
      );
      await run.apply();

      expect(run.counted?.amount, 3 * inventoryPieceAmountScale);
      expect(run.counted?.item.amountUnit, InventoryAmountUnit.piece);
    });

    testWidgets('plus and minus change the count, never below one', (
      tester,
    ) async {
      final run = _Run(tester);
      await run.open(_item(), lineUnit: InventoryAmountUnit.piece, need: 1);

      await tester.tap(find.byKey(StockAmountCountRow.moreKey));
      await tester.pump();
      await tester.tap(find.byKey(StockAmountCountRow.moreKey));
      await tester.pump();
      await tester.tap(find.byKey(StockAmountCountRow.lessKey));
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(StockAmountCountRow.countKey)).data,
        contains('2'),
      );

      await tester.tap(find.byKey(StockAmountCountRow.lessKey));
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(find.byKey(StockAmountCountRow.lessKey))
            .onPressed,
        isNull,
      );
      await run.apply();

      expect(run.counted?.amount, inventoryPieceAmountScale);
    });

    testWidgets('a piece weight that was asked is written to the item', (
      tester,
    ) async {
      final run = _Run(tester);
      await run.open(
        _item(),
        lineUnit: InventoryAmountUnit.piece,
        need: 2,
        pieceWeight: 60,
      );

      final field = find.byKey(StockAmountPieceWeight.fieldKey);
      expect(
        tester.widget<TextField>(field).controller?.text,
        '60',
        reason: 'starts with the weight the recipe names',
      );
      await tester.enterText(field, '55');
      await tester.pump();
      await run.apply();

      expect(run.counted?.item.servingQuantity, 55);
      expect(run.counted?.item.servingQuantityUnit, 'g');
    });

    testWidgets('a food that knows its piece weight does not ask for it', (
      tester,
    ) async {
      final run = _Run(tester);
      await run.open(
        _item(weight: '6 Stück', pieceWeight: 60),
        lineUnit: InventoryAmountUnit.piece,
        need: 2,
      );

      expect(find.byKey(StockAmountPieceWeight.fieldKey), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(StockAmountCountRow.countKey)).data,
        contains('6'),
      );
    });

    testWidgets('a pack of pieces without a weight asks for the pack weight '
        'when the line weighs', (tester) async {
      final run = _Run(tester);
      await run.open(
        _item(weight: '6 Stück'),
        lineUnit: InventoryAmountUnit.gram,
        need: 100,
      );

      expect(find.byKey(StockAmountField.fieldKey), findsOneWidget);
      expect(find.byKey(StockAmountCountRow.countKey), findsNothing);
    });
  });
}
