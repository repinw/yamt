import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/domain/receipt_batch_flow_state.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_batch_progress_dialog.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _TestReceiptBatchFlowController extends ReceiptBatchFlowController {
  _TestReceiptBatchFlowController(this.initialState);

  final ReceiptBatchFlowState initialState;

  @override
  ReceiptBatchFlowState build() {
    return initialState;
  }

  void replaceState(ReceiptBatchFlowState next) {
    state = next;
  }
}

Widget _wrap({
  required _TestReceiptBatchFlowController controller,
  required Future<void> Function(int index) onReviewTap,
}) {
  return ProviderScope(
    overrides: [
      receiptBatchFlowControllerProvider.overrideWith(() => controller),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: InventoryReceiptBatchProgressDialog(
          onReviewTap: onReviewTap,
          onCloseTap: () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows progress and per-file statuses', (tester) async {
    final controller = _TestReceiptBatchFlowController(
      const ReceiptBatchFlowState(
        progress: ReceiptBatchProgress(
          items: <ReceiptBatchItemProgress>[
            ReceiptBatchItemProgress(
              fileName: 'a.jpg',
              status: ReceiptBatchItemStatus.succeeded,
            ),
            ReceiptBatchItemProgress(
              fileName: 'b.jpg',
              status: ReceiptBatchItemStatus.processing,
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(
      _wrap(controller: controller, onReviewTap: (_) async {}),
    );

    expect(find.text('Processing receipts'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('a.jpg'), findsOneWidget);
    expect(find.text('b.jpg'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Processing'), findsOneWidget);
  });

  testWidgets('updates text when state changes', (tester) async {
    final controller = _TestReceiptBatchFlowController(
      const ReceiptBatchFlowState(
        progress: ReceiptBatchProgress(
          items: <ReceiptBatchItemProgress>[
            ReceiptBatchItemProgress(
              fileName: 'a.jpg',
              status: ReceiptBatchItemStatus.queued,
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(
      _wrap(controller: controller, onReviewTap: (_) async {}),
    );
    expect(find.text('0/1'), findsOneWidget);

    controller.replaceState(
      const ReceiptBatchFlowState(
        progress: ReceiptBatchProgress(
          items: <ReceiptBatchItemProgress>[
            ReceiptBatchItemProgress(
              fileName: 'a.jpg',
              status: ReceiptBatchItemStatus.succeeded,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('1/1'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('shows review actions and reviewed label', (tester) async {
    final controller = _TestReceiptBatchFlowController(
      const ReceiptBatchFlowState(
        status: ReceiptBatchFlowStatus.completed,
        progress: ReceiptBatchProgress(
          items: <ReceiptBatchItemProgress>[
            ReceiptBatchItemProgress(
              fileName: 'a.jpg',
              status: ReceiptBatchItemStatus.succeeded,
            ),
          ],
        ),
        reviewableIndices: <int>{0},
      ),
    );

    var tappedIndex = -1;
    await tester.pumpWidget(
      _wrap(
        controller: controller,
        onReviewTap: (index) async {
          tappedIndex = index;
        },
      ),
    );

    await tester.tap(find.text('Review'));
    await tester.pump();
    expect(tappedIndex, 0);

    controller.replaceState(
      const ReceiptBatchFlowState(
        status: ReceiptBatchFlowStatus.completed,
        progress: ReceiptBatchProgress(
          items: <ReceiptBatchItemProgress>[
            ReceiptBatchItemProgress(
              fileName: 'a.jpg',
              status: ReceiptBatchItemStatus.succeeded,
            ),
          ],
        ),
        reviewableIndices: <int>{0},
        reviewedIndices: <int>{0},
      ),
    );
    await tester.pump();
    expect(find.text('Reviewed'), findsOneWidget);
  });
}
