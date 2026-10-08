import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/household/application/household_scoped_list_feed.dart';

final _source = StreamController<List<int>>.broadcast();
final _seen = <List<int>>[];

class _Controller extends AsyncNotifier<List<int>> {
  late final feed = HouseholdScopedListFeed<int>(
    ref: () => ref,
    watch: () => _source.stream,
    setState: (next) => state = next,
    logName: 'test',
    recoveryMessage: 'test',
    onList: _seen.add,
  );

  @override
  Future<List<int>> build() {
    ref.onDispose(() => unawaited(feed.close()));
    return feed.start();
  }
}

final _provider = AsyncNotifierProvider<_Controller, List<int>>(
  _Controller.new,
);

void main() {
  late ProviderContainer container;

  setUp(() {
    _seen.clear();
    container = ProviderContainer()..listen(_provider, (_, _) {});
  });

  tearDown(() => container.dispose());

  Future<void> emit(List<int> items) async {
    _source.add(items);
    await pumpEventQueue();
  }

  test('the first list builds the state and later lists follow', () async {
    await emit(<int>[1]);
    expect(await container.read(_provider.future), <int>[1]);

    await emit(<int>[1, 2]);

    expect(container.read(_provider).value, <int>[1, 2]);
    expect(container.read(_provider.notifier).feed.items, <int>[1, 2]);
    expect(_seen, <List<int>>[
      <int>[1],
      <int>[1, 2],
    ]);
  });

  test('an error after the first list shows as the state', () async {
    await emit(<int>[1]);
    await container.read(_provider.future);

    _source.addError(StateError('watch failed'));
    await pumpEventQueue();

    expect(container.read(_provider).error, isA<StateError>());
  });

  test('a refresh starts a new generation with a new first list', () async {
    await emit(<int>[1]);
    await container.read(_provider.future);
    final feed = container.read(_provider.notifier).feed;
    final before = feed.generation;

    final refreshed = feed.refresh();
    await pumpEventQueue();
    await emit(<int>[3]);
    await refreshed;

    expect(feed.generation, before + 1);
    expect(container.read(_provider).value, <int>[3]);
  });

  test('publish shows a list the controller wrote', () async {
    await emit(<int>[1]);
    await container.read(_provider.future);

    container.read(_provider.notifier).feed.publish(<int>[1, 4]);

    expect(container.read(_provider).value, <int>[1, 4]);
  });
}
