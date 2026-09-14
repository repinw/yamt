import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_shared_receipt_paths.g.dart';

/// Holds pending shared receipt file paths waiting to be confirmed
/// and processed.
@Riverpod(keepAlive: true)
class PendingSharedReceiptPaths extends _$PendingSharedReceiptPaths {
  @override
  List<String>? build() => null;

  /// Sets pending file paths for incoming shared receipt.
  void setPaths(List<String> paths) {
    final valid = paths
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    if (valid.isEmpty) return;
    state = valid;
  }

  /// Consumes and clears the pending shared receipt paths.
  void consume() {
    state = null;
  }
}
