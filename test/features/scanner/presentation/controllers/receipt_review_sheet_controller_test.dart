import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/global_food_item_matcher.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/presentation/controllers/'
    'receipt_review_sheet_controller.dart';

void main() {
  test('resolveCandidatesLazily limits candidate lookups to three', () async {
    final matcher = _BlockingGlobalFoodItemMatcher();
    final items = [
      for (var index = 0; index < 5; index++) _draft('item-$index'),
    ];
    final harness = _controllerHarness(items: items, matcher: matcher);
    addTearDown(harness.dispose);

    final future = harness.controller.resolveCandidatesLazily();
    await _waitUntil(() => matcher.startedItemIds.length == 3);

    expect(matcher.maxActiveLookups, 3);
    expect(matcher.startedItemIds, ['item-0', 'item-1', 'item-2']);

    matcher
      ..complete('item-0')
      ..complete('item-1')
      ..complete('item-2');
    await _waitUntil(() => matcher.startedItemIds.length == 5);

    expect(matcher.maxActiveLookups, 3);
    matcher
      ..complete('item-3')
      ..complete('item-4');
    await future;

    expect(matcher.completedItemIds, [
      'item-0',
      'item-1',
      'item-2',
      'item-3',
      'item-4',
    ]);
  });

  test('pending lookup does not overwrite changed lookup input', () async {
    final matcher = _BlockingGlobalFoodItemMatcher();
    final harness = _controllerHarness(
      items: [_draft('item-1', name: 'Milk')],
      matcher: matcher,
    );
    addTearDown(harness.dispose);

    final future = harness.controller.prepareDraftForCandidateSelection(
      'item-1',
    );
    await _waitUntil(() => matcher.startedItemIds.contains('item-1'));

    harness.controller.applyEditedItem(
      'item-1',
      _item(id: 'item-1', name: 'Bread'),
    );
    matcher.complete('item-1');
    await future;

    final draft = harness.container.read(harness.provider).items.single;
    expect(draft.item.name, 'Bread');
    expect(draft.candidates, isEmpty);
    expect(draft.selectedGlobalFoodItemId, isNull);
  });

  test('pending lookup completes safely after controller disposal', () async {
    final matcher = _BlockingGlobalFoodItemMatcher();
    final harness = _controllerHarness(
      items: [_draft('item-1')],
      matcher: matcher,
    );

    final future = harness.controller.prepareDraftForCandidateSelection(
      'item-1',
    );
    await _waitUntil(() => matcher.startedItemIds.contains('item-1'));

    harness.dispose();
    matcher.complete('item-1');

    await expectLater(future, completion(isNull));
  });

  test('toggleItemConfirmed returns next pending item and wraps around', () {
    final harness = _controllerHarness(
      items: [
        _draft('item-1'),
        _draft('item-2'),
        _draft('item-3'),
      ],
      matcher: _BlockingGlobalFoodItemMatcher(),
    );
    addTearDown(harness.dispose);

    final nextItemId = harness.controller.toggleItemConfirmed('item-2');

    expect(nextItemId, 'item-3');
    expect(_draftFor(harness, 'item-2').isConfirmed, isTrue);

    final wrappedItemId = harness.controller.toggleItemConfirmed('item-3');

    expect(wrappedItemId, 'item-1');
    expect(_draftFor(harness, 'item-3').isConfirmed, isTrue);

    final unconfirmResult = harness.controller.toggleItemConfirmed('item-3');

    expect(unconfirmResult, isNull);
    expect(_draftFor(harness, 'item-3').isConfirmed, isFalse);
  });
}

_ControllerHarness _controllerHarness({
  required List<ReceiptReviewItemDraft> items,
  required GlobalFoodItemMatcher matcher,
}) {
  final provider = receiptReviewSheetControllerProvider(items);
  final container = ProviderContainer(
    overrides: [
      globalFoodItemMatcherProvider.overrideWithValue(matcher),
    ],
  );
  final subscription = container.listen(
    provider,
    (_, _) {},
    fireImmediately: true,
  );

  return _ControllerHarness(
    container: container,
    provider: provider,
    subscription: subscription,
  );
}

ReceiptReviewItemDraft _draftFor(
  _ControllerHarness harness,
  String itemId,
) {
  return harness.container
      .read(harness.provider)
      .items
      .singleWhere((draft) => draft.item.id == itemId);
}

ReceiptReviewItemDraft _draft(
  String id, {
  String? name,
}) {
  return ReceiptReviewItemDraft(
    item: _item(id: id, name: name ?? 'Item $id'),
  );
}

InventoryItem _item({
  required String id,
  required String name,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    weight: '100 g',
    amountUnit: InventoryAmountUnit.gram,
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 100,
    ),
  );
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (condition()) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
  }
  fail('Condition was not met.');
}

class _ControllerHarness {
  const _ControllerHarness({
    required this.container,
    required this.provider,
    required this.subscription,
  });

  final ProviderContainer container;
  final ReceiptReviewSheetControllerProvider provider;
  final ProviderSubscription<ReceiptReviewSheetState> subscription;

  ReceiptReviewSheetController get controller {
    return container.read(provider.notifier);
  }

  void dispose() {
    subscription.close();
    container.dispose();
  }
}

class _BlockingGlobalFoodItemMatcher extends GlobalFoodItemMatcher {
  _BlockingGlobalFoodItemMatcher() : super();

  final startedItemIds = <String>[];
  final completedItemIds = <String>[];
  final _completers = <String, Completer<List<GlobalFoodMatchCandidate>>>{};
  int _activeLookups = 0;
  int maxActiveLookups = 0;

  @override
  Future<List<GlobalFoodMatchCandidate>> findCandidates(
    InventoryItem item,
  ) {
    startedItemIds.add(item.id);
    _activeLookups++;
    maxActiveLookups = _activeLookups > maxActiveLookups
        ? _activeLookups
        : maxActiveLookups;

    final completer = Completer<List<GlobalFoodMatchCandidate>>();
    _completers[item.id] = completer;
    return completer.future.whenComplete(() {
      _activeLookups--;
      completedItemIds.add(item.id);
    });
  }

  void complete(String itemId) {
    final completer = _completers[itemId];
    if (completer == null || completer.isCompleted) {
      return;
    }
    completer.complete([_candidate(itemId)]);
  }
}

GlobalFoodMatchCandidate _candidate(String itemId) {
  return GlobalFoodMatchCandidate(
    item: GlobalFoodItem.create(
      id: 'global-$itemId',
      name: 'Resolved $itemId',
      now: DateTime.parse('2026-02-19T10:00:00Z'),
      packageWeight: '100 g',
      nutrition: const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Kcal: 100,
      ),
    ),
    score: 100,
    reason: GlobalFoodMatchReason.nameExact,
  );
}
