import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/domain/shared_receipt_intent.dart';

part 'pending_shared_receipt_intent.g.dart';

/// Defines pending shared receipt intent.
@Riverpod(keepAlive: true)
class PendingSharedReceiptIntent extends _$PendingSharedReceiptIntent {
  @override
  SharedReceiptIntent? build() {
    return null;
  }

  /// Replace.
  void replace(List<ReceiptInputSelection> selections) {
    if (selections.isEmpty) {
      return;
    }

    state = SharedReceiptIntent(
      requestId: DateTime.now().microsecondsSinceEpoch,
      selections: List.unmodifiable(selections),
    );
  }

  /// Consume.
  void consume(int requestId) {
    if (state?.requestId != requestId) {
      return;
    }
    state = null;
  }
}
