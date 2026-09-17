import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/scanner/data/receipt_gateway_providers.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';
import 'package:yamt/features/scanner/presentation/receipt_review_page.dart';
import 'package:yamt/features/scanner/presentation/shared/pending_shared_receipt_paths.dart';
import 'package:yamt/features/scanner/presentation/shared/shared_receipt_listener.dart';
import 'package:yamt/features/scanner/presentation/shared/shared_receipt_service.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../fakes/fake_receipt_product_resolver.dart';
import '../../fakes/fake_receipt_structured_parser.dart';
import '../../fakes/fake_receipt_text_extractor.dart';

class _FakeSharedReceiptService extends SharedReceiptService {
  @override
  Future<void> build() async {}
}

void main() {
  late FakeReceiptStructuredParser fakeParser;
  late FakeReceiptTextExtractor fakeExtractor;
  late FakeReceiptProductResolver fakeResolver;

  setUp(() {
    fakeParser = FakeReceiptStructuredParser();
    fakeExtractor = FakeReceiptTextExtractor();
    fakeResolver = FakeReceiptProductResolver();
  });

  GoRouter createRouter(GlobalKey<NavigatorState> navigatorKey) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: AppRoutes.root,
      routes: [
        GoRoute(
          path: AppRoutes.root,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('App Content'))),
        ),
        GoRoute(
          path: AppRoutes.homeInventoryReceiptReview,
          builder: (context, state) {
            final receipt = state.extra! as ScannedReceipt;
            return ReceiptReviewPage(initialReceipt: receipt);
          },
        ),
      ],
    );
  }

  group('SharedReceiptListener', () {
    Future<ProviderContainer> pumpHarness(
      WidgetTester tester, {
      VoidCallback? onReceiptSaved,
    }) async {
      final key = GlobalKey<NavigatorState>();
      final router = createRouter(key);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appRouterProvider.overrideWithValue(router),
            navigatorKeyProvider.overrideWithValue(key),
            sharedReceiptServiceProvider.overrideWith(
              _FakeSharedReceiptService.new,
            ),
            receiptStructuredParserProvider.overrideWithValue(fakeParser),
            receiptTextExtractorProvider.overrideWithValue(fakeExtractor),
            receiptProductResolverProvider.overrideWithValue(fakeResolver),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            builder: (context, child) => SharedReceiptListener(
              onReceiptSaved: onReceiptSaved,
              child: child ?? const SizedBox.shrink(),
            ),
            locale: const Locale('de'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(SharedReceiptListener));
      return ProviderScope.containerOf(element);
    }

    testWidgets('renders child content', (tester) async {
      await pumpHarness(tester);
      expect(find.text('App Content'), findsOneWidget);
    });

    testWidgets(
      'shows confirmation dialog when paths arrive and cancels cleanly',
      (tester) async {
        final container = await pumpHarness(tester);

        container.read(pendingSharedReceiptPathsProvider.notifier).setPaths([
          '/tmp/receipt.pdf',
        ]);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Geteilten Beleg scannen?'), findsOneWidget);

        await tester.tap(find.text('Abbrechen'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(container.read(pendingSharedReceiptPathsProvider), isNull);
      },
    );

    testWidgets('confirms dialog and launches scan flow', (tester) async {
      fakeParser.nextReceipt = const ScannedReceipt(
        id: 'shared-1',
        storeName: 'KAUFLAND',
        items: [ReceiptLineItem(id: '1', rawName: 'TEE', totalPrice: 0.99)],
      );

      var onReceiptSavedCalled = false;
      final container = await pumpHarness(
        tester,
        onReceiptSaved: () => onReceiptSavedCalled = true,
      );

      container.read(pendingSharedReceiptPathsProvider.notifier).setPaths([
        '/tmp/shared.pdf',
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Scannen'), findsOneWidget);
      await tester.tap(find.text('Scannen'));
      await tester.pumpAndSettle();

      expect(container.read(pendingSharedReceiptPathsProvider), isNull);
      expect(find.text('Beleg prüfen'), findsOneWidget);
      expect(find.text('KAUFLAND'), findsOneWidget);
      expect(onReceiptSavedCalled, isFalse);
    });
  });
}
