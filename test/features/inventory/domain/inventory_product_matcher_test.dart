import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_product_matcher.dart';

void main() {
  test('matches a product with a qualified variant name', () {
    expect(
      InventoryProductMatcher.matches(
        'Eiweißbrot',
        'Eiweißbrot - Proteinkorn',
      ),
      isTrue,
    );
  });

  test('matches regardless of token order and German normalization', () {
    expect(
      InventoryProductMatcher.matches(
        'Kräuter Frischkäse',
        'Frischkaese mit Kraeuter',
      ),
      isTrue,
    );
  });

  test('does not match partial words or short generic product names', () {
    expect(InventoryProductMatcher.matches('Brot', 'Brotaufstrich'), isFalse);
    expect(InventoryProductMatcher.matches('Pizza', 'Pizza Salami'), isFalse);
    expect(
      InventoryProductMatcher.matches('Apfelsaft', 'Apfelschorle'),
      isFalse,
    );
  });
}
