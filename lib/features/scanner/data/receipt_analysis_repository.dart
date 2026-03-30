import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_clients.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_parser.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_repository_helpers.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_contracts.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

part 'receipt_analysis_repository.g.dart';

const String _repositoryLogName = 'DeviceReceiptAnalysisRepository';

abstract final class _ReceiptAnalysisRepositoryFailures {
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

@riverpod
ReceiptAnalysisRepository receiptAnalysisRepository(Ref ref) {
  return DeviceReceiptAnalysisRepository(
    templateConfigClient: ref.watch(receiptTemplateConfigClientProvider),
    templateModelClient: ref.watch(receiptTemplateModelClientProvider),
    parser: ref.watch(receiptAnalysisParserProvider),
  );
}

class DeviceReceiptAnalysisRepository implements ReceiptAnalysisRepository {
  DeviceReceiptAnalysisRepository({
    required ReceiptTemplateConfigClient templateConfigClient,
    required ReceiptTemplateModelClient templateModelClient,
    required ReceiptAnalysisParser parser,
  }) : _templateConfigClient = templateConfigClient,
       _templateModelClient = templateModelClient,
       _parser = parser;

  final ReceiptTemplateConfigClient _templateConfigClient;
  final ReceiptTemplateModelClient _templateModelClient;
  final ReceiptAnalysisParser _parser;

  @override
  Future<ReceiptAnalysisResult> analyzeSelection(
    ReceiptInputSelection selection,
  ) async {
    final templateId = await _loadTemplateId();
    if (templateId == null) {
      return _ReceiptAnalysisRepositoryFailures.templateConfig;
    }

    return _generateWithTemplate(templateId: templateId, selection: selection);
  }

  Future<ReceiptAnalysisResult> _generateWithTemplate({
    required String templateId,
    required ReceiptInputSelection selection,
  }) async {
    try {
      final resolvedInputs = await buildReceiptTemplateInputs(selection);
      final responseText = await _templateModelClient.generateContent(
        templateId: templateId,
        inputs: resolvedInputs,
      );

      final normalizedResponse = _normalizeReceiptAnalysisResponse(
        responseText,
      );
      if (normalizedResponse == null) {
        return _ReceiptAnalysisRepositoryFailures.emptyResponse;
      }

      _logReceiptAnalysisRawResponse(normalizedResponse);
      final extraction = _parse(normalizedResponse);
      return ReceiptAnalysisResult.succeeded(
        rawResponse: normalizedResponse,
        extraction: extraction,
      );
    } on _ReceiptParseException {
      return _ReceiptAnalysisRepositoryFailures.parse;
    } catch (error, stackTrace) {
      _logReceiptAnalysisRepositoryError(
        message: 'Receipt AI request failed',
        error: error,
        stackTrace: stackTrace,
      );
      return _ReceiptAnalysisRepositoryFailures.aiRequest;
    }
  }

  Future<String?> _loadTemplateId() async {
    try {
      return await _templateConfigClient.loadTemplateId();
    } catch (error, stackTrace) {
      _logReceiptAnalysisRepositoryError(
        message: 'Receipt template config load failed',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  ReceiptAnalysisExtraction _parse(String normalizedResponse) {
    try {
      return _parser.parse(normalizedResponse);
    } catch (error, stackTrace) {
      _logReceiptAnalysisRepositoryError(
        message: 'Receipt analysis parse failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw _ReceiptParseException();
    }
  }
}

final class _ReceiptParseException implements Exception {}

String? _normalizeReceiptAnalysisResponse(String? responseText) {
  if (responseText == null || responseText.trim().isEmpty) {
    return null;
  }

  return responseText;
}

void _logReceiptAnalysisRawResponse(String rawResponse) {
  if (!kDebugMode) {
    return;
  }

  log('Receipt AI raw response:\n$rawResponse', name: _repositoryLogName);
}

void _logReceiptAnalysisRepositoryError({
  required String message,
  required Object error,
  required StackTrace stackTrace,
}) {
  log(message, name: _repositoryLogName, error: error, stackTrace: stackTrace);
}
