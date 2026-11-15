import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_shared_text.g.dart';

/// Text that another app shared with yamt and that no page took yet.
@Riverpod(keepAlive: true)
class PendingSharedText extends _$PendingSharedText {
  @override
  String? build() => null;

  /// Holds [text] until a page takes it; empty text is left out.
  void put(String text) {
    if (text.trim().isNotEmpty) {
      state = text;
    }
  }

  /// Returns the held text and forgets it.
  String? take() {
    final text = state;
    state = null;
    return text;
  }
}
