import 'package:flutter/material.dart';

/// Container view state shared by cookflow steps.
class CookingFlowStorageContainerView {
  /// Creates container view state.
  const CookingFlowStorageContainerView({
    required this.id,
    required this.labelController,
    required this.taraController,
    required this.grossWeightController,
    required this.portionController,
    required this.selectedTaraUtensilId,
    required this.canRemove,
  });

  /// Stable container id.
  final String id;

  /// Label controller.
  final TextEditingController labelController;

  /// Tara weight controller.
  final TextEditingController taraController;

  /// Gross weight controller.
  final TextEditingController grossWeightController;

  /// Portion count controller.
  final TextEditingController portionController;

  /// Selected utensil id.
  final String? selectedTaraUtensilId;

  /// Whether this container can be removed.
  final bool canRemove;
}
