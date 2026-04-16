import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

/// Defines shared receipt intent.
class SharedReceiptIntent {
  /// The shared receipt intent.
  const SharedReceiptIntent({
    required this.requestId,
    required this.selections,
  });

  /// The request id.
  final int requestId;

  /// The selections.
  final List<ReceiptInputSelection> selections;

  /// Whether batch.
  bool get isBatch => selections.length > 1;
}
