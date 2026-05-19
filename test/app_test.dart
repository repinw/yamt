import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/app.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/diary/application/diary_provider_warmup.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';

import 'features/calories/support/fake_calories_repositories.dart';

const _readyHealthStatus = HealthConnectionStatus(
  platform: HealthPlatform.android,
  healthConnectAvailability: HealthConnectAvailability.available,
  permissionState: HealthPermissionState.granted,
  historyAccess: HealthHistoryAccess.granted,
);

@Dependencies([
  InventoryItemsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
  diaryProviderWarmup,
])
void main() {
  testWidgets('YAMT builds router app from provider', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('root')),
        ),
      ],
    );
    addTearDown(router.dispose);
    final settingsRepository = FakeCalorieSettingsRepository();
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appRouterProvider.overrideWithValue(router),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          healthConnectionServiceProvider.overrideWith(
            (ref) => FakeHealthConnectionService(_readyHealthStatus),
          ),
        ],
        child: const YAMT(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.text('root'), findsOneWidget);
    expect(
      (await settingsRepository.readSettings()).activityTrackingStartDate,
      isNull,
    );

    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pumpAndSettle();

    expect(
      (await settingsRepository.readSettings()).activityTrackingStartDate,
      isNotNull,
    );
  });
}
