import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/app_version_config_repository.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_operations.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_renewal.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_open_count.dart';

import '../../support/fake_shopping_list_repository.dart';

const ShoppingListSourceItem _milk = (
  name: 'Milch',
  brand: null,
  initialQuantity: 1,
  unitPrice: 0.0,
);
const ShoppingListSourceItem _bread = (
  name: 'Brot',
  brand: null,
  initialQuantity: 1,
  unitPrice: 0.0,
);

/// A ticked-off recurring entry that comes back on [due].
ShoppingListItem _recurring(String name, DateTime due) => ShoppingListItem(
  id: name,
  name: name,
  normalizedName: name.toLowerCase(),
  normalizedBrand: '',
  quantity: 1,
  estimatedUnitPrice: 0,
  isDone: true,
  repeatEveryDays: 7,
  nextDueDate: due,
);

Future<void> _resume(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pump();
}

/// The time from [at] to the next local midnight: a calendar day, so 23 or
/// 25 hours across a clock change.
Duration _untilMidnight(DateTime at) =>
    DateTime(at.year, at.month, at.day + 1).difference(at);

/// Advances the fake clock by [by] and lets timers and streams run.
Future<void> _elapse(WidgetTester tester, Duration by) async {
  await tester.pump(by);
  await tester.pump();
  await tester.pump();
}

void main() {
  group('the list controller renews due entries by itself', () {
    late DateTime now;
    late ProviderContainer container;
    late FakeShoppingListRepository repository;

    Future<void> start(
      WidgetTester tester,
      List<ShoppingListItem> items,
    ) async {
      repository = FakeShoppingListRepository(initialItems: items);
      addTearDown(repository.dispose);
      container = ProviderContainer(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(repository),
          appUpdateStatusProvider.overrideWith((ref) => const Stream.empty()),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);
      // Like the home tabs, which watch the open count all the time.
      final count = container.listen(openShoppingListCountProvider, (_, _) {});
      addTearDown(count.close);
      final milk = container.listen(
        sourceItemInActiveShoppingListProvider(_milk),
        (_, _) {},
      );
      addTearDown(milk.close);
      await tester.pump();
      await tester.pump();
    }

    int? openCount() => container.read(openShoppingListCountProvider).value;

    bool milkListed() =>
        container.read(sourceItemInActiveShoppingListProvider(_milk));

    testWidgets('an entry due after midnight shows without the page', (
      tester,
    ) async {
      now = DateTime(2026, 11, 19, 23, 59);
      await start(tester, [_recurring('Milch', DateTime(2026, 11, 20))]);
      expect(openCount(), 0);
      expect(milkListed(), isFalse);

      now = DateTime(2026, 11, 20, 0, 0, 1);
      await _elapse(tester, const Duration(minutes: 1, seconds: 1));

      expect(openCount(), 1);
      expect(milkListed(), isTrue);
    });

    testWidgets('the day timer arms again after it fired', (tester) async {
      now = DateTime(2026, 11, 19, 23, 59);
      await start(tester, [
        _recurring('Milch', DateTime(2026, 11, 20)),
        _recurring('Brot', DateTime(2026, 11, 21)),
      ]);

      now = DateTime(2026, 11, 20, 0, 0, 1);
      await _elapse(tester, const Duration(minutes: 1, seconds: 1));
      expect(openCount(), 1);

      // One calendar day later, which is not 24 hours across a clock change.
      final nextDay = DateTime(2026, 11, 21, 0, 0, 1);
      final day = nextDay.difference(now);
      now = nextDay;
      await _elapse(tester, day);

      expect(openCount(), 2);
      expect(
        container.read(sourceItemInActiveShoppingListProvider(_bread)),
        isTrue,
      );
    });

    testWidgets('before midnight nothing is renewed', (tester) async {
      now = DateTime(2026, 11, 19, 23, 59);
      await start(tester, [_recurring('Milch', DateTime(2026, 11, 20))]);

      await _elapse(tester, const Duration(seconds: 30));

      expect(openCount(), 0);
    });

    testWidgets('an app resume renews a due entry', (tester) async {
      now = DateTime(2026, 11, 19, 12);
      await start(tester, [_recurring('Milch', DateTime(2026, 11, 20))]);
      expect(openCount(), 0);

      now = DateTime(2026, 11, 20, 8);
      await _resume(tester);
      await _elapse(tester, Duration.zero);

      expect(openCount(), 1);
      expect(milkListed(), isTrue);
    });

    testWidgets('a rebuilt controller keeps renewing at midnight', (
      tester,
    ) async {
      now = DateTime(2026, 11, 19, 23, 59);
      await start(tester, [_recurring('Milch', DateTime(2026, 11, 20))]);
      container.invalidate(shoppingListControllerProvider);
      await tester.pump();
      await tester.pump();

      now = DateTime(2026, 11, 20, 0, 0, 1);
      await _elapse(tester, const Duration(minutes: 1, seconds: 1));

      expect(openCount(), 1);
    });
  });

  group('ShoppingListRenewal', () {
    late DateTime Function() now;
    late int calls;
    late ShoppingListRenewal renewal;
    late ProviderContainer container;
    late Provider<int> probe;

    /// The clock starts at [start] and runs with the test's fake time.
    void open(WidgetTester tester, DateTime start) {
      final began = tester.binding.clock.now();
      now = () => start.add(tester.binding.clock.now().difference(began));
      container = ProviderContainer()..listen(probe, (_, _) {});
      // A failed test must not leave its timer and listener to the next one.
      addTearDown(container.dispose);
    }

    setUp(() {
      calls = 0;
      renewal = ShoppingListRenewal();
      probe = Provider<int>((ref) {
        renewal.start(ref, now: () => now(), onMayBeDue: () => calls++);
        return 0;
      });
    });

    testWidgets('the timer fires at midnight and re-arms every day', (
      tester,
    ) async {
      open(tester, DateTime(2026, 11, 19, 23));

      await tester.pump(const Duration(minutes: 59));
      expect(calls, 0);
      await tester.pump(const Duration(minutes: 1));
      expect(calls, 1);
      await tester.pump(_untilMidnight(now()));
      expect(calls, 2);
      await tester.pump(_untilMidnight(now()));
      expect(calls, 3);
      container.dispose();
    });

    testWidgets('an app resume calls back', (tester) async {
      open(tester, DateTime(2026, 11, 19, 12));

      await _resume(tester);

      expect(calls, 1);
      container.dispose();
    });

    testWidgets('a rebuild leaves one timer and one listener', (tester) async {
      open(tester, DateTime(2026, 11, 19, 23));
      container
        ..invalidate(probe)
        ..read(probe)
        ..invalidate(probe)
        ..read(probe);

      await _resume(tester);
      expect(calls, 1);

      calls = 0;
      await tester.pump(const Duration(hours: 1));
      expect(calls, 1);
      container.dispose();
    });

    testWidgets('dispose cancels the timer and the listener', (tester) async {
      open(tester, DateTime(2026, 11, 19, 23));
      container.dispose();

      await _resume(tester);
      await tester.pump(const Duration(days: 3));

      expect(calls, 0);
    });
  });
}
