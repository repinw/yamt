import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_receipt_actions_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _wrap({
  required bool isCameraEnabled,
  required VoidCallback onScanCameraTap,
  required VoidCallback onUploadFileTap,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: InventoryReceiptActionsSheet(
        isCameraEnabled: isCameraEnabled,
        onScanCameraTap: onScanCameraTap,
        onUploadFileTap: onUploadFileTap,
      ),
    ),
  );
}

void main() {
  testWidgets('camera and upload actions trigger callbacks when enabled', (
    tester,
  ) async {
    var cameraTapCount = 0;
    var uploadTapCount = 0;

    await tester.pumpWidget(
      _wrap(
        isCameraEnabled: true,
        onScanCameraTap: () => cameraTapCount++,
        onUploadFileTap: () => uploadTapCount++,
      ),
    );

    await tester.tap(find.text('Scan receipt (camera)'));
    await tester.pumpAndSettle();
    expect(cameraTapCount, 1);

    await tester.tap(find.text('Upload receipt (image/PDF)'));
    await tester.pumpAndSettle();
    expect(uploadTapCount, 1);
  });

  testWidgets('disabled camera action does not trigger callback', (
    tester,
  ) async {
    var cameraTapCount = 0;

    await tester.pumpWidget(
      _wrap(
        isCameraEnabled: false,
        onScanCameraTap: () => cameraTapCount++,
        onUploadFileTap: () {},
      ),
    );

    expect(
      find.text('Camera is not supported on this platform.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Scan receipt (camera)'));
    await tester.pumpAndSettle();
    expect(cameraTapCount, 0);
  });
}
