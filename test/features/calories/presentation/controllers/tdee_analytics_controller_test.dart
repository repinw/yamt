import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_time_range.dart';
import 'package:yamt/features/calories/presentation/controllers/tdee_analytics_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(tdeeAnalyticsControllerProvider, (_, _) {});
  });

  TdeeAnalyticsController notifier() =>
      container.read(tdeeAnalyticsControllerProvider.notifier);
  Set<String> selected() =>
      container.read(tdeeAnalyticsControllerProvider).selectedCycleIds;

  test('starts with every goal selected', () {
    expect(selected(), <String>{'all'});
  });

  test('picking a cycle while all is selected replaces the selection', () {
    notifier().toggleCycle('a');

    expect(selected(), <String>{'a'});
  });

  test('toggling adds and removes cycles from the selection', () {
    notifier()
      ..toggleCycle('a')
      ..toggleCycle('b');
    expect(selected(), <String>{'a', 'b'});

    notifier().toggleCycle('a');
    expect(selected(), <String>{'b'});
  });

  test('removing the last cycle falls back to all goals', () {
    notifier()
      ..toggleCycle('a')
      ..toggleCycle('a');

    expect(selected(), <String>{'all'});
  });

  test('picking all replaces a multi selection', () {
    notifier()
      ..toggleCycle('a')
      ..toggleCycle('b')
      ..toggleCycle('all');

    expect(selected(), <String>{'all'});
  });

  test('selectCycles can switch to the full time range', () {
    notifier().selectCycles(<String>{'a'}, showFullRange: true);

    final state = container.read(tdeeAnalyticsControllerProvider);
    expect(state.selectedCycleIds, <String>{'a'});
    expect(state.timeRange, TdeeAnalyticsTimeRange.all);
  });
}
