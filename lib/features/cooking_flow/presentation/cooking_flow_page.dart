import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_controller.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_logic.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_controller.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_state.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_finalize_messages.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_page_body.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_page_bottom_navigation.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_page_widgets.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_session_input_builder.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_storage_container_controller.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_storage_container_models.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_summary_ingredient_source_flow.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_summary_page.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_template_helpers.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_templates_controller.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Main Cookflow shell for a selected meal template.
@Dependencies([
  CookingFlowController,
  CookingFlowWizardController,
  InventoryItemsController,
])
class CookingFlowPage extends ConsumerStatefulWidget {
  /// Creates Cookflow page.
  const CookingFlowPage({required this.templateId, super.key});

  /// Selected template id.
  final String templateId;

  @override
  ConsumerState<CookingFlowPage> createState() => _CookingFlowPageState();
}

class _CookingFlowPageState extends ConsumerState<CookingFlowPage> {
  final TextEditingController _adjustmentController = TextEditingController();
  late final CookingFlowStorageContainerController _storageController;
  final CookingFlowRawIngredientLogger _rawIngredientLogger =
      CookingFlowRawIngredientLogger();

  @override
  void initState() {
    super.initState();
    _storageController = CookingFlowStorageContainerController(
      initialFinalPortions: _resolvedFinalPortions,
    );
    unawaited(_restoreSession());
  }

