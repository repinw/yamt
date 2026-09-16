import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/data/receipt_gateway_providers.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';
import 'package:yamt/features/scanner/presentation/controllers/receipt_review_controller.dart';

import '../../fakes/fake_receipt_product_resolver.dart';
import '../../fakes/fake_receipt_storage_gateway.dart';

void main() {
  group('ReceiptReviewController', () {
    late FakeReceiptProductResolver fakeResolver;
    late FakeReceiptStorageGateway fakeGateway;

    const testMilchCandidate = ProductCandidate(
      id: 'prod-milch-1',
      name: 'Ja! Frische Vollmilch 3,8% 1L',
      brand: 'Ja!',
      barcode: '4311501234567',
      imageUrl: 'https://example.com/milch.jpg',
    );

    const testBrotCandidate = ProductCandidate(
      id: 'prod-brot-2',
      name: 'Harry Vollkornbrot 500g',
      brand: 'Harry',
      barcode: '4009876543210',
    );

    const initialItem1 = ReceiptLineItem(
      id: 'item-1',
      rawName: 'JA! VOLLM. 3.8% 1L',
      totalPrice: 1.19,
      status: ReceiptItemStatus.suggested,
      matchedProduct: testMilchCandidate,
    );

    const initialItem2 = ReceiptLineItem(
      id: 'item-2',
      rawName: 'UNBEKANNT',
      totalPrice: 2.50,
    );

    const initialItemPfand = ReceiptLineItem(
      id: 'item-pfand',
      rawName: 'PFAND 0,25',
      totalPrice: 0.25,
      isDeposit: true,
      status: ReceiptItemStatus.confirmed,
    );

    const baseReceipt = ScannedReceipt(
      id: 'receipt-123',
      storeName: 'Rewe',
      printedTotal: 3.94, // 1.19 + 2.50 + 0.25 = 3.94
      items: [initialItem1, initialItem2, initialItemPfand],
    );

    ProviderContainer createContainer({
      ScannedReceipt receipt = baseReceipt,
    }) {
      fakeResolver = FakeReceiptProductResolver();
      fakeGateway = FakeReceiptStorageGateway();

      final container = ProviderContainer(
        overrides: [
          receiptProductResolverProvider.overrideWithValue(fakeResolver),
          receiptStorageGatewayProvider.overrideWithValue(fakeGateway),
        ],
      );

      addTearDown(container.dispose);
      return container;
    }

    test('Initialer Zustand spiegelt den übergebenen Beleg wider', () {
      final container = createContainer();
      final controller = container.read(
        receiptReviewControllerProvider(baseReceipt).notifier,
      );

      expect(controller.state.receipt.id, 'receipt-123');
      expect(controller.state.receipt.items.length, 3);
      expect(controller.state.isSaving, isFalse);
      expect(controller.state.isResolving, isFalse);
      expect(controller.state.saveSuccess, isFalse);
      expect(controller.state.errorMessage, isNull);
    });

    test('updateStoreName und updateDateTime aktualisieren Kopfdaten', () {
      final container = createContainer();
      final controller = container.read(
        receiptReviewControllerProvider(baseReceipt).notifier,
      );

      final newDate = DateTime(2026, 9, 13, 10, 30);
      controller
        ..updateStoreName('Lidl')
        ..updateDateTime(newDate);

      expect(controller.state.receipt.storeName, 'Lidl');
      expect(controller.state.receipt.dateTime, newDate);
    });

    test('updateItem ersetzt Position vollständig', () {
      final container = createContainer();
      final controller = container.read(
        receiptReviewControllerProvider(baseReceipt).notifier,
      );

      final modifiedItem = initialItem1.copyWith(
        rawName: 'VOLLMILCH 3.8% KORRIGIERT',
        totalPrice: 1.09,
      );

      controller.updateItem(modifiedItem);

      expect(
        controller.state.receipt.items.first.rawName,
        'VOLLMILCH 3.8% KORRIGIERT',
      );
      expect(controller.state.receipt.items.first.totalPrice, 1.09);
    });

    test('updateQuantity passt Menge und Rechensumme an', () {
      final container = createContainer();
      final controller = container.read(
        receiptReviewControllerProvider(baseReceipt).notifier,
      )..updateQuantity('item-1', 3);

      final updatedItem = controller.state.receipt.items.first;
      expect(updatedItem.quantity, 3);
    });

    test('updatePrice passt Zeilenpreis an', () {
      final container = createContainer();
      final controller = container.read(
        receiptReviewControllerProvider(baseReceipt).notifier,
      )..updatePrice('item-1', 1.29);

      final updatedItem = controller.state.receipt.items.first;
      expect(updatedItem.totalPrice, 1.29);
      expect(controller.state.receipt.calculatedTotal, closeTo(4.04, 0.001));
    });

    test('selectCandidate bestätigt Artikel mit gewähltem Produkt', () {
      final container = createContainer();
      final controller = container.read(
        receiptReviewControllerProvider(baseReceipt).notifier,
      )..selectCandidate('item-2', testBrotCandidate);

      final item2 = controller.state.receipt.items[1];
      expect(item2.status, ReceiptItemStatus.confirmed);
      expect(item2.matchedProduct, testBrotCandidate);
      expect(item2.displayName, 'Harry Vollkornbrot 500g');
    });

    test('clearProduct setzt Position auf unmatched zurück', () {
      final container = createContainer();
      final controller = container.read(
        receiptReviewControllerProvider(baseReceipt).notifier,
      )..clearProduct('item-1');

      final item1 = controller.state.receipt.items.first;
      expect(item1.status, ReceiptItemStatus.unmatched);
      expect(item1.matchedProduct, isNull);
    });

    test('toggleIgnore ignoriert Artikel und stellt ihn wieder her', () {
      final container = createContainer();
      final controller = container.read(
        receiptReviewControllerProvider(baseReceipt).notifier,
      )..toggleIgnore('item-2');
      expect(
        controller.state.receipt.items[1].status,
        ReceiptItemStatus.ignored,
      );

      // Zweites Toggeln -> Wiederhergestellt (unmatched)
      controller.toggleIgnore('item-2');
      expect(
        controller.state.receipt.items[1].status,
        ReceiptItemStatus.unmatched,
      );
    });

    test('removeItem entfernt Position komplett', () {
      final container = createContainer();
      final controller = container.read(
        receiptReviewControllerProvider(baseReceipt).notifier,
      )..removeItem('item-pfand');

      expect(controller.state.receipt.items.length, 2);
      expect(
        controller.state.receipt.items.any((i) => i.id == 'item-pfand'),
        isFalse,
      );
    });

    test('addItem fügt vergessenen Artikel hinzu', () {
      final container = createContainer();
      final controller = container.read(
        receiptReviewControllerProvider(baseReceipt).notifier,
      );

      const newItem = ReceiptLineItem(
        id: 'new-item',
        rawName: 'APFEL',
        totalPrice: 0.99,
        status: ReceiptItemStatus.confirmed,
        matchedProduct: ProductCandidate(id: 'apfel', name: 'Apfel'),
      );

      controller.addItem(newItem);

      expect(controller.state.receipt.items.length, 4);
      expect(controller.state.receipt.calculatedTotal, closeTo(4.93, 0.001));
    });

    test('confirmAllSuggestions bestätigt alle vorgeschlagenen Positionen', () {
      final container = createContainer();
      final controller = container.read(
        receiptReviewControllerProvider(baseReceipt).notifier,
      );

      expect(
        controller.state.receipt.items[0].status,
        ReceiptItemStatus.suggested,
      );

      controller.confirmAllSuggestions();

      expect(
        controller.state.receipt.items[0].status,
        ReceiptItemStatus.confirmed,
      );
      expect(
        controller.state.receipt.items[1].status,
        ReceiptItemStatus.unmatched,
      );
    });

    test(
      'replaceWithBarcode ersetzt Artikel sauber bei bekanntem Barcode',
      () async {
        final container = createContainer();
        fakeResolver.registerProductForBarcode(
          '4009876543210',
          testBrotCandidate,
        );

        final controller = container.read(
          receiptReviewControllerProvider(baseReceipt).notifier,
        );

        final success = await controller.replaceWithBarcode(
          'item-2',
          '4009876543210',
        );

        expect(success, isTrue);
        final item2 = controller.state.receipt.items[1];
        expect(item2.status, ReceiptItemStatus.confirmed);
        expect(item2.matchedProduct?.name, 'Harry Vollkornbrot 500g');
        expect(item2.matchedProduct?.barcode, '4009876543210');
        expect(controller.state.isResolving, isFalse);
      },
    );

    test('replaceWithBarcode meldet Fehler bei unbekanntem Barcode', () async {
      final container = createContainer();
      final controller = container.read(
        receiptReviewControllerProvider(baseReceipt).notifier,
      );

      final success = await controller.replaceWithBarcode(
        'item-2',
        '9999999999999',
      );

      expect(success, isFalse);
      expect(controller.state.errorMessage, contains('Kein Produkt'));
      expect(controller.state.isResolving, isFalse);
      expect(
        controller.state.receipt.items[1].status,
        ReceiptItemStatus.unmatched,
      );
    });

    test(
      'saveReceipt blockiert, wenn noch offene Positionen existieren',
      () async {
        final container = createContainer();
        final controller = container.read(
          receiptReviewControllerProvider(baseReceipt).notifier,
        );

        // item-2 ist noch 'unmatched'
        final success = await controller.saveReceipt();

        expect(success, isFalse);
        expect(fakeGateway.savedReceipts, isEmpty);
        expect(controller.state.errorMessage, contains('Bitte alle offenen'));
      },
    );

    test(
      'saveReceipt delegiert die vollständige Speicherung an das Gateway',
      () async {
        final container = createContainer();
        final controller =
            container.read(
                receiptReviewControllerProvider(baseReceipt).notifier,
              )
              ..confirmAllSuggestions()
              ..toggleIgnore('item-2');

        // Jetzt ist der Beleg fertig geprüft (isReadyToSave == true)
        expect(controller.state.receipt.isReadyToSave, isTrue);

        final success = await controller.saveReceipt();

        expect(success, isTrue);
        expect(controller.state.saveSuccess, isTrue);
        expect(controller.state.isSaving, isFalse);

        // Gateway prüfen:
        expect(fakeGateway.savedReceipts.length, 1);
        final savedData = fakeGateway.savedReceipts.first;
        expect(savedData.receipt.id, 'receipt-123');

        // Nur item-1 darf gespeichert werden
        // (item-2 ignoriert, Pfand gefiltert).
        expect(savedData.items.length, 1);
        expect(savedData.items.first.id, 'item-1');

        // Aliases are persisted as part of the gateway's save transaction.
        expect(fakeGateway.learnedAliases, isEmpty);
      },
    );

    test('saveReceipt fängt Speicherfehler sauber ab', () async {
      final container = createContainer();
      fakeGateway.errorToThrowOnSave = Exception('Firestore offline');

      final controller =
          container.read(receiptReviewControllerProvider(baseReceipt).notifier)
            ..confirmAllSuggestions()
            ..toggleIgnore('item-2');

      final success = await controller.saveReceipt();

      expect(success, isFalse);
      expect(controller.state.saveSuccess, isFalse);
      expect(controller.state.isSaving, isFalse);
      expect(controller.state.errorMessage, contains('Firestore offline'));
    });
  });
}
