import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/widgets/barcode_scanner/app_barcode_scanner_page.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'receipt_barcode_input_dialog.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'receipt_barcode_scanner.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  group('openReceiptBarcodeScanner', () {
    Widget buildTestApp({required Widget child}) {
      return MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );
    }

    testWidgets(
      'opens AppBarcodeScannerPage with manual action in app bar',
      (tester) async {
        String? result;

        await tester.pumpWidget(
          buildTestApp(
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await openReceiptBarcodeScanner(context);
                  },
                  child: const Text('Open Scanner'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Open Scanner'));
        await tester.pumpAndSettle();

        expect(find.byType(AppBarcodeScannerPage), findsOneWidget);
        expect(
          find.byKey(const Key('receipt_barcode_scanner_manual_action')),
          findsOneWidget,
        );

        // Tap manual entry action in app bar
        await tester.tap(
          find.byKey(const Key('receipt_barcode_scanner_manual_action')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ReceiptBarcodeInputDialog), findsOneWidget);

        // Enter barcode and submit
        await tester.enterText(find.byType(TextField), '4006381333931');
        await tester.tap(find.text('Bestätigen'));
        await tester.pumpAndSettle();

        expect(result, '4006381333931');
        expect(find.byType(AppBarcodeScannerPage), findsNothing);
      },
    );

    testWidgets('cancelling manual input dialog leaves scanner open', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => openReceiptBarcodeScanner(context),
                child: const Text('Open Scanner'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Scanner'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('receipt_barcode_scanner_manual_action')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptBarcodeInputDialog), findsOneWidget);

      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      // Dialog is closed, scanner is still open
      expect(find.byType(ReceiptBarcodeInputDialog), findsNothing);
      expect(find.byType(AppBarcodeScannerPage), findsOneWidget);
    });

    testWidgets('scanning barcode pops sheet and returns scanned value', (
      tester,
    ) async {
      String? result;

      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await openReceiptBarcodeScanner(context);
                },
                child: const Text('Open Scanner'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Scanner'));
      await tester.pumpAndSettle();

      final scannerPage = tester.widget<AppBarcodeScannerPage>(
        find.byType(AppBarcodeScannerPage),
      );
      expect(scannerPage.onBarcodeScanned, isNotNull);

      // Simulate camera detecting a barcode
      await scannerPage.onBarcodeScanned('7613035987654');
      await tester.pumpAndSettle();

      expect(result, '7613035987654');
      expect(find.byType(AppBarcodeScannerPage), findsNothing);
    });
  });
}
