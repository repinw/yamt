import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_clients.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_parser.dart';
import 'package:yamt/features/scanner/data/receipt_analysis_repository_helpers.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_contracts.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

part 'receipt_analysis_repository.g.dart';

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
      return ReceiptAnalysisRepositoryFailures.templateConfig;
    }

    return _generateWithTemplate(templateId: templateId, selection: selection);
  }

  Future<ReceiptAnalysisResult> _generateWithTemplate({
    required String templateId,
    required ReceiptInputSelection selection,
  }) async {
    try {
      final inputs = buildReceiptTemplateInputs(selection);
      final responseText = await _templateModelClient.generateContent(
        templateId: templateId,
        inputs: inputs,
      );

      final normalizedResponse = normalizeReceiptAnalysisResponse(responseText);
      if (normalizedResponse == null) {
        return ReceiptAnalysisRepositoryFailures.emptyResponse;
      }

      logReceiptAnalysisRawResponse(normalizedResponse);
      final extraction = _parse(normalizedResponse);
      return ReceiptAnalysisResult.succeeded(
        rawResponse: normalizedResponse,
        extraction: extraction,
      );
    } on _ReceiptParseException {
      return ReceiptAnalysisRepositoryFailures.parse;
    } catch (error, stackTrace) {
      logReceiptAnalysisRepositoryError(
        message: 'Receipt AI request failed',
        error: error,
        stackTrace: stackTrace,
      );
      return ReceiptAnalysisRepositoryFailures.aiRequest;
    }
  }

  Future<String?> _loadTemplateId() async {
    try {
      return await _templateConfigClient.loadTemplateId();
    } catch (error, stackTrace) {
      logReceiptAnalysisRepositoryError(
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
      logReceiptAnalysisRepositoryError(
        message: 'Receipt analysis parse failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw _ReceiptParseException();
    }
  }
}

final class _ReceiptParseException implements Exception {}
