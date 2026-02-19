import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/domain/receipt_analysis_models.dart';
import 'package:yamt/features/inventory/domain/receipt_input_models.dart';

part 'receipt_analysis_repository.g.dart';

@riverpod
ReceiptAnalysisRepository receiptAnalysisRepository(Ref ref) {
  return const PendingReceiptAnalysisRepository();
}

/// Reads a picked receipt input and returns the analysis output.
abstract interface class ReceiptAnalysisRepository {
  Future<ReceiptAnalysisResult> analyzeSelection(
    ReceiptInputSelection selection,
  );
}

/// Temporary implementation for step-wise AI rollout.
///
/// The next increment replaces this with the Firebase AI-backed repository.
class PendingReceiptAnalysisRepository implements ReceiptAnalysisRepository {
  const PendingReceiptAnalysisRepository();

  @override
  Future<ReceiptAnalysisResult> analyzeSelection(
    ReceiptInputSelection selection,
  ) {
    return Future<ReceiptAnalysisResult>.value(
      const ReceiptAnalysisResult.failed(
        errorCode: ReceiptAnalysisErrorCodes.notImplemented,
      ),
    );
  }
}
