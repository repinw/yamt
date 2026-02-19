import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/data/receipt_analysis_clients.dart';
import 'package:yamt/features/inventory/data/receipt_analysis_repository_helpers.dart';
import 'package:yamt/features/inventory/domain/receipt_analysis_models.dart';
import 'package:yamt/features/inventory/domain/receipt_input_models.dart';

export 'package:yamt/features/inventory/data/receipt_analysis_clients.dart'
    show ReceiptTemplateConfigClient, ReceiptTemplateModelClient;

part 'receipt_analysis_repository.g.dart';

@riverpod
ReceiptAnalysisRepository receiptAnalysisRepository(Ref ref) {
  return DeviceReceiptAnalysisRepository(
    templateConfigClient: ref.watch(receiptTemplateConfigClientProvider),
    templateModelClient: ref.watch(receiptTemplateModelClientProvider),
  );
}

/// Reads a picked receipt input and returns the analysis output.
abstract interface class ReceiptAnalysisRepository {
  Future<ReceiptAnalysisResult> analyzeSelection(
    ReceiptInputSelection selection,
  );
}

class DeviceReceiptAnalysisRepository implements ReceiptAnalysisRepository {
  DeviceReceiptAnalysisRepository({
    required ReceiptTemplateConfigClient templateConfigClient,
    required ReceiptTemplateModelClient templateModelClient,
  }) : _templateConfigClient = templateConfigClient,
       _templateModelClient = templateModelClient;

  final ReceiptTemplateConfigClient _templateConfigClient;
  final ReceiptTemplateModelClient _templateModelClient;

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

      return ReceiptAnalysisResult.succeeded(rawResponse: normalizedResponse);
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
}
