import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:yamt/features/scanner/domain/contracts/receipt_text_extractor.dart';

/// Function signature for processing a single image file to text.
typedef ImageFileTextProcessor = Future<String> Function(String filePath);

/// On-device receipt text extractor using Google ML Kit.
class MlKitReceiptTextExtractor implements ReceiptTextExtractor {
  /// Creates an [MlKitReceiptTextExtractor].
  ///
  /// For tests, [fileProcessor] can be provided to avoid native platform calls.
  MlKitReceiptTextExtractor({
    ImageFileTextProcessor? fileProcessor,
    TextRecognizer? textRecognizer,
  }) : _fileProcessor = fileProcessor,
       _recognizer = textRecognizer,
       _ownsRecognizer = textRecognizer == null && fileProcessor == null;

  final ImageFileTextProcessor? _fileProcessor;
  TextRecognizer? _recognizer;
  final bool _ownsRecognizer;

  TextRecognizer get _activeRecognizer {
    return _recognizer ??= TextRecognizer();
  }

  @override
  Future<String> extractText(List<String> filePaths) async {
    if (filePaths.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();

    for (final filePath in filePaths) {
      final normalizedPath = filePath.trim();
      if (normalizedPath.isEmpty) {
        continue;
      }

      if (normalizedPath.toLowerCase().endsWith('.pdf')) {
        throw ArgumentError.value(
          filePath,
          'filePath',
          'MlKitReceiptTextExtractor only supports image files (JPEG, PNG, '
              'etc.), not PDF documents. Use ReceiptStructuredParser.parsePdf '
              'for PDF e-receipts.',
        );
      }

      final text = await _processSingleFile(normalizedPath);
      final trimmed = text.trim();
      if (trimmed.isNotEmpty) {
        if (buffer.isNotEmpty) {
          buffer.writeln();
        }
        buffer.write(trimmed);
      }
    }

    return buffer.toString();
  }

  Future<String> _processSingleFile(String filePath) async {
    if (_fileProcessor != null) {
      return _fileProcessor(filePath);
    }

    final inputImage = InputImage.fromFilePath(filePath);
    final recognizedText = await _activeRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  @override
  Future<void> dispose() async {
    if (_ownsRecognizer && _recognizer != null) {
      await _recognizer!.close();
      _recognizer = null;
    }
  }
}
