import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/receipt_analysis_parser.dart';

void main() {
  const parser = JsonReceiptAnalysisParser();

  test('parses root object with minified items key', () {
    const rawResponse = '{"s":"Store","i":[{"n":"Milk"},{"n":"Bread"}]}';

    final extraction = parser.parse(rawResponse);

    expect(extraction.root['s'], 'Store');
    expect(extraction.items.length, 2);
    expect(extraction.items.first['n'], 'Milk');
  });

  test('parses fenced json payload', () {
    const rawResponse = '''
```json
{"items":[{"name":"Yogurt"}]}
```
''';

    final extraction = parser.parse(rawResponse);

    expect(extraction.items.length, 1);
    expect(extraction.items.first['name'], 'Yogurt');
  });

  test('parses list root as items collection', () {
    const rawResponse = '[{"n":"Apple"},{"n":"Banana"}]';

    final extraction = parser.parse(rawResponse);

    expect(extraction.root, isEmpty);
    expect(extraction.items.length, 2);
  });

  test('throws format exception for invalid json root', () {
    const rawResponse = '"not an object or list"';

    expect(() => parser.parse(rawResponse), throwsA(isA<FormatException>()));
  });
}
