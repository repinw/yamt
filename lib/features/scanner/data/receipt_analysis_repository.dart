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
const String _receiptTemplateId = 'testtemplate';

abstract final class _ReceiptAnalysisRepositoryFailures {
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

/// Receipt analysis repository.
@riverpod
ReceiptAnalysisRepository receiptAnalysisRepository(Ref ref) {
  return DeviceReceiptAnalysisRepository(
    templateModelClient: ref.watch(receiptTemplateModelClientProvider),
    parser: ref.watch(receiptAnalysisParserProvider),
  );
}

/// Defines device receipt analysis repository.
class DeviceReceiptAnalysisRepository implements ReceiptAnalysisRepository {
  /// Creates an instance.
  DeviceReceiptAnalysisRepository({
    required ReceiptTemplateModelClient templateModelClient,
    required ReceiptAnalysisParser parser,
  }) : _templateModelClient = templateModelClient,
       _parser = parser;

  final ReceiptTemplateModelClient _templateModelClient;
  final ReceiptAnalysisParser _parser;

  @override
  Future<ReceiptAnalysisResult> analyzeSelection(
    ReceiptInputSelection selection,
  ) async {
    return _generateWithTemplate(
      templateId: _receiptTemplateId,
      selection: selection,
    );
  }

  Future<ReceiptAnalysisResult> _generateWithTemplate({
    required String templateId,
    required ReceiptInputSelection selection,
  }) async {
    final totalStopwatch = Stopwatch()..start();
    try {
      final inputStopwatch = Stopwatch()..start();
      final resolvedInputs = await buildReceiptTemplateInputs(selection);
      inputStopwatch.stop();
      _logReceiptAnalysisTiming(
        'input',
        inputStopwatch.elapsed,
        selection: selection,
      );

      final requestStopwatch = Stopwatch()..start();
      final responseText = await _templateModelClient.generateContent(
        templateId: templateId,
        inputs: resolvedInputs,
      );
      requestStopwatch.stop();
      _logReceiptAnalysisTiming(
        'model',
        requestStopwatch.elapsed,
        selection: selection,
      );

      final normalizedResponse = _normalizeReceiptAnalysisResponse(
        responseText,
      );
      if (normalizedResponse == null) {
        return _ReceiptAnalysisRepositoryFailures.emptyResponse;
      }

      _logReceiptAnalysisRawResponse(normalizedResponse);
      final parseStopwatch = Stopwatch()..start();
      final extraction = _parse(normalizedResponse);
      parseStopwatch.stop();
      _logReceiptAnalysisTiming(
        'parse',
        parseStopwatch.elapsed,
        selection: selection,
      );
      totalStopwatch.stop();
      _logReceiptAnalysisTiming(
        'total',
        totalStopwatch.elapsed,
        selection: selection,
        itemCount: extraction.items.length,
      );
      return ReceiptAnalysisResult.succeeded(
        rawResponse: normalizedResponse,
        extraction: extraction,
      );
    } on _ReceiptParseException {
      return _ReceiptAnalysisRepositoryFailures.parse;
    } on Object catch (error, stackTrace) {
      _logReceiptAnalysisRepositoryError(
        message: 'Receipt AI request failed',
        error: error,
        stackTrace: stackTrace,
      );
      return _ReceiptAnalysisRepositoryFailures.aiRequest;
    }
  }

  ReceiptAnalysisExtraction _parse(String normalizedResponse) {
    try {
      return _parser.parse(normalizedResponse);
    } on Object catch (error, stackTrace) {
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

void _logReceiptAnalysisTiming(
  String stage,
  Duration elapsed, {
  required ReceiptInputSelection selection,
  int? itemCount,
}) {
  assert(() {
    final itemSuffix = itemCount == null ? '' : ', items: $itemCount';
    log(
      'Receipt analysis $stage took ${elapsed.inMilliseconds}ms '
      'for ${selection.name}$itemSuffix.',
      name: _repositoryLogName,
    );
    return true;
  }(), 'Receipt analysis timing log should run only in debug mode.');
}

void _logReceiptAnalysisRepositoryError({
  required String message,
  required Object error,
  required StackTrace stackTrace,
}) {
  log(message, name: _repositoryLogName, error: error, stackTrace: stackTrace);
}
