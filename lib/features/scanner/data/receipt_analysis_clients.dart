// ignore_for_file: experimental_member_use

import 'package:firebase_ai/firebase_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/settings/provider/ai_processing_level_controller.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_contracts.dart';

part 'receipt_analysis_clients.g.dart';

const String _minimalReceiptTemplateId = 'receiptocr-minimal';
const String _lowReceiptTemplateId = 'receiptocr-low';
const String _balancedReceiptTemplateId = 'receiptocr-medium';
const String _highReceiptTemplateId = 'receiptocr-high';
const String _vertexLocation = 'global';

@riverpod
ReceiptTemplateConfigClient receiptTemplateConfigClient(Ref ref) {
  return StaticReceiptTemplateConfigClient(
    level: ref.watch(aiProcessingLevelControllerProvider),
  );
}

@riverpod
ReceiptTemplateModelClient receiptTemplateModelClient(Ref ref) {
  return FirebaseReceiptTemplateModelClient(
    model: FirebaseAI.vertexAI(
      location: _vertexLocation,
    ).templateGenerativeModel(),
  );
}

class StaticReceiptTemplateConfigClient implements ReceiptTemplateConfigClient {
  StaticReceiptTemplateConfigClient({required AiProcessingLevel level})
    : _level = level;

  final AiProcessingLevel _level;

  @override
  Future<String> loadTemplateId() async {
    return switch (_level) {
      AiProcessingLevel.minimal => _minimalReceiptTemplateId,
      AiProcessingLevel.low => _lowReceiptTemplateId,
      AiProcessingLevel.balanced => _balancedReceiptTemplateId,
      AiProcessingLevel.high => _highReceiptTemplateId,
    };
  }
}

class FirebaseReceiptTemplateModelClient implements ReceiptTemplateModelClient {
  FirebaseReceiptTemplateModelClient({required TemplateGenerativeModel model})
    : _model = model;

  final TemplateGenerativeModel _model;

  @override
  Future<String?> generateContent({
    required String templateId,
    required Map<String, Object?> inputs,
  }) async {
    final response = await _model.generateContent(templateId, inputs: inputs);
    return response.text;
  }
}