  @override
  void dispose() {
    _storageController.dispose();
    _adjustmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final templatesAsync = ref.watch(preparedMealTemplatesControllerProvider);
    final wizardState = ref.watch(cookingFlowWizardControllerProvider);
    final isFinalizingMeal = ref.watch(
      cookingFlowControllerProvider.select(
        (state) => state.isFinalizingMeal,
      ),
    );
    final inventoryItems =
        ref.watch(inventoryItemsControllerProvider).asData?.value ??
        const <InventoryItem>[];

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBackPressed();
      },
      child: Scaffold(
        appBar: CookflowTopBar(
          onBackPressed: _handleBackPressed,
          progressIndex: switch (_step) {
            CookingFlowStep.start => null,
            CookingFlowStep.preparation => 0,
            CookingFlowStep.cooking => 1,
            CookingFlowStep.summary => 2,
            CookingFlowStep.finalize => 3,
            CookingFlowStep.success => null,
          },
        ),
        body: SafeArea(
          child: CookingFlowPageBody(
            isRestoringSession: wizardState.isRestoringSession,
            templatesAsync: templatesAsync,
            wizardState: wizardState,
            templateId: widget.templateId,
            targetPortions: _portionCount,
            introDraft: _introDraft,
            introShoppingBaselineInventoryItemIds:
                _introShoppingBaselineInventoryItemIds,
            introResetSignal: _introResetSignal,
            storageContainers: _storageContainerViews,
            adjustmentController: _adjustmentController,
            adjustments: _adjustments,
            summaryIngredients: _summaryIngredients,
            inventoryItems: inventoryItems,
            ingredientContainerAssignments:
                _effectiveIngredientContainerAssignments,
            isWeightValid: _hasValidFinalizeWeight,
            buildNutritionPreview: _buildFinalizeNutritionPreview,
            splitIntoPortions: _splitIntoPortions,
            validationMessage: _finalizeWeightValidationMessage,
            finalPortionCount: _finalPortionCount,
            savedMealName:
                _savedPreparedMealName ?? l10n.cookflowSuccessFallbackMealName,
            onTemplateResolved: _handleTemplateResolved,
            onInventoryPressed: _openSavedMealInInventory,
            onTargetPortionsChanged: _updatePortionCount,
            onRestartPressed: _restartSession,
            onShoppingLabelsResolved: _resolveShoppingListLabels,
            onSelectionStateChanged: _updateIntroSelectionState,
            onContainerChanged: _updateStorageContainerText,
            onContainerTaraUtensilSelected: _selectStorageContainerUtensil,
            onAddContainerPressed: _addStorageContainer,
            onRemoveContainerPressed: _removeStorageContainer,
            onOpenKitchenUtensilsPressed: _startOpenKitchenUtensils,
            onAddAdjustmentPressed: _addOnTheFlyAdjustment,
            onRemoveAdjustmentPressed: _removeOnTheFlyAdjustment,
            onSummaryAmountChanged: _updateSummaryIngredientAmount,
            onRemoveSummaryIngredient: _removeSummaryIngredient,
            onAddIngredientSourceSelected: _startSummaryIngredientSource,
            onAdjustmentSourceSelected: _startSummaryAdjustmentSource,
            onIngredientContainerChanged: _updateIngredientContainerAssignment,
            onSplitIntoPortionsChanged: _updateSplitIntoPortions,
            onFinalPortionCountChanged: _updateFinalizePortionCount,
          ),
        ),
        bottomNavigationBar: CookingFlowPageBottomNavigation(
          step: _step,
          isFinalizingMeal: isFinalizingMeal,
          hasValidFinalizeWeight: _hasValidFinalizeWeight,
          introAllItemsSelected: _introAllItemsSelected,
          introHasShoppingSelections: _introHasShoppingSelections,
          introHasUnresolvedConflicts: _introHasUnresolvedConflicts,
          introShoppingHandled: _introShoppingHandled,
          introShoppingRedirectInProgress: _introShoppingRedirectInProgress,
          onLaterPressed: _handleBackPressed,
          onIntroShoppingPressed: _startIntroShoppingListPressed,
          onOpenPreparationPressed: _openPreparationStep,
          onOpenCookingPressed: _openCookingStep,
          onOpenSummaryPressed: _openSummaryStep,
          onOpenFinalizePressed: _openFinalizeStep,
          onFinalizePressed: _startFinalizeMealSave,
        ),
      ),
    );
  }

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  CookingFlowWizardState get _wizardState {
    return ref.read(cookingFlowWizardControllerProvider);
  }

  CookingFlowWizardController get _wizardController {
    return ref.read(cookingFlowWizardControllerProvider.notifier);
  }

  CookingFlowStep get _step => _wizardState.step;

  List<String> get _adjustments => _wizardState.adjustments;

  List<CookingFlowSummaryIngredientDraft> get _summaryIngredients {
    return _wizardState.summaryIngredients;
  }

  CookingFlowIntroDraft? get _introDraft => _wizardState.introDraft;

  bool get _splitIntoPortions => _wizardState.splitIntoPortions;

  double get _portionCount => _wizardState.portionCount;

  double get _finalPortionCount => _wizardState.finalPortionCount;

  List<String> get _introShoppingBaselineInventoryItemIds {
    return _wizardState.introShoppingBaselineInventoryItemIds;
  }

  int get _introResetSignal => _wizardState.introResetSignal;

  bool get _introAllItemsSelected => _wizardState.introAllItemsSelected;

  bool get _introHasShoppingSelections {
    return _wizardState.introHasShoppingSelections;
  }

  bool get _introHasUnresolvedConflicts {
    return _wizardState.introHasUnresolvedConflicts;
  }

  bool get _introShoppingHandled => _wizardState.introShoppingHandled;

  bool get _introShoppingRedirectInProgress {
    return _wizardState.introShoppingRedirectInProgress;
  }

  Map<String, String> get _ingredientContainerAssignments {
    return _wizardState.ingredientContainerAssignments;
  }

  String? get _savedPreparedMealId => _wizardState.savedPreparedMealId;

  String? get _savedPreparedMealName {
    final state = _wizardState;
    if (state.savedPreparedMealName != null) {
      return state.savedPreparedMealName;
    }
    if (state.savedContainerCount > 1) {
      return _l10n.cookflowSavedMealsCount(state.savedContainerCount);
    }
    return null;
  }

  void _handleTemplateResolved(PreparedMeal template) {
    _initializePortionsFromTemplate(template);
    _rawIngredientLogger.logTemplate(template);
  }

  void _openPreparationStep() {
    _wizardController.openPreparationStep();
    _persistSessionSilently();
  }

  void _updateIntroSelectionState(CookingFlowIntroSelectionState selection) {
    _wizardController.updateIntroSelectionState(selection);
    _persistSessionSilently();
  }

  Future<void> _handleIntroShoppingListPressed() async {
    final inventoryItems =
        ref.read(inventoryItemsControllerProvider).asData?.value ??
        const <InventoryItem>[];
    final result = await _wizardController.addIntroShoppingItems(
      inventoryItems: inventoryItems,
    );
    if (!mounted || result == CookingFlowShoppingListActionResult.disposed) {
      return;
    }
    if (result == CookingFlowShoppingListActionResult.failed) {
      _showSnackBar(_l10n.cookflowShoppingListAddFailed);
      return;
    }
    final saved = await _saveSession();
    if (!mounted || !saved) {
      return;
    }
    await context.push(AppRoutes.homeShopping);
  }

  void _startIntroShoppingListPressed() {
    unawaited(_handleIntroShoppingListPressed());
  }

  Future<void> _resolveShoppingListLabels(List<String> labels) async {
    await _wizardController.resolveShoppingListLabels(labels);
  }

  void _startFinalizeMealSave() {
    unawaited(_finalizeMeal());
  }

  Future<void> _finalizeMeal() async {
    if (ref.read(cookingFlowControllerProvider).isFinalizingMeal) {
      return;
    }

    final templates = ref
        .read(preparedMealTemplatesControllerProvider)
        .asData
        ?.value;
    final template = templates == null
        ? null
        : findCookingFlowTemplate(templates, widget.templateId);
    if (template == null) {
      _showSnackBar(_l10n.cookflowTemplateNotFound);
      return;
    }

    final validationMessage = _finalizeWeightValidationMessage;
    if (validationMessage != null) {
      _showSnackBar(validationMessage);
      return;
    }

    final result = await _wizardController.finalizeMeal(
      template: template,
      finalPortions: _finalizeSavePlanPortions,
      containers: _finalizeStorageContainerInputs,
    );
    if (!mounted) {
      return;
    }

    if (!result.isSuccess) {
      _showSnackBar(
        cookingFlowFinalizeSaveFailureMessage(
          l10n: _l10n,
          failure: result.failure,
          invalidInputMessage: _finalizeWeightValidationMessage,
        ),
      );
      return;
    }
  }

  int get _resolvedFinalPortions {
    return resolveCookingFlowFinalPortions(
      splitIntoPortions: _splitIntoPortions,
      portionCount: _finalPortionCount,
    );
  }

  int get _targetRecipePortions {
    final roundedPortions = _portionCount.round();
    return roundedPortions < 1 ? 1 : roundedPortions;
  }

  List<CookingFlowStorageContainerView> get _storageContainerViews {
    return _storageController.views;
  }

  List<String> get _storageContainerIds {
    return _storageController.ids;
  }

  Map<String, String> get _effectiveIngredientContainerAssignments {
    return effectiveCookingFlowIngredientContainerAssignments(
      containers: _finalizeStorageContainerInputs,
      summaryIngredients: _summaryIngredients,
      assignments: _ingredientContainerAssignments,
    );
  }

  bool get _hasValidFinalizeWeight {
    return _finalizeWeightValidationMessage == null;
  }

  String? get _finalizeWeightValidationMessage {
    final failure = validateCookingFlowFinalize(
      containers: _finalizeStorageContainerInputs,
      summaryIngredients: _summaryIngredients,
      assignments: _effectiveIngredientContainerAssignments,
    );
    return failure == null
        ? null
        : cookingFlowFinalizeValidationMessage(_l10n, failure);
  }

  CookingFlowNutritionPreview _buildFinalizeNutritionPreview({
    required PreparedMeal template,
    required List<InventoryItem> inventoryItems,
  }) {
    return buildCookingFlowFinalizeNutritionPreview(
      template: template,
      inventoryItems: inventoryItems,
      summaryIngredients: _summaryIngredients,
      introDraft: _introDraft,
      targetPortions: _targetRecipePortions,
      finalPortions: _resolvedFinalPortions,
      splitIntoPortions: _splitIntoPortions,
      portionCount: _finalPortionCount,
      ingredientParser: const TemplateIngredientParser(),
    );
  }

  int get _finalizeSavePlanPortions {
    if (_splitIntoPortions) {
      return _resolvedFinalPortions;
    }
    return _targetRecipePortions;
  }

  List<CookingFlowFinalizeStorageContainerInput>
  get _finalizeStorageContainerInputs {
    return _storageController.finalizeInputs(
      totalPortions: _finalizeSavePlanPortions,
      fallbackLabelForIndex: (index) {
        return _l10n.cookflowContainerNameHint(index + 1);
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openCookingStep() {
    _wizardController.openCookingStep();
    _persistSessionSilently();
  }

  void _openSummaryStep() {
    final template = findCookingFlowTemplate(
      ref.read(preparedMealTemplatesControllerProvider).asData?.value ??
          const <PreparedMeal>[],
      widget.templateId,
    );
    final inventoryItems =
        ref.read(inventoryItemsControllerProvider).asData?.value ??
        const <InventoryItem>[];
    _wizardController.openSummaryStep(
      template: template,
      inventoryItems: inventoryItems,
      containerIds: _storageContainerIds,
    );
    _persistSessionSilently();
  }

  void _openFinalizeStep() {
    _wizardController.openFinalizeStep(_storageContainerIds);
    _persistSessionSilently();
  }

  void _goBackOneStep() {
    _wizardController.goBackOneStep();
    _persistSessionSilently();
  }

  void _handleBackPressed() {
    unawaited(_handleBackPressedAsync());
  }

  Future<void> _handleBackPressedAsync() async {
    if (_step == CookingFlowStep.success) {
      _openSavedMealInInventory();
      return;
    }
    if (_step == CookingFlowStep.start) {
      await _saveSession();
      if (!mounted) {
        return;
      }
      _leaveCookflow();
      return;
    }
    _goBackOneStep();
  }

  void _leaveCookflow() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.homeInventoryTemplates);
  }

  void _openSavedMealInInventory() {
    final preparedMealId = _savedPreparedMealId;
    if (preparedMealId == null) {
      context.go(AppRoutes.homeInventory);
      return;
    }
    context.go(AppRoutes.homeInventory, extra: preparedMealId);
  }

  void _addOnTheFlyAdjustment() {
    final value = _adjustmentController.text.trim();
    if (value.isEmpty) {
      return;
    }
    _wizardController.addAdjustment(value);
    _adjustmentController.clear();
    _persistSessionSilently();
  }

  void _removeOnTheFlyAdjustment(int index) {
    _wizardController.removeAdjustment(index);
    _persistSessionSilently();
  }

  void _updateSummaryIngredientAmount(int index, String value) {
    _wizardController.updateSummaryIngredientAmount(
      index: index,
      value: value,
      containerIds: _storageContainerIds,
    );
    _persistSessionSilently();
  }

  void _removeSummaryIngredient(int index) {
    _wizardController.removeSummaryIngredient(
      index: index,
      containerIds: _storageContainerIds,
    );
    _persistSessionSilently();
  }

  void _startSummaryIngredientSource(
    CookingFlowSummaryIngredientAddSource source,
  ) {
    unawaited(_handleSummaryIngredientSource(source: source));
  }

  void _startSummaryAdjustmentSource(
    int index,
    CookingFlowSummaryIngredientAddSource source,
  ) {
    unawaited(
      _handleSummaryIngredientSource(
        source: source,
        adjustmentIndex: index,
      ),
    );
  }

  Future<void> _handleSummaryIngredientSource({
    required CookingFlowSummaryIngredientAddSource source,
    int? adjustmentIndex,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final ingredient = await resolveCookingFlowSummaryIngredientSource(
      context: context,
      container: container,
      source: source,
      currentIngredients: _summaryIngredients,
      adjustment: _adjustmentAt(adjustmentIndex),
      saveSession: _saveSession,
    );
    if (!mounted || ingredient == null) {
      return;
    }

    container
        .read(cookingFlowWizardControllerProvider.notifier)
        .addSummaryIngredient(
          ingredient: ingredient,
          adjustmentIndex: adjustmentIndex,
          containerIds: _storageContainerIds,
        );
    _persistSessionSilently();
  }

  String? _adjustmentAt(int? index) {
    if (!_isValidAdjustmentIndex(index)) {
      return null;
    }
    return _adjustments[index!];
  }

  bool _isValidAdjustmentIndex(int? index) {
    return index != null && index >= 0 && index < _adjustments.length;
  }

  void _replaceStorageContainersFromSession(CookingFlowSession storedSession) {
    _storageController.replaceFromSession(storedSession);
  }

  void _resetStorageContainers() {
    _storageController.reset(finalPortions: _resolvedFinalPortions);
  }

  void _syncEmptyStorageContainerPortions() {
    _storageController.syncEmptyPortions(_resolvedFinalPortionsText);
  }

  String get _resolvedFinalPortionsText => _resolvedFinalPortions.toString();

  void _normalizeIngredientContainerAssignments() {
    _wizardController.normalizeIngredientContainerAssignments(
      _storageContainerIds,
    );
  }

  void _updateSplitIntoPortions(bool value) {
    _wizardController.updateSplitIntoPortions(value: value);
    _persistSessionSilently();
  }

  void _updateFinalizePortionCount(double value) {
    _wizardController.updateFinalizePortionCount(value);
    _persistSessionSilently();
  }

  void _updateStorageContainerText(String value) {
    setState(() {});
    _persistSessionSilently();
  }

  void _selectStorageContainerUtensil(
    String containerId,
    KitchenUtensil utensil,
  ) {
    setState(() {
      _storageController.selectUtensil(containerId, utensil);
    });
    _persistSessionSilently();
  }

  void _addStorageContainer() {
    setState(() {
      _storageController.add(finalPortions: _resolvedFinalPortions);
    });
    _normalizeIngredientContainerAssignments();
    _persistSessionSilently();
  }

  void _removeStorageContainer(String containerId) {
    var removed = false;
    setState(() {
      removed = _storageController.remove(containerId);
    });
    if (!removed) {
      return;
    }
    _normalizeIngredientContainerAssignments();
    _persistSessionSilently();
  }

  void _updateIngredientContainerAssignment(
    String rowKey,
    String containerId,
  ) {
    _wizardController.updateIngredientContainerAssignment(
      rowKey: rowKey,
      containerId: containerId,
      containerIds: _storageContainerIds,
    );
    _persistSessionSilently();
  }

  void _startOpenKitchenUtensils() {
    unawaited(_openKitchenUtensils());
  }

  Future<void> _openKitchenUtensils() async {
    final saved = await _saveSession();
    if (!mounted || !saved) {
      return;
    }
    await context.push(AppRoutes.homeKitchenUtensils);
  }

  void _updatePortionCount(double value) {
    _wizardController.updatePortionCount(value);
    _syncEmptyStorageContainerPortions();
    _persistSessionSilently();
  }

  void _initializePortionsFromTemplate(PreparedMeal template) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final container = ProviderScope.containerOf(context, listen: false);
      final changed = container
          .read(cookingFlowWizardControllerProvider.notifier)
          .initializePortionsFromTemplate(template);
      if (!mounted || !changed) {
        return;
      }
      _syncEmptyStorageContainerPortions();
    });
  }

  Future<void> _restoreSession() async {
    final storedSession = await _wizardController.restoreSession(
      widget.templateId,
    );
    if (!mounted) {
      return;
    }
    if (storedSession == null) {
      return;
    }
    setState(() {
      _replaceStorageContainersFromSession(storedSession);
      _adjustmentController.text = storedSession.adjustmentInputText;
    });
    _normalizeIngredientContainerAssignments();
  }

  Future<void> _restartSession() async {
    await _wizardController.restartSession();
    if (!mounted) {
      return;
    }

    setState(() {
      _adjustmentController.clear();
      _resetStorageContainers();
    });
  }

  Future<bool> _saveSession() async {
    final saved = await _wizardController.saveSession(_currentSessionInput);
    if (!mounted) {
      return false;
    }
    if (saved) {
      return true;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(_l10n.cookflowSessionSaveFailed)),
      );
    return false;
  }

  void _persistSessionSilently() {
    _wizardController.persistSessionSilently(_currentSessionInput);
  }

  CookingFlowWizardSessionInput get _currentSessionInput {
    return buildCookingFlowWizardSessionInput(
      templateId: widget.templateId,
      storageController: _storageController,
      adjustmentController: _adjustmentController,
      ingredientContainerAssignments: _effectiveIngredientContainerAssignments,
    );
  }
}
