import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:meta/meta.dart';

/// One sheet of an `.xlsx` workbook. The first row is the header and shows
/// bold. A cell is a [num], a [String], or null for an empty cell.
@immutable
class XlsxSheet {
  /// Creates a sheet named [name] with [rows].
  const new({required this.name, required this.rows});

  /// Tab name, at most 31 characters and none of `[]:*?/\`.
  final String name;

  /// Rows of cells, header first.
  final List<List<Object?>> rows;
}

/// Encodes [sheets] as an Office Open XML spreadsheet (`.xlsx`).
Uint8List encodeXlsxWorkbook(List<XlsxSheet> sheets) {
  final archive = Archive()
    ..addFile(ArchiveFile.string('[Content_Types].xml', _contentTypes(sheets)))
    ..addFile(ArchiveFile.string('_rels/.rels', _rootRelations))
    ..addFile(ArchiveFile.string('xl/workbook.xml', _workbook(sheets)))
    ..addFile(
      ArchiveFile.string('xl/_rels/workbook.xml.rels', _relations(sheets)),
    )
    ..addFile(ArchiveFile.string('xl/styles.xml', _styles));
  for (final (index, sheet) in sheets.indexed) {
    archive.addFile(
      ArchiveFile.string(
        'xl/worksheets/sheet${index + 1}.xml',
        _worksheet(sheet),
      ),
    );
  }
  return ZipEncoder().encodeBytes(archive);
}

const _xmlHead = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
const _openXml = 'http://schemas.openxmlformats.org';
const _mainNamespace = '$_openXml/spreadsheetml/2006/main';
const _relationNamespace = '$_openXml/officeDocument/2006/relationships';
const _packageRelationNamespace = '$_openXml/package/2006/relationships';
const _officeType = 'application/vnd.openxmlformats-officedocument';

String _contentTypes(List<XlsxSheet> sheets) => [
  _xmlHead,
  '<Types xmlns="$_openXml/package/2006/content-types">',
  '<Default Extension="rels" ',
  'ContentType="application/vnd.openxmlformats-package.relationships+xml"/>',
  '<Default Extension="xml" ContentType="application/xml"/>',
  '<Override PartName="/xl/workbook.xml" ',
  'ContentType="$_officeType.spreadsheetml.sheet.main+xml"/>',
  '<Override PartName="/xl/styles.xml" ',
  'ContentType="$_officeType.spreadsheetml.styles+xml"/>',
  for (var number = 1; number <= sheets.length; number++) ...[
    '<Override PartName="/xl/worksheets/sheet$number.xml" ',
    'ContentType="$_officeType.spreadsheetml.worksheet+xml"/>',
  ],
  '</Types>',
].join();

final String _rootRelations = [
  _xmlHead,
  '<Relationships xmlns="$_packageRelationNamespace">',
  '<Relationship Id="rId1" Type="$_relationNamespace/officeDocument" ',
  'Target="xl/workbook.xml"/>',
  '</Relationships>',
].join();

String _workbook(List<XlsxSheet> sheets) => [
  _xmlHead,
  '<workbook xmlns="$_mainNamespace" xmlns:r="$_relationNamespace">',
  '<sheets>',
  for (final (index, sheet) in sheets.indexed) ...[
    '<sheet name="${_escape(sheet.name)}" ',
    'sheetId="${index + 1}" r:id="rId${index + 1}"/>',
  ],
  '</sheets></workbook>',
].join();

String _relations(List<XlsxSheet> sheets) => [
  _xmlHead,
  '<Relationships xmlns="$_packageRelationNamespace">',
  for (var number = 1; number <= sheets.length; number++) ...[
    '<Relationship Id="rId$number" Type="$_relationNamespace/worksheet" ',
    'Target="worksheets/sheet$number.xml"/>',
  ],
  '<Relationship Id="rId${sheets.length + 1}" ',
  'Type="$_relationNamespace/styles" Target="styles.xml"/>',
  '</Relationships>',
].join();

/// Style 0 is plain, style 1 bold for the header row.
final String _styles = [
  _xmlHead,
  '<styleSheet xmlns="$_mainNamespace">',
  '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>',
  '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>',
  '<fills count="2"><fill><patternFill patternType="none"/></fill>',
  '<fill><patternFill patternType="gray125"/></fill></fills>',
  '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/>',
  '</border></borders>',
  '<cellStyleXfs count="1">',
  '<xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>',
  '</cellStyleXfs>',
  '<cellXfs count="2">',
  '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>',
  '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" ',
  'applyFont="1"/>',
  '</cellXfs></styleSheet>',
].join();

String _worksheet(XlsxSheet sheet) {
  final rows = StringBuffer();
  for (final (rowIndex, row) in sheet.rows.indexed) {
    final style = rowIndex == 0 ? ' s="1"' : '';
    rows.write('<row r="${rowIndex + 1}">');
    for (final (columnIndex, cell) in row.indexed) {
      final ref = '${_column(columnIndex)}${rowIndex + 1}';
      switch (cell) {
        case num() when cell.isFinite:
          rows.write('<c r="$ref"$style><v>$cell</v></c>');
        case String():
          rows
            ..write('<c r="$ref" t="inlineStr"$style>')
            ..write('<is><t xml:space="preserve">${_escape(cell)}</t></is>')
            ..write('</c>');
      }
    }
    rows.write('</row>');
  }
  return [
    _xmlHead,
    '<worksheet xmlns="$_mainNamespace">',
    '<sheetViews><sheetView workbookViewId="0">',
    '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" ',
    'state="frozen"/>',
    '</sheetView></sheetViews>',
    '<sheetData>$rows</sheetData></worksheet>',
  ].join();
}

/// Column letters of the 0-based [index]: 0 is A, 26 is AA.
String _column(int index) {
  final letters = <String>[];
  var rest = index + 1;
  while (rest > 0) {
    letters.insert(0, String.fromCharCode(0x41 + (rest - 1) % 26));
    rest = (rest - 1) ~/ 26;
  }
  return letters.join();
}

/// [text] escaped for XML, without the control characters XML forbids.
String _escape(String text) =>
    const HtmlEscape(HtmlEscapeMode.element)
        .convert(text.replaceAll(_forbiddenControl, ''))
        .replaceAll('"', '&quot;');

final _forbiddenControl = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]');
