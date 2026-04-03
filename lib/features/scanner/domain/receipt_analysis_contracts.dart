import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

/// Reads a picked receipt input and returns the analysis output.
abstract interface class ReceiptAnalysisRepository {
  Future<ReceiptAnalysisResult> analyzeSelection(
    ReceiptInputSelection selection,
  );
}

/// Executes a Firebase AI template and returns generated text.
abstract interface class ReceiptTemplateModelClient {
  Future<String?> generateContent({
    required String templateId,
    required Map<String, Object?> inputs,
  });
}
