import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_import_repository.dart';

const _answer = '''
{"items": [{"name": "Milch", "quantity": 2, "note": null, "shelf": "chilled"}],
 "skipped": ["Samstag"]}
''';

void main() {
  test('sends the pasted text and reads the answer', () async {
    Map<String, Object?>? sent;
    final repository = ShoppingListImportRepository(
      templateClient: (inputs) async {
        sent = inputs;
        return _answer;
      },
    );

    final reading = await repository.loadFromText('2 Milch\nSamstag');

    expect(sent, {'text': '2 Milch\nSamstag'});
    expect(reading.lines.single.name, 'Milch');
    expect(reading.skipped, ['Samstag']);
  });

  test('sends scanned PDF pages as files', () async {
    final directory = await Directory.systemTemp.createTemp('shopping_import');
    addTearDown(() => directory.delete(recursive: true));
    final pdf = File('${directory.path}/list.pdf')
      ..writeAsBytesSync(utf8.encode('%PDF'));
    Map<String, Object?>? sent;
    final repository = ShoppingListImportRepository(
      templateClient: (inputs) async {
        sent = inputs;
        return _answer;
      },
    );

    await repository.loadFromFiles([pdf.path]);

    expect(sent, {
      'files': [
        {
          'mimeType': 'application/pdf',
          'data': base64Encode(utf8.encode('%PDF')),
        },
      ],
    });
  });

  test('an empty answer is a FormatException', () async {
    final repository = ShoppingListImportRepository(
      templateClient: (_) async => ' ',
    );

    expect(() => repository.loadFromText('Milch'), throwsFormatException);
  });

  test('an answer of the wrong shape is a FormatException', () async {
    final repository = ShoppingListImportRepository(
      templateClient: (_) async => '{"items": "Milch"}',
    );

    expect(() => repository.loadFromText('Milch'), throwsFormatException);
  });
}
