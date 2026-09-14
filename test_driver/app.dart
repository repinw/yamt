import 'package:flutter_driver/driver_extension.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/features/scanner/presentation/flow/receipt_scan_flow_coordinator.dart';
import 'package:yamt/features/scanner/presentation/shared/shared_receipt_service.dart';
import 'package:yamt/main.dart' as app;

@Dependencies([
  navigatorKey,
  appRouter,
  InventoryItemsController,
  PreparedMealsController,
  SharedReceiptService,
  receiptScanFlowCoordinator,
])
Future<void> main() async {
  enableFlutterDriverExtension();
  await app.main();
}
