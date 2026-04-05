import 'package:yamt/features/scanner/domain/receipt_input_models.dart';

class SharedReceiptIntent {
  const SharedReceiptIntent({
    required this.requestId,
    required this.selections,
  });

  final int requestId;
  final List<ReceiptInputSelection> selections;

  bool get isBatch => selections.length > 1;
}
