import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/receipt_analysis_parser.dart';
import 'package:yamt/features/inventory/domain/receipt_analysis_models.dart';

void main() {
  const parser = JsonReceiptAnalysisParser();

  test('parses root object with minified items key', () {
    const rawResponse = '{"s":"Store","i":[{"n":"Milk"},{"n":"Bread"}]}';

    final extraction = parser.parse(rawResponse);

    expect(extraction.root['s'], 'Store');
    expect(extraction.items.length, 2);
    expect(extraction.items.first.name, 'Milk');
    expect(extraction.items.first.rawPayload['n'], 'Milk');
  });

  test('parses fenced json payload', () {
    const rawResponse = '''
```json
{"items":[{"name":"Yogurt"}]}
```
''';

    final extraction = parser.parse(rawResponse);

    expect(extraction.items.length, 1);
    expect(extraction.items.first.name, 'Yogurt');
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

  test('throws when items list contains invalid entry', () {
    const rawResponse = '{"items":[{"n":"Milk"},123]}';

    expect(() => parser.parse(rawResponse), throwsA(isA<FormatException>()));
  });

  test('parses code fence with upper-case language label', () {
    const rawResponse = '''
```JSON
{"i":[{"n":"Butter"}]}
```
''';

    final extraction = parser.parse(rawResponse);
    expect(extraction.items, hasLength(1));
    expect(extraction.items.first.name, 'Butter');
  });

  test('typed items expose strongly-typed item model', () {
    const rawResponse = '{"i":[{"n":"Cheese"}]}';

    final extraction = parser.parse(rawResponse);

    expect(extraction.items.single, isA<ReceiptAnalysisItem>());
  });
}
