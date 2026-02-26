import 'dart:convert';
import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

const String _repositoryLogName = 'DeviceReceiptAnalysisRepository';

abstract final class ReceiptAnalysisRepositoryFailures {
  static const templateConfig = ReceiptAnalysisResult.failed(
    errorCode: ReceiptAnalysisErrorCodes.templateConfigFailed,
  );
  static const emptyResponse = ReceiptAnalysisResult.failed(
    errorCode: ReceiptAnalysisErrorCodes.emptyResponse,
  );
  static const aiRequest = ReceiptAnalysisResult.failed(
    errorCode: ReceiptAnalysisErrorCodes.aiRequestFailed,
  );
  static const parse = ReceiptAnalysisResult.failed(
    errorCode: ReceiptAnalysisErrorCodes.parseFailed,
  );
}

Future<Map<String, Object?>> buildReceiptTemplateInputs(
  ReceiptInputSelection selection,
) async {
  final bytes = await _resolveSelectionBytes(selection);
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
    throw const ReceiptInputBytesMissingException(
      'Receipt input has no bytes and no file path.',
    );
  }
  return XFile(filePath).readAsBytes();
}

class ReceiptInputBytesMissingException implements Exception {
  const ReceiptInputBytesMissingException(this.message);

  final String message;
}

String? normalizeReceiptAnalysisResponse(String? responseText) {
  if (responseText == null || responseText.trim().isEmpty) {
    return null;
  }

  return responseText;
}

void logReceiptAnalysisRawResponse(String rawResponse) {
  if (!kDebugMode) {
    return;
  }

  log('Receipt AI raw response:\n$rawResponse', name: _repositoryLogName);
}

void logReceiptAnalysisRepositoryError({
  required String message,
  required Object error,
  required StackTrace stackTrace,
}) {
  log(message, name: _repositoryLogName, error: error, stackTrace: stackTrace);
}
