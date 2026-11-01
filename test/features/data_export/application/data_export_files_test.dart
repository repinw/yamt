import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/data_export/application/data_export_files.dart';
import 'package:yamt/features/data_export/application/data_export_labels.dart';
import 'package:yamt/features/data_export/data/data_export_file_sharer.dart';
import 'package:yamt/features/data_export/domain/data_export_purpose.dart';

import '../../../helpers/data_export_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DataExportLabels labels;

  setUpAll(() async {
    labels = await englishLabels();
  });

  Future<List<DataExportFile>> write(DataExportPurpose purpose) =>
      writeDataExportFiles(
        report: sampleReport(),
        purpose: purpose,
        labels: labels,
      );

  test('the AI gets one text file', () async {
    final files = await write(DataExportPurpose.ai);

    expect(files, hasLength(1));
    expect(files.single.name, 'yamt-2026-09-20-2026-09-22.txt');
    expect(files.single.mimeType, 'text/plain');
    expect(utf8.decode(files.single.bytes), startsWith('# Nutrition report'));
  });

  test('the advisor gets a PDF and then a spreadsheet', () async {
    final files = await write(DataExportPurpose.advisor);

    expect(files.map((file) => file.name), [
      'yamt-2026-09-20-2026-09-22.pdf',
      'yamt-2026-09-20-2026-09-22.xlsx',
    ]);
    expect(files.first.mimeType, 'application/pdf');
    expect(
      files.last.mimeType,
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    expect(utf8.decode(files.first.bytes.sublist(0, 5)), '%PDF-');
    expect(
      ZipDecoder().decodeBytes(files.last.bytes).findFile('xl/workbook.xml'),
      isNotNull,
    );
  });

  test('for myself gets a PDF', () async {
    final files = await write(DataExportPurpose.self);

    expect(files.map((file) => file.name), ['yamt-2026-09-20-2026-09-22.pdf']);
    expect(files.single.mimeType, 'application/pdf');
    expect(files.single.bytes, isNotEmpty);
  });

  test('only the personal purpose saves', () {
    expect(DataExportPurpose.ai.saves, isFalse);
    expect(DataExportPurpose.advisor.saves, isFalse);
    expect(DataExportPurpose.self.saves, isTrue);
  });

  test('file name holds the first and last day', () {
    expect(
      DataExportLabels.fileName(sampleReport(), 'pdf'),
      'yamt-2026-09-20-2026-09-22.pdf',
    );
  });
}
