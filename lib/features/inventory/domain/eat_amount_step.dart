const _steps = [1, 5, 10, 25, 50, 100, 250, 500, 1000];
const _maxStops = 60;

/// Step of the amount ruler for amounts from 0 to [max]: the smallest round
/// step that keeps the ruler at 60 stops or fewer.
int eatAmountStep(num max) {
  for (final step in _steps) {
    if (max / step <= _maxStops) {
      return step;
    }
  }
  return _steps.last;
}
