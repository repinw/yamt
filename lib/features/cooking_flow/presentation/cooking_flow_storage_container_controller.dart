import 'package:flutter/material.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_logic.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_state.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_page_widgets.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_storage_container_models.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';

/// Owns page text controllers for cookflow storage containers.
class CookingFlowStorageContainerController {
  /// Creates controller and primary storage container.
  CookingFlowStorageContainerController({required int initialFinalPortions}) {
    containers.add(_createPrimaryStorageContainer(initialFinalPortions));
  }

  /// Primary tara text controller.
  final TextEditingController taraController = TextEditingController(
    text: cookingFlowTaraDefaultValue,
  );

  /// Primary gross-weight text controller.
  final TextEditingController grossWeightController = TextEditingController();

  /// Mutable storage container states.
  final List<CookingFlowStorageContainerState> containers =
      <CookingFlowStorageContainerState>[];

  String? _selectedTaraUtensilId;
  var _nextStorageContainerIndex = 2;

  /// Selected utensil for primary container.
  String? get selectedTaraUtensilId => _selectedTaraUtensilId;

  /// Current storage views for UI widgets.
  List<CookingFlowStorageContainerView> get views {
    return containers
        .map(
          (container) => CookingFlowStorageContainerView(
            id: container.id,
            labelController: container.labelController,
            taraController: container.taraController,
            grossWeightController: container.grossWeightController,
            portionController: container.portionController,
            selectedTaraUtensilId: container.taraUtensilId,
            canRemove: containers.length > 1,
          ),
        )
        .toList(growable: false);
  }

  /// Current storage ids.
  List<String> get ids {
    return containers.map((container) => container.id).toList(growable: false);
  }

  /// Inputs used by finalize save.
  List<CookingFlowFinalizeStorageContainerInput> finalizeInputs({
    required int totalPortions,
    required String Function(int index) fallbackLabelForIndex,
  }) {
    return [
      for (var index = 0; index < containers.length; index++)
        CookingFlowFinalizeStorageContainerInput(
          id: containers[index].id,
          label: _displayLabel(
            container: containers[index],
            index: index,
            fallbackLabelForIndex: fallbackLabelForIndex,
          ),
          taraText: containers[index].taraController.text.trim(),
          grossWeightText: containers[index].grossWeightController.text.trim(),
          taraWeight: containers[index].taraWeight,
          grossWeight: containers[index].grossWeight,
          finalNetWeight: containers[index].finalNetWeight,
          totalPortions: totalPortions,
        ),
    ];
  }

  /// Inputs used by session persistence.
  List<CookingFlowWizardStorageDraftInput> sessionDrafts() {
    return containers
        .map(
          (container) => CookingFlowWizardStorageDraftInput(
            id: container.id,
            label: container.labelController.text.trim(),
            taraText: container.taraController.text.trim(),
            taraUtensilId: container.taraUtensilId,
            grossWeightText: container.grossWeightController.text.trim(),
            portionCount: container.totalPortions.toDouble(),
          ),
        )
        .toList(growable: false);
  }

  /// Replaces storage container state from restored session.
  void replaceFromSession(CookingFlowSession storedSession) {
    _disposeContainerStates();
    containers.clear();
    final drafts = storedSession.storageContainers.isEmpty
        ? <CookingFlowStorageContainerSessionDraft>[
            CookingFlowStorageContainerSessionDraft(
              id: 'container-1',
              label: '',
              taraText: storedSession.taraText,
              taraUtensilId: storedSession.taraUtensilId,
              grossWeightText: storedSession.grossWeightText,
              portionCount: resolveCookingFlowFinalPortions(
                splitIntoPortions: storedSession.splitIntoPortions,
                portionCount: storedSession.portionCount,
              ).toDouble(),
            ),
          ]
        : storedSession.storageContainers;
    for (var index = 0; index < drafts.length; index++) {
      containers.add(
        _createStorageContainer(
          draft: drafts[index],
          usePrimaryWeightControllers: index == 0,
          finalPortions: resolveCookingFlowFinalPortions(
            splitIntoPortions: storedSession.splitIntoPortions,
            portionCount: storedSession.portionCount,
          ),
        ),
      );
    }
    _selectedTaraUtensilId = containers.first.taraUtensilId;
    _nextStorageContainerIndex = _nextContainerIndexAfterRestore();
  }

  /// Resets to one primary container.
  void reset({required int finalPortions}) {
    _disposeContainerStates();
    containers
      ..clear()
      ..add(_createPrimaryStorageContainer(finalPortions));
    _nextStorageContainerIndex = 2;
    _selectedTaraUtensilId = null;
  }

