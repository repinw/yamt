import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/cooking_flow/application/cooking_flow_summary_builder.dart';

/// Text controller state for one storage container row.
class CookingFlowStorageContainerState {
  /// Creates storage container state.
  new({
    required this.id,
    required this.labelController,
    required this.taraController,
    required this.grossWeightController,
    required this.portionController,
    required this.usesPrimaryWeightControllers,
    this.taraUtensilId,
  });

  /// Stable id.
  final String id;

  /// Optional display label controller.
  final TextEditingController labelController;

  /// Tara text controller.
  final TextEditingController taraController;

  /// Gross text controller.
  final TextEditingController grossWeightController;

  /// Portion text controller.
  final TextEditingController portionController;

  /// Whether this row uses legacy primary controllers.
  final bool usesPrimaryWeightControllers;

  /// Selected utensil id.
  String? taraUtensilId;

  /// Tara grams.
  int get taraWeight => parseCookingFlowWholeWeight(taraController.text);

  /// Gross grams.
  int get grossWeight =>
      parseCookingFlowWholeWeight(grossWeightController.text);

  /// Net grams.
  int get finalNetWeight => grossWeight - taraWeight;

  /// Total portions.
  int get totalPortions {
    final portions = parseCookingFlowWholeWeight(portionController.text);
    return portions < 1 ? 0 : portions;
  }

  /// Disposes owned controllers.
  void dispose() {
    labelController.dispose();
    portionController.dispose();
    if (!usesPrimaryWeightControllers) {
      taraController.dispose();
      grossWeightController.dispose();
    }
  }
}
