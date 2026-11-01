import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/data_export/application/data_export_pdf_writer.dart';

import '../../../helpers/data_export_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('writes a PDF document', () async {
    final labels = await englishLabels();

    final bytes = await writeDataExportPdf(sampleReport(), labels);

    expect(bytes, isNotEmpty);
    expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
  });

  test('writes a PDF for a report without a logged day', () async {
    final labels = await englishLabels();

    final bytes = await writeDataExportPdf(
      exportReport([exportDay(DateTime(2026, 9, 20))], withGoal: false),
      labels,
    );

    expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
  });
}
