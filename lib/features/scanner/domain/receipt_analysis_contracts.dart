// Contracts stay class-based for provider overrides and test fakes.
// ignore_for_file: one_member_abstracts

import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

/// Reads a picked receipt input and returns the analysis output.
abstract interface class ReceiptAnalysisRepository {
  /// Analyze selection.
  Future<ReceiptAnalysisResult> analyzeSelection(
    ReceiptInputSelection selection,
  );
}

/// Executes a Firebase AI template and returns generated text.
abstract interface class ReceiptTemplateModelClient {
  /// Generate content.
  Future<String?> generateContent({
    required String templateId,
    required Map<String, Object?> inputs,
  });
}
