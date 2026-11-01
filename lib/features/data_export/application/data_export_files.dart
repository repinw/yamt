import 'dart:convert';

import 'package:yamt/features/data_export/application/data_export_labels.dart';
import 'package:yamt/features/data_export/application/data_export_markdown_writer.dart';
import 'package:yamt/features/data_export/application/data_export_pdf_writer.dart';
import 'package:yamt/features/data_export/application/data_export_xlsx_writer.dart';
import 'package:yamt/features/data_export/data/data_export_file_sharer.dart';
import 'package:yamt/features/data_export/domain/data_export_purpose.dart';
import 'package:yamt/features/data_export/domain/data_export_report.dart';

/// Writes the files of [purpose] for [report], in share order.
Future<List<DataExportFile>> writeDataExportFiles({
  required DataExportReport report,
  required DataExportPurpose purpose,
  required DataExportLabels labels,
}) async {
  return [
    for (final format in purpose.formats)
      DataExportFile(
        name: DataExportLabels.fileName(report, format.extension),
        mimeType: format.mimeType,
        bytes: switch (format) {
          DataExportFormat.text => utf8.encode(
            writeDataExportMarkdown(report, labels),
          ),
          DataExportFormat.pdf => await writeDataExportPdf(report, labels),
          DataExportFormat.xlsx => writeDataExportXlsx(report, labels),
        },
      ),
  ];
}
