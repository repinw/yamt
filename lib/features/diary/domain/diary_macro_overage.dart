/// Share of [current] that exceeds the macro [target], between 0 and 1.
///
/// Macro bars stripe this share at their end to mark eating beyond the goal.
double diaryMacroOverageShare({
  required double current,
  required double target,
}) {
  if (target <= 0 || current - target <= 0.5) {
    return 0;
  }
  return (current - target) / current;
}
