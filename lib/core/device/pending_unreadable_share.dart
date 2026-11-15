import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_unreadable_share.g.dart';

/// Whether another app shared something with yamt that we could not read and
/// no page told the user yet.
@Riverpod(keepAlive: true)
class PendingUnreadableShare extends _$PendingUnreadableShare {
  @override
  bool build() => false;

  /// Holds the signal until a page takes it.
  void raise() => state = true;

  /// Returns whether the signal was held and forgets it.
  bool take() {
    final held = state;
    state = false;
    return held;
  }
}
