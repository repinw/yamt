import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_finalize_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_state.dart';
import 'package:yamt/features/cooking_flow/data/'
    'cooking_flow_session_local_store.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/cooking_flow/presentation/controllers/'
    'cooking_flow_controller.dart';
import 'package:yamt/features/cooking_flow/presentation/controllers/'
    'cooking_flow_wizard_controller.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository.dart';

import '../../../shoppinglist/support/fake_shopping_list_repository.dart';

@Dependencies([CookingFlowController, CookingFlowWizardController])
void main() {
  test('moves through preparation, cooking, summary, and finalize steps', () {
    final container = _container();
    final controller = container.read(
      cookingFlowWizardControllerProvider.notifier,
    );
    void openPreparationStep() => controller.openPreparationStep();
    void openCookingStep() => controller.openCookingStep();
    void openSummaryStep() => controller.openSummaryStep(
      template: null,
      inventoryItems: const <InventoryItem>[],
      containerIds: const <String>['container-1'],
    );
    void openFinalizeStep() {
      controller.openFinalizeStep(const <String>['container-1']);
    }

    openPreparationStep();
    expect(
      container.read(cookingFlowWizardControllerProvider).step,
      CookingFlowStep.preparation,
    );

    openCookingStep();
    expect(
      container.read(cookingFlowWizardControllerProvider).step,
      CookingFlowStep.cooking,
    );

    openSummaryStep();
    expect(
      container.read(cookingFlowWizardControllerProvider).step,
      CookingFlowStep.summary,
    );

    openFinalizeStep();
    expect(
      container.read(cookingFlowWizardControllerProvider).step,
      CookingFlowStep.finalize,
    );
  });

  test('resets summary on base portion change but not finalize change', () {
    final container = _container();
    final controller = container.read(
      cookingFlowWizardControllerProvider.notifier,
    );
    void addSummaryIngredientAndSetFinalizePortions() {
      controller
        ..addSummaryIngredient(
          ingredient: _summaryIngredient,
          adjustmentIndex: null,
          containerIds: const <String>['container-1'],
        )
        ..updateFinalizePortionCount(5.6);
    }

    void updateBasePortions() {
      controller.updatePortionCount(7.4);
    }

    addSummaryIngredientAndSetFinalizePortions();

    final afterFinalizeChange = container.read(
      cookingFlowWizardControllerProvider,
    );
    expect(afterFinalizeChange.finalPortionCount, 6);
    expect(afterFinalizeChange.summaryIngredients, hasLength(1));
    expect(afterFinalizeChange.ingredientContainerAssignments, <String, String>{
      'row-rice': 'container-1',
    });

    updateBasePortions();

    final afterBaseChange = container.read(cookingFlowWizardControllerProvider);
    expect(afterBaseChange.portionCount, 7);
    expect(afterBaseChange.finalPortionCount, 7);
    expect(afterBaseChange.summaryIngredients, isEmpty);
    expect(afterBaseChange.summarySourceSignature, isEmpty);
    expect(afterBaseChange.ingredientContainerAssignments, isEmpty);
  });

  test('intro selection update clears stale summary ingredients', () async {
    final store = _FakeCookingFlowSessionLocalStore(
      session: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.summary,
        taraText: '',
        adjustmentInputText: '',
        adjustments: <String>[],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[
          CookingFlowSummaryIngredientSessionDraft(
            key: 'row-rice',
            name: 'Rice',
            amount: '200',
            unitCode: 'g',
            inventoryItemIds: <String>['rice'],
            kind: CookingFlowSummaryIngredientKind.template,
            sourceIngredient: '200g Rice',
          ),
        ],
        grossWeightText: '',
        splitIntoPortions: false,
        portionCount: 4,
        introDraft: CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(rawIngredient: '200g Rice'),
          ],
        ),
        introShoppingHandled: true,
        introShoppingBaselineInventoryItemIds: <String>['rice'],
        ingredientContainerAssignments: <String, String>{
          'row-rice': 'container-1',
        },
      ),
    );
    final container = _container(store: store);
    final controller = container.read(
      cookingFlowWizardControllerProvider.notifier,
    );

    await controller.restoreSession('template-1');
    expect(
      container.read(cookingFlowWizardControllerProvider).summaryIngredients,
      isNotEmpty,
    );

    controller.updateIntroSelectionState(
      const CookingFlowIntroSelectionState(
        allItemsSelected: false,
        hasShoppingSelections: false,
        hasUnresolvedConflicts: true,
        shoppingListLabels: <String>[],
        draft: CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(rawIngredient: '100g Beans'),
          ],
        ),
      ),
    );

    final state = container.read(cookingFlowWizardControllerProvider);
    expect(state.summaryIngredients, isEmpty);
    expect(state.introHasUnresolvedConflicts, isTrue);
    expect(state.introShoppingBaselineInventoryItemIds, isEmpty);
  });

  test('adds intro shopping items and stores inventory baseline', () async {
    final shoppingRepository = FakeShoppingListRepository();
    final container = _container(shoppingRepository: shoppingRepository);
    addTearDown(shoppingRepository.dispose);
    final controller = container.read(
      cookingFlowWizardControllerProvider.notifier,
    );

    final result =
        await (controller..updateIntroSelectionState(
              const CookingFlowIntroSelectionState(
                allItemsSelected: false,
                hasShoppingSelections: true,
                hasUnresolvedConflicts: false,
                shoppingListLabels: <String>['Mehl'],
                draft: CookingFlowIntroDraft(),
              ),
            ))
            .addIntroShoppingItems(
              inventoryItems: <InventoryItem>[
                _inventoryItem(id: 'flour', name: 'Mehl'),
              ],
            );

    final state = container.read(cookingFlowWizardControllerProvider);
    expect(result, CookingFlowShoppingListActionResult.success);
    expect(shoppingRepository.savedItems.single.name, 'Mehl');
    expect(state.introShoppingHandled, isTrue);
    expect(state.introShoppingRedirectInProgress, isFalse);
    expect(state.introShoppingBaselineInventoryItemIds, <String>['flour']);
  });

  test('goBackOneStep walks backward through wizard states', () {
    final container = _container();
    final controller = container.read(
      cookingFlowWizardControllerProvider.notifier,
    );
    final goBackOneStep = controller.goBackOneStep;

    controller
      ..openPreparationStep()
      ..openCookingStep()
      ..openSummaryStep(
        template: null,
        inventoryItems: const <InventoryItem>[],
        containerIds: const <String>['container-1'],
      )
      ..openFinalizeStep(const <String>['container-1'])
      ..goBackOneStep();
    expect(
      container.read(cookingFlowWizardControllerProvider).step,
      CookingFlowStep.summary,
    );

    goBackOneStep();
    goBackOneStep();
    goBackOneStep();
    goBackOneStep();

    expect(
      container.read(cookingFlowWizardControllerProvider).step,
      CookingFlowStep.start,
    );
  });

  test('summary ingredient mutations keep assignments normalized', () {
    final container = _container();
    final controller = container.read(
      cookingFlowWizardControllerProvider.notifier,
    );
    final addAdjustment = controller.addAdjustment;
    final addSummaryIngredient = controller.addSummaryIngredient;
    final updateSummaryIngredientAmount =
        controller.updateSummaryIngredientAmount;
    final updateIngredientContainerAssignment =
        controller.updateIngredientContainerAssignment;
    final normalizeIngredientContainerAssignments =
        controller.normalizeIngredientContainerAssignments;

    addAdjustment('  more rice  ');
    addSummaryIngredient(
      ingredient: _summaryIngredient,
      adjustmentIndex: 0,
      containerIds: const <String>['container-1', 'container-2'],
    );
    updateSummaryIngredientAmount(
      index: 0,
      value: '250',
      containerIds: const <String>['container-1', 'container-2'],
    );
    updateIngredientContainerAssignment(
      rowKey: 'row-rice',
      containerId: 'container-2',
      containerIds: const <String>['container-1', 'container-2'],
    );
    normalizeIngredientContainerAssignments(const <String>['container-3']);

    final updated = container.read(cookingFlowWizardControllerProvider);
    expect(updated.adjustments, isEmpty);
    expect(updated.summaryIngredients.single.amount, '250');
    expect(updated.ingredientContainerAssignments, <String, String>{
      'row-rice': 'container-3',
    });

    controller.removeSummaryIngredient(
      index: 0,
      containerIds: const <String>['container-3'],
    );
    expect(
      container.read(cookingFlowWizardControllerProvider).summaryIngredients,
      isEmpty,
    );
    expect(
      container
          .read(cookingFlowWizardControllerProvider)
          .ingredientContainerAssignments,
      isEmpty,
    );
  });

  test('restores stored session through wizard controller', () async {
    final store = _FakeCookingFlowSessionLocalStore(
      session: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.summary,
        taraText: '100',
        adjustmentInputText: '',
        adjustments: <String>['mehr Salz'],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[
          CookingFlowSummaryIngredientSessionDraft(
            key: 'row-rice',
            name: 'Rice',
            amount: '200',
            unitCode: 'g',
            inventoryItemIds: <String>['rice'],
            kind: CookingFlowSummaryIngredientKind.template,
            sourceIngredient: '200g Rice',
          ),
        ],
        grossWeightText: '700',
        splitIntoPortions: true,
        portionCount: 4,
        finalPortionCount: 6,
        introDraft: CookingFlowIntroDraft(),
        introShoppingHandled: true,
        introShoppingBaselineInventoryItemIds: <String>['rice'],
        ingredientContainerAssignments: <String, String>{
          'row-rice': 'container-1',
        },
      ),
    );
    final container = _container(store: store);
    final controller = container.read(
      cookingFlowWizardControllerProvider.notifier,
    );

    final restored = await controller.restoreSession('template-1');

    expect(restored, isNotNull);
    final state = container.read(cookingFlowWizardControllerProvider);
    expect(state.step, CookingFlowStep.summary);
    expect(state.isRestoringSession, isFalse);
    expect(state.didInitializePortionsFromTemplate, isTrue);
    expect(state.adjustments, <String>['mehr Salz']);
    expect(state.summaryIngredients.single.name, 'Rice');
    expect(state.finalPortionCount, 6);
    expect(state.ingredientContainerAssignments, <String, String>{
      'row-rice': 'container-1',
    });
  });

  test('moves to success after finalize succeeds', () async {
    final container = _container();
    final wizard = container.read(cookingFlowWizardControllerProvider.notifier);
    final finalizeController =
        container.read(cookingFlowControllerProvider.notifier)
            as _SuccessCookingFlowController;

    wizard
      ..addSummaryIngredient(
        ingredient: _summaryIngredient,
        adjustmentIndex: null,
        containerIds: const <String>['container-1'],
      )
      ..openFinalizeStep(const <String>['container-1']);

    final result = await wizard.finalizeMeal(
      template: _template(),
      finalPortions: 4,
      containers: _containers,
    );

    expect(result.isSuccess, isTrue);
    expect(finalizeController._finalizeCalls, 1);
    expect(finalizeController._capturedSummaryIngredients.single.name, 'Rice');
    expect(finalizeController._capturedAssignments, <String, String>{
      'row-rice': 'container-1',
    });
    final state = container.read(cookingFlowWizardControllerProvider);
    expect(state.step, CookingFlowStep.success);
    expect(state.savedPreparedMealId, 'meal-1');
    expect(state.savedPreparedMealName, 'Rice Bowl');
    expect(state.savedContainerCount, 1);
  });
}

