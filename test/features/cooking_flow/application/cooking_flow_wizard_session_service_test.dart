import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_session_service.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_state.dart';
import 'package:yamt/features/cooking_flow/data/'
    'cooking_flow_session_local_store.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';

void main() {
  test('defaults portion adjustment to off for new sessions', () {
    const state = CookingFlowWizardState.initial();

    expect(state.splitIntoPortions, isFalse);
  });

  test('saves wizard state into persisted session snapshot', () async {
    final store = _FakeCookingFlowSessionLocalStore();
    final container = _container(store);
    final controller = container.read(
      cookingFlowWizardSessionServiceProvider,
    );

    final saved = await controller.saveSession(
      state: _state(isRestoringSession: false),
      input: const CookingFlowWizardSessionInput(
        templateId: 'template-1',
        taraText: '300',
        taraUtensilId: 'pot-1',
        adjustmentInputText: 'salt',
        grossWeightText: '1800',
        storageContainers: <CookingFlowWizardStorageDraftInput>[
          CookingFlowWizardStorageDraftInput(
            id: 'container-1',
            label: 'Behaelter 1',
            taraText: '300',
            taraUtensilId: 'pot-1',
            grossWeightText: '1800',
            portionCount: 4,
          ),
        ],
        ingredientContainerAssignments: <String, String>{
          'template:500g Mehl': 'container-1',
        },
      ),
    );

    expect(saved, isTrue);
    expect(store.savedSession?.templateId, 'template-1');
    expect(store.savedSession?.step, CookingFlowSessionStep.summary);
    expect(store.savedSession?.summaryIngredients.single.name, 'Mehl');
    expect(store.savedSession?.storageContainers.single.taraText, '300');
    expect(
      store.savedSession?.ingredientContainerAssignments,
      <String, String>{'template:500g Mehl': 'container-1'},
    );
  });

  test('does not save while wizard is restoring session', () async {
    final store = _FakeCookingFlowSessionLocalStore();
    final container = _container(store);

    final saved = await container
        .read(cookingFlowWizardSessionServiceProvider)
        .saveSession(
          state: _state(isRestoringSession: true),
          input: const CookingFlowWizardSessionInput(
            templateId: 'template-1',
            taraText: '',
            taraUtensilId: null,
            adjustmentInputText: '',
            grossWeightText: '',
            storageContainers: <CookingFlowWizardStorageDraftInput>[],
            ingredientContainerAssignments: <String, String>{},
          ),
        );

    expect(saved, isFalse);
    expect(store.savedSession, isNull);
  });

  test('restores matching session into wizard state', () async {
    final store = _FakeCookingFlowSessionLocalStore(
      session: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.finalize,
        taraText: '300',
        taraUtensilId: 'pot-1',
        adjustmentInputText: '',
        adjustments: <String>['salt'],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[
          CookingFlowSummaryIngredientSessionDraft(
            key: 'template:500g Mehl',
            name: 'Mehl',
            amount: '500',
            unitCode: 'g',
            inventoryItemIds: <String>['flour'],
            kind: CookingFlowSummaryIngredientKind.template,
            sourceIngredient: '500g Mehl',
          ),
        ],
        grossWeightText: '1800',
        splitIntoPortions: false,
        portionCount: 4,
        finalPortionCount: 6,
        introDraft: CookingFlowIntroDraft(),
        introShoppingHandled: true,
        introShoppingBaselineInventoryItemIds: <String>['flour'],
        ingredientContainerAssignments: <String, String>{
          'template:500g Mehl': 'container-1',
        },
      ),
    );
    final container = _container(store);
    final controller = container.read(
      cookingFlowWizardSessionServiceProvider,
    );

    final restored = await controller.restoreSession('template-1');
    final state = controller.stateFromStoredSession(
      currentState: const CookingFlowWizardState.initial(),
      storedSession: restored!,
    );

    expect(state.step, CookingFlowStep.finalize);
    expect(state.isRestoringSession, isFalse);
    expect(state.didInitializePortionsFromTemplate, isTrue);
    expect(state.adjustments, <String>['salt']);
    expect(state.summaryIngredients.single.inventoryItemIds, <String>['flour']);
    expect(state.splitIntoPortions, isFalse);
    expect(state.finalPortionCount, 6);
    expect(state.introShoppingHandled, isTrue);
    expect(state.ingredientContainerAssignments, <String, String>{
      'template:500g Mehl': 'container-1',
    });
  });
}

ProviderContainer _container(_FakeCookingFlowSessionLocalStore store) {
  final container = ProviderContainer(
    overrides: [cookingFlowSessionLocalStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);
  return container;
}

CookingFlowWizardState _state({required bool isRestoringSession}) {
  return const CookingFlowWizardState.initial().copyWith(
    step: CookingFlowStep.summary,
    isRestoringSession: isRestoringSession,
    adjustments: <String>['salt'],
    summaryIngredients: const <CookingFlowSummaryIngredientDraft>[
      CookingFlowSummaryIngredientDraft(
        key: 'template:500g Mehl',
        name: 'Mehl',
        amount: '500',
        unitCode: 'g',
        inventoryItemIds: <String>['flour'],
        kind: CookingFlowSummaryIngredientKind.template,
        sourceIngredient: '500g Mehl',
      ),
    ],
    splitIntoPortions: false,
    portionCount: 4,
    finalPortionCount: 6,
    introDraft: const CookingFlowIntroDraft(),
    introShoppingHandled: true,
    introShoppingBaselineInventoryItemIds: <String>['flour'],
    ingredientContainerAssignments: <String, String>{
      'template:500g Mehl': 'container-1',
    },
  );
}

class _FakeCookingFlowSessionLocalStore
    implements CookingFlowSessionLocalStore {
  _FakeCookingFlowSessionLocalStore({this.session});

  CookingFlowSession? session;
  CookingFlowSession? savedSession;

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
    savedSession = session;
    this.session = session;
    return true;
  }
}
