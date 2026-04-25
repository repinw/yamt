import 'package:flutter_driver/driver_extension.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';
import 'package:yamt/main.dart' as app;

@Dependencies([
  appRouter,
  InventoryItemsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
])
Future<void> main() async {
  enableFlutterDriverExtension();
  await app.main();
}