ProviderContainer _container({
  _FakeCookingFlowSessionLocalStore? store,
  FakeShoppingListRepository? shoppingRepository,
}) {
  final container = ProviderContainer(
    overrides: [
      cookingFlowSessionLocalStoreProvider.overrideWithValue(
        store ?? _FakeCookingFlowSessionLocalStore(),
      ),
      if (shoppingRepository != null)
        shoppingListRepositoryProvider.overrideWithValue(shoppingRepository),
      cookingFlowControllerProvider.overrideWith(
        _SuccessCookingFlowController.new,
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

InventoryItem _inventoryItem({required String id, required String name}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-27T12:00:00Z'),
    storeName: 'Test',
    quantity: 1,
    initialAmount: 500,
    currentAmount: 500,
    amountUnit: InventoryAmountUnit.gram,
  );
}

const _summaryIngredient = CookingFlowSummaryIngredientDraft(
  key: 'row-rice',
  name: 'Rice',
  amount: '200',
  unitCode: 'g',
  inventoryItemIds: <String>['rice'],
  kind: CookingFlowSummaryIngredientKind.template,
  sourceIngredient: '200g Rice',
);

const _containers = <CookingFlowFinalizeStorageContainerInput>[
  CookingFlowFinalizeStorageContainerInput(
    id: 'container-1',
    label: 'Topf 1',
    taraText: '100',
    grossWeightText: '700',
    taraWeight: 100,
    grossWeight: 700,
    finalNetWeight: 600,
    totalPortions: 4,
  ),
];

PreparedMeal _template() {
  final now = DateTime.parse('2026-03-27T12:00:00Z');
  return PreparedMeal(
    id: 'template-1',
    name: 'Rice Bowl',
    recipeIngredients: const <String>['200g Rice'],
    totalPortions: 4,
    remainingPortions: 4,
    totalKcal: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    createdAt: now,
    updatedAt: now,
    components: const <PreparedMealComponent>[],
  );
}

class _SuccessCookingFlowController extends CookingFlowController {
  int _finalizeCalls = 0;
  List<CookingFlowSummaryIngredientDraft> _capturedSummaryIngredients =
      const <CookingFlowSummaryIngredientDraft>[];
  Map<String, String> _capturedAssignments = const <String, String>{};

  @override
  CookingFlowControllerState build() {
    return const CookingFlowControllerState();
  }

  @override
  Future<CookingFlowFinalizeSaveResult> finalizeMeal({
    required PreparedMeal template,
    required List<CookingFlowSummaryIngredientDraft> summaryIngredients,
    required CookingFlowIntroDraft? introDraft,
    required int targetPortions,
    required int finalPortions,
    required List<CookingFlowFinalizeStorageContainerInput> containers,
    required Map<String, String> ingredientContainerAssignments,
  }) async {
    _finalizeCalls += 1;
    _capturedSummaryIngredients = summaryIngredients;
    _capturedAssignments = ingredientContainerAssignments;
    return const CookingFlowFinalizeSaveResult.success(
      preparedMealId: 'meal-1',
      containerCount: 1,
    );
  }
}

class _FakeCookingFlowSessionLocalStore
    implements CookingFlowSessionLocalStore {
  _FakeCookingFlowSessionLocalStore({this.session});

  CookingFlowSession? session;

  @override
  Future<bool> clear() async {
    session = null;
    return true;
  }

  @override
  Future<CookingFlowSession?> load() async {
    return session;
  }

  @override
  Future<bool> save(CookingFlowSession session) async {
    this.session = session;
    return true;
  }
}
