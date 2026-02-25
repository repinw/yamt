import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_batch_progress_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _wrap(ValueNotifier<ReceiptBatchProgress> progressListenable) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: InventoryReceiptBatchProgressDialog(
        progressListenable: progressListenable,
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
    addTearDown(progress.dispose);

    await tester.pumpWidget(_wrap(progress));

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
    addTearDown(progress.dispose);

    await tester.pumpWidget(_wrap(progress));
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
}
