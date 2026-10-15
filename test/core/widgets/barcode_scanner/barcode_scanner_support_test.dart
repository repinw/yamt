import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/widgets/barcode_scanner/barcode_scanner_support.dart';

void main() {
  final start = DateTime(2026);
  Duration ms(int value) => Duration(milliseconds: value);
  const a = '4006381333931';
  const b = '4006381333948';

  test('a barcode counts once it is read twice in a row', () {
    final confirmation = BarcodeScanConfirmation();

    expect(confirmation.confirm(a, start), isFalse);
    // Another code starts over.
    expect(confirmation.confirm(b, start.add(ms(200))), isFalse);
    expect(confirmation.confirm(b, start.add(ms(400))), isTrue);
  });

  test('a read at the end of the window still continues, a later one '
      'starts over', () {
    final confirmation = BarcodeScanConfirmation()..confirm(a, start);

    expect(confirmation.confirm(a, start.add(ms(800))), isTrue);

    final late = BarcodeScanConfirmation()..confirm(a, start);
    expect(late.confirm(a, start.add(ms(801))), isFalse);
  });

  test('reset forgets the reads so far', () {
    final confirmation = BarcodeScanConfirmation()
      ..confirm(a, start)
      ..reset();

    expect(confirmation.confirm(a, start.add(ms(100))), isFalse);
    expect(confirmation.confirm(a, start.add(ms(200))), isTrue);
  });

  test('requiredReads sets how many reads in a row count', () {
    final confirmation = BarcodeScanConfirmation(requiredReads: 3);

    expect(confirmation.confirm(a, start), isFalse);
    expect(confirmation.confirm(a, start.add(ms(100))), isFalse);
    expect(confirmation.confirm(a, start.add(ms(200))), isTrue);
  });
}
