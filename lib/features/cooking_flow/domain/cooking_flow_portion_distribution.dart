/// Splits [totalPortions] over storage containers in proportion to their
/// [netWeights].
///
/// Every container gets at least one portion. The result sums to
/// [totalPortions], or to the container count when there are more containers
/// than portions. Rounding uses the largest remainder, so the container with
/// the biggest leftover share gets the next portion. Containers without a
/// positive weight count as equal when no container has one.
List<int> distributeCookingFlowPortions({
  required int totalPortions,
  required List<int> netWeights,
}) {
  final count = netWeights.length;
  if (count == 0) {
    return const <int>[];
  }
  final total = totalPortions < count ? count : totalPortions;
  final weights = netWeights.map((weight) => weight < 0 ? 0 : weight).toList();
  final weightSum = weights.fold<int>(0, (sum, weight) => sum + weight);
  final quotas = weights
      .map(
        (weight) => weightSum == 0 ? total / count : total * weight / weightSum,
      )
      .toList();
  final portions = quotas
      .map((quota) => quota.floor() < 1 ? 1 : quota.floor())
      .toList();
  var assigned = portions.fold<int>(0, (sum, value) => sum + value);

  final byRemainder = List<int>.generate(count, (index) => index)
    ..sort((a, b) {
      final remainderA = quotas[a] - quotas[a].floor();
      final remainderB = quotas[b] - quotas[b].floor();
      final order = remainderB.compareTo(remainderA);
      return order != 0 ? order : a.compareTo(b);
    });
  for (var step = 0; assigned < total; step++) {
    portions[byRemainder[step % count]]++;
    assigned++;
  }

  // Minimum portions can overshoot the total; take the surplus back from the
  // containers that sit furthest above their share.
  while (assigned > total) {
    var donor = -1;
    for (var index = 0; index < count; index++) {
      if (portions[index] <= 1) {
        continue;
      }
      if (donor < 0 ||
          portions[index] - quotas[index] > portions[donor] - quotas[donor]) {
        donor = index;
      }
    }
    portions[donor]--;
    assigned--;
  }
  return portions;
}
