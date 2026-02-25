import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_barcode_utils.dart';

void main() {
  test('normalizeBarcode removes non-digit characters', () {
    expect(normalizeBarcode('  40-0638 1333 931  '), '4006381333931');
  });

  test('isSupportedBarcode validates expected lengths', () {
    expect(isSupportedBarcode('1234567'), isFalse);
    expect(isSupportedBarcode('12345678'), isTrue);
    expect(isSupportedBarcode('12345678901234'), isTrue);
    expect(isSupportedBarcode('123456789012345'), isFalse);
  });
}
