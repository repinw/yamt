import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';

void main() {
  group('ProductCandidate & ReceiptLineItem (Freezed)', () {
    const productFrischkaese = ProductCandidate(
      id: 'prod-frischkaese-1',
      name: 'Bresso Frischkäse 150g',
      brand: 'Bresso',
      category: 'Käse & Milchprodukte',
      barcode: '4001234567890',
      imageUrl: 'https://example.com/frischkaese.jpg',
      packageSize: '150g',
      confidence: 0.95,
      nutrition: GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Fat: 22,
      ),
    );

    const productMilch = ProductCandidate(
      id: 'prod-milch-2',
      name: 'Ja! Frische Vollmilch 3,8% 1L',
      brand: 'Ja!',
      category: 'Milch',
      barcode: '4311501234567',
      imageUrl: 'https://example.com/milch.jpg',
      packageSize: '1l',
      source: CandidateSource.barcode,
      nutrition: GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Fat: 3.8,
      ),
    );

    test('Nährwerte folgen der deutschen Reihenfolge Fett, KH, Protein', () {
      const product = ProductCandidate(
        id: 'nutrition-order',
        name: 'Testprodukt',
        nutrition: GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.verified,
          per100Kcal: 46,
          per100Fat: 1.4,
          per100Carbs: 6.8,
          per100Protein: 0.8,
        ),
      );

      expect(product.formattedMacros, '46 kcal · F: 1.4g · KH: 6.8g · P: 0.8g');
    });

    test('Initial line item is unmatched by default', () {
      const item = ReceiptLineItem(
        id: 'line-1',
        rawName: 'JA! VOLLM. 3.8% 1L',
        totalPrice: 1.19,
        rawCategory: 'Molkereiprodukte',
      );

      expect(item.status, ReceiptItemStatus.unmatched);
      expect(item.matchedProduct, isNull);
      expect(item.displayName, 'JA! VOLLM. 3.8% 1L');
      expect(item.shouldPersist, isFalse);
      expect(item.effectivePrice, 1.19);
      expect(item.rawCategory, 'Molkereiprodukte');
    });

    test('Rabatt reduziert den effektiven Preis korrekt', () {
      const discountedItem = ReceiptLineItem(
        id: 'line-rabatt',
        rawName: 'GOUDA JUNG 400G',
        totalPrice: 2.49,
        discount: 0.50, // 50 Cent Rabatt
        status: ReceiptItemStatus.confirmed,
        matchedProduct: ProductCandidate(id: 'gouda', name: 'Gouda Jung'),
      );

      expect(discountedItem.totalPrice, 2.49);
      expect(discountedItem.discount, 0.50);
      expect(discountedItem.effectivePrice, closeTo(1.99, 0.001));
      expect(discountedItem.lineSavings, closeTo(0.50, 0.001));
      expect(discountedItem.shouldPersist, isTrue);
    });

    test('Reine Rabattzeile zieht Betrag ab und wird nicht gespeichert', () {
      const discountCoupon = ReceiptLineItem(
        id: 'line-coupon',
        rawName: 'LIDL PLUS GUTSCHEIN',
        totalPrice: 5,
        isDiscount: true,
        status: ReceiptItemStatus.confirmed,
      );

      expect(discountCoupon.isDiscount, isTrue);
      expect(discountCoupon.effectivePrice, -5.0);
      expect(discountCoupon.lineSavings, 5.0);
      expect(discountCoupon.shouldPersist, isFalse);
    });

    test('REGRESSION: Barcode-Korrektur ersetzt Artikel sauber '
        'ohne Datenleck', () {
      const originalItem = ReceiptLineItem(
        id: 'line-1',
        rawName: 'JA! VOLLM. 3.8% 1L',
        totalPrice: 1.19,
        status: ReceiptItemStatus.suggested,
        matchedProduct: productFrischkaese,
      );

      expect(originalItem.matchedProduct?.name, 'Bresso Frischkäse 150g');

      final updatedItem = originalItem.withSelectedProduct(productMilch);

      expect(updatedItem.id, 'line-1');
      expect(updatedItem.rawName, 'JA! VOLLM. 3.8% 1L');
      expect(updatedItem.totalPrice, 1.19);
      expect(updatedItem.status, ReceiptItemStatus.confirmed);
      expect(updatedItem.shouldPersist, isTrue);

      final product = updatedItem.matchedProduct!;
      expect(product.id, 'prod-milch-2');
      expect(product.name, 'Ja! Frische Vollmilch 3,8% 1L');
      expect(product.barcode, '4311501234567');
      expect(product.imageUrl, 'https://example.com/milch.jpg');
      expect(product.source, CandidateSource.barcode);

      expect(originalItem.matchedProduct?.name, 'Bresso Frischkäse 150g');
    });

    test('Pfandzeilen werden korrekt als nicht speicherbar erkannt', () {
      const depositItem = ReceiptLineItem(
        id: 'line-deposit',
        rawName: 'PFAND 0,25 EUR',
        totalPrice: 0.25,
        isDeposit: true,
        status: ReceiptItemStatus.confirmed,
        matchedProduct: ProductCandidate(id: 'deposit-id', name: 'Einwegpfand'),
      );

      expect(depositItem.shouldPersist, isFalse);
    });
  });

  group('ScannedReceipt calculations, Rabatte & Pfand', () {
    const itemNormal = ReceiptLineItem(
      id: '1',
      rawName: 'MILCH',
      totalPrice: 1.19,
      status: ReceiptItemStatus.confirmed,
      matchedProduct: ProductCandidate(id: 'm1', name: 'Milch'),
    );

    const itemRabatt = ReceiptLineItem(
      id: '2',
      rawName: 'BROT',
      totalPrice: 2.50,
      discount: 0.50, // 2.50 - 0.50 = 2.00
      status: ReceiptItemStatus.suggested,
      matchedProduct: ProductCandidate(id: 'b1', name: 'Brot'),
    );

    const itemDeposit = ReceiptLineItem(
      id: 'deposit',
      rawName: 'PFAND 0,25',
      totalPrice: 0.25,
      isDeposit: true,
      status: ReceiptItemStatus.confirmed,
    );

    const itemCoupon = ReceiptLineItem(
      id: 'coupon',
      rawName: 'WARENGUTSCHEIN',
      totalPrice: 1,
      isDiscount: true,
      status: ReceiptItemStatus.confirmed,
    );

    test('Calculated total, totalSavings und totalDeposit stimmen', () {
      const receipt = ScannedReceipt(
        id: 'receipt-1',
        sourceFilePaths: ['/path/to/part1.jpg', '/path/to/part2.jpg'],
        sourceMimeType: 'image/jpeg',
        confidenceScore: 0.98,
        rawText: 'LIDL FILIALE BERLIN\nMILCH 1.19\nBROT 2.50\nSUMME 3.69',
        printedTotal: 2.44, // 1.19 + 2.00 + 0.25 - 1.00 = 2.44
        items: [itemNormal, itemRabatt, itemDeposit, itemCoupon],
      );

      expect(receipt.sourceFilePaths.length, 2);
      expect(receipt.primarySourceFilePath, '/path/to/part1.jpg');
      expect(receipt.confidenceScore, 0.98);
      expect(
        receipt.rawText,
        'LIDL FILIALE BERLIN\nMILCH 1.19\nBROT 2.50\nSUMME 3.69',
      );
      expect(receipt.calculatedTotal, closeTo(2.44, 0.001));
      expect(receipt.hasDiscrepancy, isFalse);
      expect(receipt.totalSavings, closeTo(1.50, 0.001)); // 0.50 + 1.00
      expect(receipt.totalDeposit, closeTo(0.25, 0.001));

      // savableItems darf Pfand und Gutschein nicht enthalten
      expect(receipt.savableItems.length, 1); // nur itemNormal ist confirmed
      expect(receipt.savableItems.first.id, '1');
    });

    test('addItem fügt eine vergessene Position hinzu', () {
      const receipt = ScannedReceipt(id: 'receipt-add', items: [itemNormal]);

      expect(receipt.items.length, 1);
      expect(receipt.calculatedTotal, 1.19);

      final withNewItem = receipt.addItem(itemRabatt);

      expect(withNewItem.items.length, 2);
      expect(withNewItem.calculatedTotal, closeTo(3.19, 0.001)); // 1.19 + 2.00
    });

    test('confirmAllSuggestions updates only suggested items', () {
      const receipt = ScannedReceipt(
        id: 'receipt-2',
        items: [itemNormal, itemRabatt, itemDeposit],
      );

      final confirmedReceipt = receipt.confirmAllSuggestions();

      expect(confirmedReceipt.items[0].status, ReceiptItemStatus.confirmed);
      expect(confirmedReceipt.items[1].status, ReceiptItemStatus.confirmed);
      expect(confirmedReceipt.unresolvedCount, 0);
      expect(confirmedReceipt.savableItems.length, 2); // normal + rabatt
    });

    test('updateItem replaces target item cleanly with copyWith', () {
      const receipt = ScannedReceipt(
        id: 'receipt-3',
        items: [itemNormal, itemRabatt],
      );

      final updatedItem = itemRabatt.copyWith(quantity: 2);
      final updatedReceipt = receipt.updateItem(updatedItem);

      expect(updatedReceipt.items[1].quantity, 2);
      expect(updatedReceipt.items[0].quantity, 1);
    });
  });
}
