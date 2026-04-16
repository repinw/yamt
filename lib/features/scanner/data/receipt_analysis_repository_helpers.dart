import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

const int _maxReceiptAnalysisBytes = 12 * 1024 * 1024;

/// Build receipt template inputs.
Future<Map<String, Object?>> buildReceiptTemplateInputs(
  ReceiptInputSelection selection,
) async {
  final bytes = await _resolveSelectionBytes(selection);
  if (bytes.length > _maxReceiptAnalysisBytes) {
    throw _ReceiptInputFileTooLargeException(bytes.length);
  }
  final base64Data = base64Encode(bytes);

  return <String, Object?>{
    'mimeType': selection.mimeType,
    'imageData': base64Data,
  };
}

Future<Uint8List> _resolveSelectionBytes(
  ReceiptInputSelection selection,
) async {
  if (selection.hasEmbeddedBytes) {
    return selection.bytes;
  }

  final filePath = selection.filePath;
  if (filePath == null || filePath.isEmpty) {
    throw const _ReceiptInputBytesMissingException(
      'Receipt input has no bytes and no file path.',
    );
  }
  final file = XFile(filePath);
  final fileLength = await file.length();
  if (fileLength > _maxReceiptAnalysisBytes) {
    throw _ReceiptInputFileTooLargeException(fileLength);
  }
  return file.readAsBytes();
}

class _ReceiptInputBytesMissingException implements Exception {
  const _ReceiptInputBytesMissingException(this.message);

  final String message;
}

class _ReceiptInputFileTooLargeException implements Exception {
  const _ReceiptInputFileTooLargeException(this.byteLength);

  final int byteLength;
}
