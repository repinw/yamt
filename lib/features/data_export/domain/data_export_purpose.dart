/// A file the export writes.
enum DataExportFormat {
  /// Plain text (Markdown inside) with a question for an AI and explained
  /// fields; `.txt` because some AI apps take no `.md` file.
  text('txt', 'text/plain'),

  /// A report with charts and a day table.
  pdf('pdf', 'application/pdf'),

  /// A spreadsheet with one sheet per subject.
  xlsx(
    'xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );

  new(this.extension, this.mimeType);

  /// File name extension without the dot.
  final String extension;

  /// MIME type for the share sheet.
  final String mimeType;
}

/// Who the export is for. It decides which files the export writes.
enum DataExportPurpose {
  /// The user's own AI, which gives feedback on the eating.
  ai([DataExportFormat.text]),

  /// A nutrition advisor, who reads the report and works with the table.
  advisor([DataExportFormat.pdf, DataExportFormat.xlsx]),

  /// The user, for an overview; saved on the device, not shared.
  self([DataExportFormat.pdf], saves: true);

  new(this.formats, {this.saves = false});

  /// The files of this purpose, in share order.
  final List<DataExportFormat> formats;

  /// Whether the files are saved on the device instead of shared.
  final bool saves;
}
