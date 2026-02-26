import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_batch_progress_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _wrap({
  required ValueNotifier<ReceiptBatchProgress> progressListenable,
  required ValueNotifier<Set<int>> reviewableIndicesListenable,
  required ValueNotifier<Set<int>> reviewedIndicesListenable,
  required ValueNotifier<bool> batchCompletedListenable,
  required Future<void> Function(int index) onReviewTap,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: InventoryReceiptBatchProgressDialog(
        progressListenable: progressListenable,
        reviewableIndicesListenable: reviewableIndicesListenable,
        reviewedIndicesListenable: reviewedIndicesListenable,
        batchCompletedListenable: batchCompletedListenable,
        onReviewTap: onReviewTap,
        onCloseTap: () {},
      ),
    ),
  );
}

void main() {
  testWidgets('shows progress and per-file statuses', (tester) async {
    final progress = ValueNotifier<ReceiptBatchProgress>(
      const ReceiptBatchProgress(
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
    );
    final reviewable = ValueNotifier<Set<int>>(const <int>{});
    final reviewed = ValueNotifier<Set<int>>(const <int>{});
    final completed = ValueNotifier<bool>(false);
    addTearDown(progress.dispose);
    addTearDown(reviewable.dispose);
    addTearDown(reviewed.dispose);
    addTearDown(completed.dispose);

    await tester.pumpWidget(
      _wrap(
        progressListenable: progress,
        reviewableIndicesListenable: reviewable,
        reviewedIndicesListenable: reviewed,
        batchCompletedListenable: completed,
        onReviewTap: (_) async {},
      ),
    );

    expect(find.text('Processing receipts'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('a.jpg'), findsOneWidget);
    expect(find.text('b.jpg'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Processing'), findsOneWidget);
  });

  testWidgets('updates text when progress changes', (tester) async {
    final progress = ValueNotifier<ReceiptBatchProgress>(
      const ReceiptBatchProgress(
        items: <ReceiptBatchItemProgress>[
          ReceiptBatchItemProgress(
            fileName: 'a.jpg',
            status: ReceiptBatchItemStatus.queued,
          ),
        ],
      ),
    );
    final reviewable = ValueNotifier<Set<int>>(const <int>{});
    final reviewed = ValueNotifier<Set<int>>(const <int>{});
    final completed = ValueNotifier<bool>(false);
    addTearDown(progress.dispose);
    addTearDown(reviewable.dispose);
    addTearDown(reviewed.dispose);
    addTearDown(completed.dispose);

    await tester.pumpWidget(
      _wrap(
        progressListenable: progress,
        reviewableIndicesListenable: reviewable,
        reviewedIndicesListenable: reviewed,
        batchCompletedListenable: completed,
        onReviewTap: (_) async {},
      ),
    );
    expect(find.text('0/1'), findsOneWidget);

    progress.value = const ReceiptBatchProgress(
      items: <ReceiptBatchItemProgress>[
        ReceiptBatchItemProgress(
          fileName: 'a.jpg',
          status: ReceiptBatchItemStatus.succeeded,
        ),
      ],
    );
    await tester.pump();

    expect(find.text('1/1'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('shows review actions and reviewed label', (tester) async {
    final progress = ValueNotifier<ReceiptBatchProgress>(
      const ReceiptBatchProgress(
        items: <ReceiptBatchItemProgress>[
          ReceiptBatchItemProgress(
            fileName: 'a.jpg',
            status: ReceiptBatchItemStatus.succeeded,
          ),
        ],
      ),
    );
    final reviewable = ValueNotifier<Set<int>>(<int>{0});
    final reviewed = ValueNotifier<Set<int>>(const <int>{});
    final completed = ValueNotifier<bool>(true);
    addTearDown(progress.dispose);
    addTearDown(reviewable.dispose);
    addTearDown(reviewed.dispose);
    addTearDown(completed.dispose);

    var tappedIndex = -1;
    await tester.pumpWidget(
      _wrap(
        progressListenable: progress,
        reviewableIndicesListenable: reviewable,
        reviewedIndicesListenable: reviewed,
        batchCompletedListenable: completed,
        onReviewTap: (index) async {
          tappedIndex = index;
        },
      ),
    );

    await tester.tap(find.text('Review'));
    await tester.pump();
    expect(tappedIndex, 0);

    reviewed.value = <int>{0};
    await tester.pump();
    expect(find.text('Reviewed'), findsOneWidget);
  });
}
