// ignore_for_file: experimental_member_use

import 'package:firebase_ai/firebase_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_contracts.dart';

part 'receipt_analysis_clients.g.dart';

const String _vertexLocation = 'global';
const Duration _templateRequestTimeout = Duration(seconds: 200);

@riverpod
ReceiptTemplateModelClient receiptTemplateModelClient(Ref ref) {
  return FirebaseReceiptTemplateModelClient(
    model: FirebaseAI.vertexAI(
      location: _vertexLocation,
    ).templateGenerativeModel(),
  );
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
    final response = await _model
        .generateContent(templateId, inputs: inputs)
        .timeout(_templateRequestTimeout);
    return response.text;
  }
}
