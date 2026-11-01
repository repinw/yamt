import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/utils/xlsx_workbook.dart';

Archive _decode(List<XlsxSheet> sheets) =>
    ZipDecoder().decodeBytes(encodeXlsxWorkbook(sheets));

String _text(Archive archive, String name) =>
    utf8.decode(archive.findFile(name)!.content);

void main() {
  test('encodes a zip with the parts of a workbook and one file per sheet', () {
    final archive = _decode(const [
      XlsxSheet(
        name: 'One',
        rows: [
          <Object?>['a'],
        ],
      ),
      XlsxSheet(
        name: 'Two',
        rows: [
          <Object?>['b'],
        ],
      ),
    ]);

    expect(archive.files.map((file) => file.name), [
      '[Content_Types].xml',
      '_rels/.rels',
      'xl/workbook.xml',
      'xl/_rels/workbook.xml.rels',
      'xl/styles.xml',
      'xl/worksheets/sheet1.xml',
      'xl/worksheets/sheet2.xml',
    ]);
    final workbook = _text(archive, 'xl/workbook.xml');
    expect(workbook, contains('<sheet name="One" sheetId="1" r:id="rId1"/>'));
    expect(workbook, contains('<sheet name="Two" sheetId="2" r:id="rId2"/>'));
  });

  test('writes numbers as numbers and strings inline', () {
    final sheet = _text(
      _decode(const [
        XlsxSheet(
          name: 'S',
          rows: [
            <Object?>['Head', 'Count'],
            <Object?>['Oats', 42],
            <Object?>['Rice', 1.5],
          ],
        ),
      ]),
      'xl/worksheets/sheet1.xml',
    );

    expect(sheet, contains('<c r="A2" t="inlineStr">'));
    expect(sheet, contains('<c r="B2"><v>42</v></c>'));
    expect(sheet, contains('<c r="B3"><v>1.5</v></c>'));
  });

  test('only the header row is bold', () {
    final sheet = _text(
      _decode(const [
        XlsxSheet(
          name: 'S',
          rows: [
            <Object?>['Head'],
            <Object?>['Body'],
          ],
        ),
      ]),
      'xl/worksheets/sheet1.xml',
    );

    expect(sheet, contains('<c r="A1" t="inlineStr" s="1">'));
    expect(sheet, contains('<c r="A2" t="inlineStr">'));
  });

  test('skips null cells, NaN, and infinite numbers', () {
    final sheet = _text(
      _decode(const [
        XlsxSheet(
          name: 'S',
          rows: [
            <Object?>['h'],
            <Object?>[null, double.nan, double.infinity, -double.infinity, 7],
          ],
        ),
      ]),
      'xl/worksheets/sheet1.xml',
    );

    expect(sheet, isNot(contains('NaN')));
    expect(sheet, isNot(contains('Infinity')));
    expect(sheet, isNot(contains('r="A2"')));
    expect(sheet, isNot(contains('r="B2"')));
    expect(sheet, isNot(contains('r="C2"')));
    expect(sheet, isNot(contains('r="D2"')));
    expect(sheet, contains('<c r="E2"><v>7</v></c>'));
  });

  test('escapes XML characters in cells and sheet names', () {
    final archive = _decode(const [
      XlsxSheet(
        name: 'Fish & "Chips"',
        rows: [
          <Object?>['<b>"Tom" & \'Jerry\'</b>'],
        ],
      ),
    ]);

    expect(
      _text(archive, 'xl/workbook.xml'),
      contains('name="Fish &amp; &quot;Chips&quot;"'),
    );
    final sheet = _text(archive, 'xl/worksheets/sheet1.xml');
    expect(sheet, contains('&lt;b&gt;'));
    expect(sheet, contains('&amp;'));
    expect(sheet, isNot(contains('<b>')));
  });

  test('drops control characters that XML forbids', () {
    final sheet = _text(
      _decode(const [
        XlsxSheet(
          name: 'S',
          rows: [
            <Object?>['a\u0000b\u0008c\u000Bd\u001Fe\tf\ng'],
          ],
        ),
      ]),
      'xl/worksheets/sheet1.xml',
    );

    expect(sheet, contains('abcde\tf\ng'));
  });

  test('names the columns past Z with two letters', () {
    final sheet = _text(
      _decode([
        XlsxSheet(
          name: 'S',
          rows: [
            [for (var i = 0; i < 28; i++) i],
          ],
        ),
      ]),
      'xl/worksheets/sheet1.xml',
    );

    expect(sheet, contains('r="Z1"'));
    expect(sheet, contains('r="AA1"'));
    expect(sheet, contains('r="AB1"'));
  });

  test('freezes the header row', () {
    final sheet = _text(
      _decode(const [XlsxSheet(name: 'S', rows: [])]),
      'xl/worksheets/sheet1.xml',
    );

    expect(sheet, contains('state="frozen"'));
  });
}
