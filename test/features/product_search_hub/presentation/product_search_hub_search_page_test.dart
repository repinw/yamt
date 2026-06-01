import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'models/product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_lookup.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_search_results/product_search_hub_search_results.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _buildHarness({
  List<OffProductSearchResult> searchResults = const <OffProductSearchResult>[],
  ProductSearchHubRouteArgs args = const ProductSearchHubRouteArgs.inventory(),
  ProductSearchHubSearchLookup? lookupProducts,
}) {
  return ProviderScope(
    overrides: [
      voiceSearchServiceProvider.overrideWithValue(_FakeVoiceSearchService()),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ProductSearchHubSearchPage(
        args: args,
        lookupProducts:
            lookupProducts ??
            ({
              required query,
              required limit,
              store,
              weight,
            }) async {
              return ProductSearchHubSearchLookupResult.success(
                List<OffProductSearchResult>.from(searchResults.take(limit)),
              );
            },
      ),
    ),
  );
}

void main() {
  testWidgets('focused search lists matching products', (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        searchResults: const [
          OffProductSearchResult(
            code: 'search-milk',
            name: 'Whole milk',
            brand: 'Dairy Co',
            score: 1,
            packageWeight: '1 l',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await _pumpFocusedSearchReady(tester);

    await tester.enterText(
      find.byKey(const Key('product_search_hub_search_field')),
      'Milk',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('product_search_hub_search_result_search-milk')),
      findsOneWidget,
    );
    expect(find.text('Whole milk'), findsOneWidget);
    expect(find.text('Dairy Co'), findsOneWidget);
  });

  testWidgets('focused search passes route search context to lookup', (
    tester,
  ) async {
    String? capturedStore;
    String? capturedWeight;

    await tester.pumpWidget(
      _buildHarness(
        args: ProductSearchHubRouteArgs.inventory(
          item: _item(storeName: 'Aldi Nord', weight: '500 g'),
        ),
        lookupProducts:
            ({required query, required limit, store, weight}) async {
              capturedStore = store;
              capturedWeight = weight;
              return ProductSearchHubSearchLookupResult.success(
                const <OffProductSearchResult>[],
              );
            },
      ),
    );
    await tester.pumpAndSettle();
    await _pumpFocusedSearchReady(tester);

    await tester.enterText(
      find.byKey(const Key('product_search_hub_search_field')),
      'Milk',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(capturedStore, 'Aldi');
    expect(capturedWeight, '500 g');
  });

  testWidgets('focused search starts with route item query', (tester) async {
    String? capturedQuery;

    await tester.pumpWidget(
      _buildHarness(
        args: ProductSearchHubRouteArgs.inventory(
          item: _item(
            name: 'Whole milk',
            brand: 'Dairy Co',
            storeName: 'Aldi Nord',
            weight: '500 g',
          ),
        ),
        lookupProducts:
            ({required query, required limit, store, weight}) async {
              capturedQuery = query;
              return ProductSearchHubSearchLookupResult.success(
                const <OffProductSearchResult>[
                  OffProductSearchResult(
                    code: 'initial-milk',
                    name: 'Whole milk',
                    brand: 'Dairy Co',
                    score: 1,
                  ),
                ],
              );
            },
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(capturedQuery, 'Whole milk Dairy Co Aldi Nord');
    expect(
      find.byKey(const Key('product_search_hub_search_result_initial-milk')),
      findsOneWidget,
    );
  });

  testWidgets('focused search ignores stale lookup results', (tester) async {
    final firstLookup = Completer<ProductSearchHubSearchLookupResult>();
    final queries = <String>[];

    await tester.pumpWidget(
      _buildHarness(
        lookupProducts:
            ({required query, required limit, store, weight}) async {
              queries.add(query);
              if (query == 'Milk') {
                return firstLookup.future;
              }
              return ProductSearchHubSearchLookupResult.success(
                const <OffProductSearchResult>[
                  OffProductSearchResult(
                    code: 'bread',
                    name: 'Bread',
                    score: 1,
                  ),
                ],
              );
            },
      ),
    );
    await tester.pumpAndSettle();
    await _pumpFocusedSearchReady(tester);

    await tester.enterText(
      find.byKey(const Key('product_search_hub_search_field')),
      'Milk',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('product_search_hub_search_field')),
      'Bread',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    firstLookup.complete(
      ProductSearchHubSearchLookupResult.success(
        const <OffProductSearchResult>[
          OffProductSearchResult(code: 'milk', name: 'Milk', score: 1),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(queries, const <String>['Milk', 'Bread']);
    expect(
      find.byKey(const Key('product_search_hub_search_result_bread')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('product_search_hub_search_result_milk')),
      findsNothing,
    );
  });

  testWidgets('focused search field can be edited and cleared', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();
    await _pumpFocusedSearchReady(tester);

    await tester.enterText(
      find.byKey(const Key('product_search_hub_search_field')),
      'Milk',
    );
    await tester.pump();

    expect(find.text('Milk'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('product_search_hub_search_clear_button')),
    );
    await tester.pump();

    final field = tester.widget<TextField>(
      find.byKey(const Key('product_search_hub_search_field')),
    );
    expect(field.controller?.text, isEmpty);
  });

  testWidgets('focused search renders AI and create actions only', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();
    await _pumpFocusedSearchReady(tester);

    expect(
      find.byKey(const Key('product_search_hub_search_ai_action')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('product_search_hub_search_create_own_action')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('product_search_hub_barcode_action')),
      findsNothing,
    );
    _expectOutlinedActionEnabled(
      tester,
      const Key('product_search_hub_search_ai_action'),
    );
    _expectOutlinedActionEnabled(
      tester,
      const Key('product_search_hub_search_create_own_action'),
    );
  });

  testWidgets('empty search create button invokes create action', (
    tester,
  ) async {
    var didCreate = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProductSearchHubSearchResults(
            results: const <OffProductSearchResult>[],
            isSearching: false,
            hasFailed: false,
            onRetry: () {},
            onCreateOwnPressed: () {
              didCreate = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const Key('product_search_hub_search_create_product_button')),
    );

    expect(didCreate, isTrue);
  });
}

Future<void> _pumpFocusedSearchReady(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

void _expectOutlinedActionEnabled(WidgetTester tester, Key actionKey) {
  final buttonFinder = find.descendant(
    of: find.byKey(actionKey),
    matching: find.byType(OutlinedButton),
  );
  expect(buttonFinder, findsOneWidget);
  final button = tester.widget<OutlinedButton>(buttonFinder);
  expect(button.onPressed, isNotNull);
}

InventoryItem _item({
  required String storeName,
  required String weight,
  String name = 'Milk',
  String? brand,
}) {
  return InventoryItem.create(
    id: 'item',
    name: name,
    entryDate: DateTime.utc(2026, 6),
    storeName: storeName,
    quantity: 1,
    weight: weight,
    brand: brand,
  );
}

class _FakeVoiceSearchService implements VoiceSearchService {
  @override
  bool get isListening => false;

  @override
  Future<void> cancelListening() async {}

  @override
  Future<VoiceSearchFailure?> startListening({
    required ValueChanged<VoiceSearchRecognition> onResult,
    required ValueChanged<bool> onListeningStateChanged,
    required ValueChanged<VoiceSearchFailure> onError,
  }) async {
    return VoiceSearchFailure.unavailable;
  }

  @override
  Future<void> stopListening() async {}
}
