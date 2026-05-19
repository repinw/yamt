import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/features/cooking_flow/application/cooking_flow_finalize_models.dart';
import 'package:yamt/features/cooking_flow/application/cooking_flow_summary_models.dart';
import 'package:yamt/features/cooking_flow/data/'
    'cooking_flow_session_local_store.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/cooking_flow/presentation/controllers/cooking_flow_controller.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';

@Dependencies([CookingFlowController])
void main() {
  test('second finalize call fails while first save is running', () async {
    final inventoryRepository = _BlockingInventoryItemRepository();
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(inventoryRepository),
        preparedMealsControllerProvider.overrideWith(
          _SuccessPreparedMealsController.new,
        ),
        cookingFlowSessionLocalStoreProvider.overrideWithValue(
          _FakeCookingFlowSessionLocalStore(),
        ),
        cookingFlowControllerProvider.overrideWith(CookingFlowController.new),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(cookingFlowControllerProvider.notifier);

    final firstResult = controller.finalizeMeal(
      template: _template(),
      summaryIngredients: _summaryIngredients,
      introDraft: null,
      targetPortions: 4,
      finalPortions: 4,
      containers: _containers,
      ingredientContainerAssignments: const <String, String>{
        'row-1': 'container-1',
      },
    );

    expect(
      container.read(cookingFlowControllerProvider).isFinalizingMeal,
      isTrue,
    );

    final secondResult = await controller.finalizeMeal(
      template: _template(),
      summaryIngredients: _summaryIngredients,
      introDraft: null,
      targetPortions: 4,
      finalPortions: 4,
      containers: _containers,
      ingredientContainerAssignments: const <String, String>{
        'row-1': 'container-1',
      },
    );

    expect(secondResult.failure, CookingFlowFinalizeSaveFailure.saveFailed);

    inventoryRepository.completeRead();
    final resolvedFirstResult = await firstResult;

    expect(resolvedFirstResult.isSuccess, isTrue);
    expect(
      container.read(cookingFlowControllerProvider).isFinalizingMeal,
      isFalse,
    );
  });
}

const _summaryIngredients = <CookingFlowSummaryIngredientDraft>[
  CookingFlowSummaryIngredientDraft(
    key: 'row-1',
    name: 'Mehl',
    amount: '500',
    unitCode: 'g',
    inventoryItemIds: <String>['flour'],
    kind: CookingFlowSummaryIngredientKind.template,
    sourceIngredient: '500g Mehl',
  ),
];

const _containers = <CookingFlowFinalizeStorageContainerInput>[
  CookingFlowFinalizeStorageContainerInput(
    id: 'container-1',
    label: 'Topf 1',
    taraText: '100',
    grossWeightText: '600',
    taraWeight: 100,
    grossWeight: 600,
    finalNetWeight: 500,
    totalPortions: 4,
  ),
];

PreparedMeal _template() {
  final now = DateTime.parse('2026-03-27T12:00:00Z');
  return PreparedMeal(
    id: 'template-1',
    name: 'Testgericht',
    recipeIngredients: const <String>['500g Mehl'],
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

class _BlockingInventoryItemRepository implements InventoryItemRepository {
  final _readCompleter = Completer<List<InventoryItem>>();

  void completeRead() {
    if (!_readCompleter.isCompleted) {
      _readCompleter.complete(const <InventoryItem>[]);
    }
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Future<List<InventoryItem>> readAll() {
    return _readCompleter.future;
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Stream<List<InventoryItem>> watchAll() {
    return const Stream<List<InventoryItem>>.empty();
  }
}

class _SuccessPreparedMealsController extends PreparedMealsController {
  @override
  FutureOr<List<PreparedMeal>> build() {
    return const <PreparedMeal>[];
  }

  @override
  Future<PreparedMealCreationResult> createPreparedMealsFromTemplateContainers({
    required PreparedMeal template,
    required int totalPortions,
    required Map<String, List<String>> recipeIngredientAssignments,
    required Map<String, RecipeIngredientAmountConversion>
    recipeIngredientAmountConversions,
    required List<PreparedMealContainerInput> containers,
    required Map<String, String> sourceKeysByIngredient,
    List<PreparedMealItemInput> additionalItems =
        const <PreparedMealItemInput>[],
  }) async {
    return PreparedMealCreationResult.successMany(
      containers.map((container) => 'meal-${container.id}').toList(),
    );
  }
}

class _FakeCookingFlowSessionLocalStore
    implements CookingFlowSessionLocalStore {
  @override
  Future<bool> clear() async {
    return true;
  }

  @override
  Future<CookingFlowSession?> load() async {
    return null;
  }

  @override
  Future<bool> save(CookingFlowSession session) async {
    return true;
  }
}
