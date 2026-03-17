import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/presentation/'
    'inventory_receipt_review_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

InventoryItem _item({
  required String id,
  bool isDeposit = false,
  bool isDiscount = false,
}) {
  return InventoryItem.create(
    id: id,
    name: 'Item $id',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    unitPrice: 1,
    isDeposit: isDeposit,
    isDiscount: isDiscount,
  );
}

Widget _buildHarness({required InventoryReceiptReviewPageArgs args}) {
  final router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => _ReviewLauncher(args: args),
      ),
      GoRoute(
        path: AppRoutes.homeInventoryReceiptReview,
        builder: (context, state) {
          final args = state.extra! as InventoryReceiptReviewPageArgs;
          return InventoryReceiptReviewPage(args: args);
        },
      ),
    ],
  );

  return MaterialApp.router(
    locale: const Locale('en'),
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

class _ReviewLauncher extends StatefulWidget {
  const _ReviewLauncher({required this.args});

  final InventoryReceiptReviewPageArgs args;

  @override
  State<_ReviewLauncher> createState() => _ReviewLauncherState();
}

class _ReviewLauncherState extends State<_ReviewLauncher> {
  bool? _result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('result:${_result?.toString() ?? 'none'}'),
          FilledButton(
            key: const Key('open_review_page'),
            onPressed: () async {
              final result = await context.push<bool>(
                AppRoutes.homeInventoryReceiptReview,
                extra: widget.args,
              );
              if (!mounted) {
                return;
              }
              setState(() {
                _result = result;
              });
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('system back closes review page with false result', (
    tester,
  ) async {
    var saveCallCount = 0;

    await tester.pumpWidget(
      _buildHarness(
        args: InventoryReceiptReviewPageArgs(
          items: <ReceiptReviewItemDraft>[
            ReceiptReviewItemDraft(item: _item(id: 'item-1')),
          ],
          onSaveTap: (_) async {
            saveCallCount += 1;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_review_page')));
    await tester.pumpAndSettle();

    expect(find.byType(InventoryReceiptReviewPage), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(InventoryReceiptReviewPage), findsNothing);
    expect(find.text('result:false'), findsOneWidget);
    expect(saveCallCount, 0);
  });

  testWidgets('save calls onSaveTap and closes with true result', (
    tester,
  ) async {
    List<ReceiptReviewItemDraft>? savedDrafts;

    await tester.pumpWidget(
      _buildHarness(
        args: InventoryReceiptReviewPageArgs(
          items: <ReceiptReviewItemDraft>[
            ReceiptReviewItemDraft(item: _item(id: 'item-1')),
          ],
          onSaveTap: (drafts) async {
            savedDrafts = drafts;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_review_page')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(find.byType(InventoryReceiptReviewPage), findsNothing);
    expect(find.text('result:true'), findsOneWidget);
    expect(savedDrafts, isNotNull);
    expect(savedDrafts!.map((draft) => draft.item.id), <String>['item-1']);
  });
}
