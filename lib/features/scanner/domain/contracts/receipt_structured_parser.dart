import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';

/// Contract for parsing receipt text or documents into a structured
/// [ScannedReceipt] using an AI model.
abstract interface class ReceiptStructuredParser {
  /// Parses extracted [rawText] (e.g. from local camera OCR) into
  /// a structured [ScannedReceipt].
  ///
  /// Preserves [sourceFilePaths] on the parsed receipt model for
  /// later reference and review.
  Future<ScannedReceipt> parseRawText({
    required String rawText,
    List<String> sourceFilePaths = const <String>[],
  });

  /// Parses a digital PDF document (e-receipt) directly into
  /// a structured [ScannedReceipt].
  Future<ScannedReceipt> parsePdf({required String pdfFilePath});
}
