import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/features/household/application/household_data_scope.dart';
import 'package:yamt/features/recipes/application/cook_run_providers.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';

import '../cook_run_fixtures.dart';

void main() {
  late CookRunRepository repo;
  late FakeFirebaseFirestore firestore;
  late ProviderContainer container;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    final scope = (
      householdId: 'h1',
      firestore: firestore,
      cipher: PayloadCipher(await PayloadCipher.newDataKey()),
    );
    repo = CookRunRepository(scope: scope);
    container = ProviderContainer(
      overrides: [householdDataScopeProvider.overrideWithValue(scope)],
    );
    addTearDown(container.dispose);
  });

  Future<void> removeRun(String id) => firestore
      .collection('households')
      .doc('h1')
      .collection('cook_runs')
      .doc(id)
      .delete();

  Future<void> pump() async {
    await repo.pending;
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('cookRuns sorts the newest start first', () async {
    final base = cookRunStart;
    await repo.create(buildCookRun(id: 'old', startedAt: base));
    await repo.create(
      buildCookRun(id: 'new', startedAt: base.add(const Duration(hours: 2))),
    );
    await repo.create(
      buildCookRun(id: 'mid', startedAt: base.add(const Duration(hours: 1))),
    );
    await pump();

    addTearDown(container.listen(cookRunsProvider, (_, _) {}).close);
    final runs = await container.read(cookRunsProvider.future);

    expect(runs.map((r) => r.id), ['new', 'mid', 'old']);
  });

  test('cookRun finds one run or null', () async {
    await repo.create(buildCookRun(id: 'a'));
    await pump();

    addTearDown(container.listen(cookRunProvider('a'), (_, _) {}).close);
    addTearDown(container.listen(cookRunProvider('zz'), (_, _) {}).close);
    expect((await container.read(cookRunProvider('a').future))!.id, 'a');
    expect(await container.read(cookRunProvider('zz').future), isNull);
  });

  test('recipeCookRun follows the run of the recipe', () async {
    final provider = recipeCookRunProvider('t1');
    addTearDown(container.listen(provider, (_, _) {}).close);

    expect(await container.read(provider.future), isNull);

    await repo.create(buildCookRun());
    await pump();
    expect(container.read(provider).value?.id, 'recipe-t1');

    await removeRun('recipe-t1');
    await pump();
    expect(container.read(provider).value, isNull);
  });

  test('cookRunReservations sums takes and skips equal maps', () async {
    final run = buildCookRun().withTakes('line-0', [
      const ItemTake(itemId: 'i', amount: 100),
    ]);
    await repo.create(run);
    await pump();
    final seen = <Map<String, int>>[];
    final subscription = container.listen(
      cookRunReservationsProvider,
      (_, next) => next.whenData(seen.add),
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await pump();
    expect(seen, [
      {'i': 100},
    ]);

    // The run changes but not what it takes: no new emission.
    await repo.mutate(run.id, (r) => r.copyWith(portions: 7));
    await pump();
    expect(seen, hasLength(1));

    // Taking more emits the new sums.
    await repo.mutate(
      run.id,
      (r) => r.withTakes('line-1', [const ItemTake(itemId: 'i', amount: 50)]),
    );
    await pump();
    expect(seen.last, {'i': 150});

    // Ending the run emits an empty map.
    await removeRun(run.id);
    await pump();
    expect(seen.last, isEmpty);
  });
}
