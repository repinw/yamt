import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';

part 'cook_run_providers.g.dart';

/// Watches the cook runs of the household, newest first.
@riverpod
Stream<List<CookRun>> cookRuns(Ref ref) {
  return ref
      .watch(cookRunRepositoryProvider)
      .watchAll()
      .map((runs) => runs.sortedByCompare((run) => run.startedAt, _newest));
}

/// The cook run [id], `null` while it does not exist.
@riverpod
Future<CookRun?> cookRun(Ref ref, String id) async {
  final runs = await ref.watch(cookRunsProvider.future);
  return runs.firstWhereOrNull((run) => run.id == id);
}

/// The cook run of the recipe [recipeId], `null` while none runs.
@riverpod
Future<CookRun?> recipeCookRun(Ref ref, String recipeId) async {
  final runs = await ref.watch(cookRunsProvider.future);
  return runs.firstWhereOrNull((run) => run.recipeId == recipeId);
}

/// What all cook runs together take from each Vorrat item, by item id.
/// The open run counts here too: the cooking page sums the other runs
/// itself with `reservationsOf` over [cookRuns] without its own id.
@riverpod
Stream<Map<String, int>> cookRunReservations(Ref ref) {
  return ref
      .watch(cookRunRepositoryProvider)
      .watchAll()
      .map(reservationsOf)
      .distinct(const MapEquality<String, int>().equals);
}

int _newest(DateTime a, DateTime b) => b.compareTo(a);
