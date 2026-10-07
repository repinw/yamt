/// Result of completing a hub product result.
class ProductSearchHubCompletionResult {
  const new _({
    required this.shouldCloseHub,
    this.saved = false,
    this.wasCanceled = false,
  });

  /// No user-visible completion action.
  const new none() : this._(shouldCloseHub: false);

  /// The user canceled the follow-up dialog.
  const new canceled() : this._(shouldCloseHub: false, wasCanceled: true);

  /// Close the hub after a direct save; [saved] when the food was saved
  /// rather than planned.
  const new closeHub({bool saved = false})
    : this._(shouldCloseHub: true, saved: saved);

  /// Whether hub should close after completion.
  final bool shouldCloseHub;

  /// Whether the food was saved, to the Vorrat or with a diary entry.
  final bool saved;

  /// Whether the user canceled the follow-up dialog.
  final bool wasCanceled;
}