  /// Adds storage container.
  void add({required int finalPortions}) {
    containers.add(_createStorageContainer(finalPortions: finalPortions));
  }

  /// Removes storage container by id.
  bool remove(String containerId) {
    if (containers.length <= 1) {
      return false;
    }
    final index = containers.indexWhere(
      (container) => container.id == containerId,
    );
    if (index < 0) {
      return false;
    }
    containers.removeAt(index).dispose();
    final first = containers.first;
    if (first.usesPrimaryWeightControllers) {
      _selectedTaraUtensilId = first.taraUtensilId;
    }
    return true;
  }

  /// Selects utensil for one container.
  bool selectUtensil(String containerId, KitchenUtensil utensil) {
    final container = _find(containerId);
    if (container == null) {
      return false;
    }
    container.taraUtensilId = utensil.id;
    container.taraController.text = utensil.weightGrams.toString();
    if (container.labelController.text.trim().isEmpty && utensil.name != null) {
      container.labelController.text = utensil.name!;
    }
    if (container.usesPrimaryWeightControllers) {
      _selectedTaraUtensilId = utensil.id;
    }
    return true;
  }

  /// Syncs empty portion fields to current default.
  void syncEmptyPortions(String text) {
    for (final container in containers) {
      final currentText = container.portionController.text.trim();
      if (currentText.isEmpty || currentText == '3') {
        container.portionController.text = text;
      }
    }
  }

  /// Disposes owned controllers.
  void dispose() {
    _disposeContainerStates();
    taraController.dispose();
    grossWeightController.dispose();
  }

  CookingFlowStorageContainerState _createPrimaryStorageContainer(
    int finalPortions,
  ) {
    return CookingFlowStorageContainerState(
      id: 'container-1',
      labelController: TextEditingController(),
      taraController: taraController,
      grossWeightController: grossWeightController,
      portionController: TextEditingController(
        text: _portionText(finalPortions),
      ),
      usesPrimaryWeightControllers: true,
      taraUtensilId: _selectedTaraUtensilId,
    );
  }

  CookingFlowStorageContainerState _createStorageContainer({
    required int finalPortions,
    CookingFlowStorageContainerSessionDraft? draft,
    bool usePrimaryWeightControllers = false,
  }) {
    if (usePrimaryWeightControllers) {
      taraController.text = draft?.taraText ?? taraController.text;
      grossWeightController.text =
          draft?.grossWeightText ?? grossWeightController.text;
    }
    return CookingFlowStorageContainerState(
      id: draft?.id ?? _nextStorageContainerId(),
      labelController: TextEditingController(text: draft?.label ?? ''),
      taraController: usePrimaryWeightControllers
          ? taraController
          : TextEditingController(
              text: draft?.taraText ?? cookingFlowTaraDefaultValue,
            ),
      grossWeightController: usePrimaryWeightControllers
          ? grossWeightController
          : TextEditingController(text: draft?.grossWeightText ?? ''),
      portionController: TextEditingController(
        text: _portionText(draft?.portionCount ?? finalPortions),
      ),
      usesPrimaryWeightControllers: usePrimaryWeightControllers,
      taraUtensilId: draft?.taraUtensilId,
    );
  }

  void _disposeContainerStates() {
    for (final container in containers) {
      container.dispose();
    }
  }

  int _nextContainerIndexAfterRestore() {
    var nextIndex = 1;
    for (final container in containers) {
      final suffix = int.tryParse(container.id.replaceFirst('container-', ''));
      if (suffix != null && suffix >= nextIndex) {
        nextIndex = suffix + 1;
      }
    }
    return nextIndex < 2 ? 2 : nextIndex;
  }

  String _nextStorageContainerId() {
    while (true) {
      final id = 'container-${_nextStorageContainerIndex++}';
      final exists = containers.any((container) => container.id == id);
      if (!exists) {
        return id;
      }
    }
  }

  CookingFlowStorageContainerState? _find(String id) {
    for (final container in containers) {
      if (container.id == id) {
        return container;
      }
    }
    return null;
  }

  String _displayLabel({
    required CookingFlowStorageContainerState container,
    required int index,
    required String Function(int index) fallbackLabelForIndex,
  }) {
    final label = container.labelController.text.trim();
    if (label.isNotEmpty) {
      return label;
    }
    return fallbackLabelForIndex(index);
  }

  String _portionText(num value) {
    final rounded = value.round();
    return (rounded < 1 ? 1 : rounded).toString();
  }
}
