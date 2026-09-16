// coverage:ignore-file
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yamt/app.dart';
import 'package:yamt/core/config/firebase_config.dart';
import 'package:yamt/core/debug/app_provider_observer.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/application/'
    'calorie_inventory_entry_save_handler.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_entry_post_persist_hook.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_product_search_hub_completion_handler.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_calorie_entry_post_persist_hook.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_quick_eat_application.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_picker.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_calorie_entry_delete_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_eat_coordinator.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_product_search_launcher.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_product_search_hub_completion_handler.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_quick_eat_sheet_picker.dart';
import 'package:yamt/features/product_search_hub/application/'
    'product_search_hub_completion_providers.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_mode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupFirebase();
  final appPreferences = await _createAppPreferences();

  runApp(
    ProviderScope(
      observers: kDebugMode
          ? const <ProviderObserver>[AppProviderObserver()]
          : const <ProviderObserver>[],
      overrides: [
        appPreferencesProvider.overrideWithValue(appPreferences),
        calorieEntryPostPersistHookProvider.overrideWith(
          (ref) => ref.watch(inventoryCalorieEntryPostPersistHookProvider),
        ),
        calorieEntryDeleteFlowProvider.overrideWith(
          (ref) => ref.watch(inventoryCalorieEntryDeleteFlowProvider),
        ),
        calorieInventoryEntrySaveHandlerProvider.overrideWith((ref) {
          final saveFlow = ref.watch(
            inventoryBackedCalorieEntrySaveFlowProvider,
          );
          return saveFlow.saveEntry;
        }),
        calorieInventoryPendingConsumptionDiscarderProvider.overrideWith((ref) {
          return ref
              .watch(inventoryQuickEatActionsProvider)
              .discardInventoryItemConsumption;
        }),
        inventoryManualProductSearchLauncherProvider.overrideWith(
          (ref) => buildInventoryProductSearchHubManualProductSearchLauncher(),
        ),
        inventoryQuickEatPickerProvider.overrideWithValue(
          const InventoryQuickEatSheetPicker(),
        ),
        productSearchHubCompletionHandlerFactoryProvider.overrideWith((ref) {
          final container = ref.container;
          return (mode) => switch (mode) {
            ProductSearchHubMode.inventory =>
              InventoryProductSearchHubCompletionHandler(
                container: container,
              ),
            ProductSearchHubMode.diary =>
              DiaryProductSearchHubCompletionHandler(
                container: container,
                eatCoordinator: container.read(
                  inventoryManualProductEatCoordinatorProvider,
                ),
              ),
            ProductSearchHubMode.selection =>
              const SelectionProductSearchHubCompletionHandler(),
          };
        }),
      ],
      child: const YAMT(),
    ),
  );
}

Future<AppPreferences> _createAppPreferences() async {
  try {
    final preferences = await SharedPreferences.getInstance();
    return SharedPreferencesStore(preferences: preferences);
  } on MissingPluginException {
    return SharedPreferencesStore();
  } on PlatformException {
    return SharedPreferencesStore();
  }
}
