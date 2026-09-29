/// Picks the action that the user taps most often among [ids].
///
/// [counts] maps an action id to how often it was tapped. Returns `null` when
/// no action in [ids] was tapped yet. A tie goes to the action that comes
/// first in [ids].
String? mostUsedAction(Map<String, int> counts, Iterable<String> ids) {
  String? best;
  var bestCount = 0;
  for (final id in ids) {
    final count = counts[id] ?? 0;
    if (count > bestCount) {
      best = id;
      bestCount = count;
    }
  }
  return best;
}
