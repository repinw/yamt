import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/scanner/domain/receipt_capture_flow_models.dart';
import 'package:yamt/features/scanner/domain/receipt_input_models.dart';
import 'package:yamt/features/scanner/presentation/receipt_review_flow_runner.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _ThrowingReceiptCaptureFlowController
    extends ReceiptCaptureFlowController {
  _ThrowingReceiptCaptureFlowController({
    required this.started,
    required this.releaseError,
    required this.error,
  });

  final Completer<void> started;
  final Completer<void> releaseError;
  final Object error;

  @override
  Future<ReceiptCaptureFlowResult?> build() async {
    return null;
  }

  @override
  Future<ReceiptCaptureFlowResult> runSelection({
    required ReceiptInputSelection selection,
  }) async {
    if (!started.isCompleted) {
      started.complete();
    }
    await releaseError.future;
    throw error;
  }
}

ReceiptInputSelection _selection() {
  return ReceiptInputSelection(
    source: ReceiptInputSource.file,
    name: 'shared_receipt.jpg',
    mimeType: 'image/jpeg',
    bytes: Uint8List.fromList(<int>[1, 2, 3]),
  );
}

void main() {
  testWidgets(
    'runSelection closes the loading dialog when the controller throws',
    (tester) async {
      final started = Completer<void>();
      final releaseError = Completer<void>();
      final error = StateError('boom');
      final fakeController = _ThrowingReceiptCaptureFlowController(
        started: started,
        releaseError: releaseError,
        error: error,
      );

      late BuildContext capturedContext;
      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            receiptCaptureFlowControllerProvider.overrideWith(
              () => fakeController,
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Consumer(
              builder: (context, ref, child) {
                capturedContext = context;
                capturedRef = ref;
                return const Scaffold(body: Text('Home'));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final runner = ReceiptReviewFlowRunner(
        context: capturedContext,
        ref: capturedRef,
        l10n: AppLocalizations.of(capturedContext)!,
        captureController: fakeController,
      );
      addTearDown(runner.dispose);

      final future = runner.runSelection(
        selection: _selection(),
        onItemsSaved: () {},
      );
      await started.future;
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final expectation = expectLater(future, throwsA(same(error)));
      releaseError.complete();

      await expectation;
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}
