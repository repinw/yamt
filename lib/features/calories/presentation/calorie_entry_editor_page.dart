import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_create_context.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_content.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines calorie entry editor page.
@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
  calorieEntryDeleteFlow,
])
class CalorieEntryEditorPage extends ConsumerStatefulWidget {
  /// The calorie entry editor page.
  const CalorieEntryEditorPage({
    super.key,
    this.entryId,
    this.prefilledProfile,
    this.scannedSourceRef,
    this.inventoryContext,
    this.preselectedMealType,
    this.preselectedLoggedAt,
  });

  /// The entry id.
  final String? entryId;

  /// The prefilled profile.
  final CalorieProductProfile? prefilledProfile;

  /// The scanned source ref.
  final CalorieScannedSourceRef? scannedSourceRef;

  /// The inventory context.
  final CalorieInventoryCreateContext? inventoryContext;

  /// The preselected meal type.
  final MealType? preselectedMealType;

  /// The preselected logged at.
  final DateTime? preselectedLoggedAt;

  @override
  ConsumerState<CalorieEntryEditorPage> createState() {
    return _CalorieEntryEditorPageState();
  }
}

class _CalorieEntryEditorPageState
    extends ConsumerState<CalorieEntryEditorPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateChangesProvider);

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: SizedBox.square(
            dimension: AppSizes.inlineProgressIndicator,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.progressStrokeWidth,
            ),
          ),
        ),
      );
    }

    final user = authState.asData?.value;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.homeCalories)),
        body: Center(child: Text(l10n.caloriesAuthRequired)),
      );
    }

    return CalorieEntryEditorContent(
      user: user,
      entryId: widget.entryId,
      prefilledProfile: widget.prefilledProfile,
      scannedSourceRef: widget.scannedSourceRef,
      inventoryContext: widget.inventoryContext,
      preselectedMealType: widget.preselectedMealType,
      preselectedLoggedAt: widget.preselectedLoggedAt,
    );
  }
}
