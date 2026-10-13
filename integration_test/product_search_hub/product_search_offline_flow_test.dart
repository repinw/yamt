import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/network_connectivity.dart';
import 'package:yamt/core/widgets/offline_banner.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/data/'
    'composite_product_search_adapter.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_barcode_lookup_candidate.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_gateway.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_search_results/product_search_hub_search_results.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/fake_connectivity.dart';

const _barcode = '4008400404127';
const _searchFieldKey = Key('product_search_hub_search_field');
const _resultKey = Key('product_search_hub_search_result_$_barcode');

/// Finds the scanned product only online, like the real search, whose
/// sources give nothing offline. Answers after a real async gap.
class _Gateway implements ProductSearchGateway {
  bool online = false;

  @override
  Future<ProductSearchHubSearchLookupResult> search({
    required String query,
    required int limit,
    String? store,
    String? brand,
    String? weight,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return ProductSearchHubSearchLookupResult.success(
      online
          ? const [
              OffProductSearchResult(
                code: _barcode,
                name: 'Kinder Schokolade',
                brand: 'Ferrero',
                score: 1,
              ),
            ]
          : const <OffProductSearchResult>[],
    );
  }

  @override
  Future<List<InventoryBarcodeLookupCandidate>> resolveBarcodeCandidates({
    required String barcode,
  }) async => const [];

  @override
  Future<List<InventoryItem>> readRecentItems() async => const [];
}

Future<void> _pumpVisibleStep(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('offline the app says so and the search names the missing '
      'connection; back online it searches again', (tester) async {
    final connectivity = FakeConnectivity(offline: true);
    addTearDown(connectivity.dispose);
    final gateway = _Gateway();
    final container = ProviderContainer(
      overrides: [
        connectivityProvider.overrideWithValue(connectivity),
        productSearchGatewayProvider.overrideWithValue(gateway),
      ],
    );
    addTearDown(container.dispose);

    // Wrapped like the app wraps every page.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => OfflineBanner(child: child!),
          home: const ProductSearchHubPage(),
        ),
      ),
    );
    await _pumpVisibleStep(tester);

    expect(find.byKey(OfflineBanner.stripKey), findsOneWidget);

    // A scanned barcode lands in the search field.
    await tester.enterText(find.byKey(_searchFieldKey), _barcode);
    await _pumpVisibleStep(tester);

    expect(
      find.byKey(ProductSearchHubSearchResults.offlineStateKey),
      findsOneWidget,
    );
    expect(
      find.byKey(ProductSearchHubSearchResults.emptyStateKey),
      findsNothing,
    );

    gateway.online = true;
    connectivity.goOnline();
    await tester.pump(connectivitySettleDelay);
    await _pumpVisibleStep(tester);

    expect(find.byKey(OfflineBanner.stripKey), findsNothing);
    expect(find.byKey(OfflineBanner.backOnlineKey), findsOneWidget);
    expect(find.byKey(_resultKey), findsOneWidget);
    expect(
      find.byKey(ProductSearchHubSearchResults.offlineStateKey),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
