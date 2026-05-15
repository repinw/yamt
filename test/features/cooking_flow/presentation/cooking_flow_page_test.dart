import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_controller.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_wizard_controller.dart';
import 'package:yamt/features/cooking_flow/data/'
    'cooking_flow_session_local_store.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/cooking_flow/presentation/cooking_flow_page.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_progress_indicator.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_templates_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kitchen_utensils/provider/'
    'kitchen_utensils_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _FakeCookingFlowSessionLocalStore
    implements CookingFlowSessionLocalStore {
  _FakeCookingFlowSessionLocalStore({
    this.initialSession,
    this.saveSucceeds = true,
  });

  CookingFlowSession? initialSession;
  final bool saveSucceeds;
  CookingFlowSession? savedSession;
  int saveCallCount = 0;
  int clearCallCount = 0;

  @override
  Future<CookingFlowSession?> load() async {
    return initialSession;
  }

  @override
  Future<bool> save(CookingFlowSession session) async {
    saveCallCount += 1;
    if (!saveSucceeds) {
      return false;
    }
    savedSession = session;
    initialSession = session;
    return true;
  }

  @override
  Future<bool> clear() async {
    clearCallCount += 1;
    initialSession = null;
    return true;
  }
}

class _StaticPreparedMealTemplatesController
    extends PreparedMealTemplatesController {
  _StaticPreparedMealTemplatesController(this._templates);

  final List<PreparedMeal> _templates;

  @override
  FutureOr<List<PreparedMeal>> build() {
    return List<PreparedMeal>.from(_templates);
  }
}

class _StaticInventoryItemsController extends InventoryItemsController {
  _StaticInventoryItemsController(this._items);

  final List<InventoryItem> _items;

  @override
  FutureOr<List<InventoryItem>> build() {
    return List<InventoryItem>.from(_items);
  }
}

class _FakeInventoryItemRepository implements InventoryItemRepository {
  _FakeInventoryItemRepository(this.items);

  final List<InventoryItem> items;

  @override
  Stream<List<InventoryItem>> watchAll() {
    return Stream<List<InventoryItem>>.value(items);
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return List<InventoryItem>.from(items);
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    return true;
  }
}

class _CapturingPreparedMealsController extends PreparedMealsController {
  _CapturingPreparedMealsController({
    required PreparedMealCreationResult result,
  }) : _result = result;

  final PreparedMealCreationResult _result;
  Map<String, List<String>>? _capturedAssignments;
  List<PreparedMealContainerInput>? _capturedContainers;
  int? _capturedFinalNetWeight;
  int? _capturedTotalPortions;
  int? _capturedTemplatePortions;

  @override
  FutureOr<List<PreparedMeal>> build() {
    return const <PreparedMeal>[];
  }

  @override
  Future<PreparedMealCreationResult> createPreparedMealFromTemplate({
    required PreparedMeal template,
    required int totalPortions,
    required Map<String, List<String>> recipeIngredientAssignments,
    required Map<String, RecipeIngredientAmountConversion>
    recipeIngredientAmountConversions,
    List<PreparedMealItemInput> additionalItems =
        const <PreparedMealItemInput>[],
    int? finalNetWeight,
    Map<String, String> sourceKeysByIngredient = const <String, String>{},
  }) async {
    _capturedAssignments = recipeIngredientAssignments;
    _capturedFinalNetWeight = finalNetWeight;
    _capturedTotalPortions = totalPortions;
    _capturedTemplatePortions = template.totalPortions;
    return _result;
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
    _capturedAssignments = recipeIngredientAssignments;
    _capturedContainers = containers;
    _capturedFinalNetWeight = containers.isEmpty
        ? null
        : containers.first.finalNetWeight;
    _capturedTotalPortions = totalPortions;
    _capturedTemplatePortions = template.totalPortions;
    return _result;
  }
}

class _StaticKitchenUtensilsController extends KitchenUtensilsController {
  _StaticKitchenUtensilsController(this._utensils);

  final List<KitchenUtensil> _utensils;

  @override
  FutureOr<List<KitchenUtensil>> build() {
    return List<KitchenUtensil>.from(_utensils);
  }
}

class _FakeCookingFlowVoiceSearchService implements VoiceSearchService {
  var _isListening = false;
  ValueChanged<VoiceSearchRecognition>? _onResult;
  ValueChanged<bool>? _onListeningStateChanged;
  ValueChanged<VoiceSearchFailure>? _onError;

  @override
  bool get isListening => _isListening;

  @override
  Future<VoiceSearchFailure?> startListening({
    required ValueChanged<VoiceSearchRecognition> onResult,
    required ValueChanged<bool> onListeningStateChanged,
    required ValueChanged<VoiceSearchFailure> onError,
  }) async {
    _onResult = onResult;
    _onListeningStateChanged = onListeningStateChanged;
    _onError = onError;
    _isListening = true;
    onListeningStateChanged(true);
    return null;
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
    _onListeningStateChanged?.call(false);
  }

  @override
  Future<void> cancelListening() async {
    _isListening = false;
    _onListeningStateChanged?.call(false);
  }

  void emitTranscript(String transcript) {
    _onResult?.call(
      VoiceSearchRecognition(transcript: transcript, isFinal: true),
    );
  }

  void emitError(VoiceSearchFailure failure) {
    _onError?.call(failure);
  }
}

PreparedMeal _template({
  required String id,
  String name = 'Herzhafter Linseneintopf',
  List<String> recipeIngredients = const <String>['300g Linsen'],
  int totalPortions = 4,
}) {
  return PreparedMeal(
    id: id,
    name: name,
    recipeIngredients: recipeIngredients,
    totalPortions: totalPortions,
    remainingPortions: totalPortions,
    totalKcal: 400,
    totalProtein: 20,
    totalCarbs: 40,
    totalFat: 10,
    createdAt: DateTime.parse('2026-03-27T12:00:00Z'),
    updatedAt: DateTime.parse('2026-03-27T12:00:00Z'),
    components: const <PreparedMealComponent>[],
  );
}

InventoryItem _inventoryItem({
  required String id,
  required String name,
  required int amount,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-27T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialAmount: amount,
    currentAmount: amount,
    amountUnit: InventoryAmountUnit.gram,
  );
}

KitchenUtensil _kitchenUtensil({
  required String id,
  required String name,
  required int weightGrams,
}) {
  return KitchenUtensil(
    id: id,
    name: name,
    weightGrams: weightGrams,
    createdAt: DateTime.parse('2026-03-27T10:00:00Z'),
    updatedAt: DateTime.parse('2026-03-27T10:00:00Z'),
  );
}

@Dependencies([
  CookingFlowController,
  CookingFlowWizardController,
  InventoryItemsController,
])
Widget _buildHarness({
  required _FakeCookingFlowSessionLocalStore sessionStore,
  required List<PreparedMeal> templates,
  List<InventoryItem> inventoryItems = const <InventoryItem>[],
  List<KitchenUtensil> kitchenUtensils = const <KitchenUtensil>[],
  VoiceSearchService? voiceSearchService,
  _CapturingPreparedMealsController? preparedMealsController,
}) {
  final controller =
      preparedMealsController ??
      _CapturingPreparedMealsController(
        result: const PreparedMealCreationResult.failure(
          PreparedMealCreationFailureReason.invalidInput,
        ),
      );

  final container = ProviderContainer(
    overrides: [
      cookingFlowSessionLocalStoreProvider.overrideWithValue(sessionStore),
      preparedMealTemplatesControllerProvider.overrideWith(
        () => _StaticPreparedMealTemplatesController(templates),
      ),
      inventoryItemsControllerProvider.overrideWith(
        () => _StaticInventoryItemsController(inventoryItems),
      ),
      inventoryItemRepositoryProvider.overrideWithValue(
        _FakeInventoryItemRepository(inventoryItems),
      ),
      preparedMealsControllerProvider.overrideWith(() => controller),
      cookingFlowControllerProvider.overrideWith(CookingFlowController.new),
      kitchenUtensilsControllerProvider.overrideWith(
        () => _StaticKitchenUtensilsController(kitchenUtensils),
      ),
      if (voiceSearchService != null)
        voiceSearchServiceProvider.overrideWithValue(voiceSearchService),
    ],
  );
  addTearDown(container.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CookingFlowPage(templateId: templates.single.id),
    ),
  );
}

@Dependencies([
  CookingFlowController,
  CookingFlowWizardController,
  InventoryItemsController,
])
Widget _buildRouterHarness({
  required _FakeCookingFlowSessionLocalStore sessionStore,
  required List<PreparedMeal> templates,
  List<KitchenUtensil> kitchenUtensils = const <KitchenUtensil>[],
}) {
  final container = ProviderContainer(
    overrides: [
      cookingFlowSessionLocalStoreProvider.overrideWithValue(sessionStore),
      preparedMealTemplatesControllerProvider.overrideWith(
        () => _StaticPreparedMealTemplatesController(templates),
      ),
      inventoryItemsControllerProvider.overrideWith(
        () => _StaticInventoryItemsController(const <InventoryItem>[]),
      ),
      inventoryItemRepositoryProvider.overrideWithValue(
        _FakeInventoryItemRepository(const <InventoryItem>[]),
      ),
      preparedMealsControllerProvider.overrideWith(
        () => _CapturingPreparedMealsController(
          result: const PreparedMealCreationResult.failure(
            PreparedMealCreationFailureReason.invalidInput,
          ),
        ),
      ),
      cookingFlowControllerProvider.overrideWith(CookingFlowController.new),
      kitchenUtensilsControllerProvider.overrideWith(
        () => _StaticKitchenUtensilsController(kitchenUtensils),
      ),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.homeInventoryTemplateDetailPath(
      templates.single.id,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.homeInventoryTemplateDetail,
        builder: (context, state) {
          return CookingFlowPage(
            templateId: state.pathParameters['templateId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.homeInventoryTemplates,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Template list route')),
        ),
      ),
      GoRoute(
        path: AppRoutes.homeKitchenUtensils,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Kitchen utensil route')),
        ),
      ),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

@Dependencies([
  CookingFlowController,
  CookingFlowWizardController,
  InventoryItemsController,
])
void main() {
  testWidgets('start back leaves cookflow when session save fails', (
    tester,
  ) async {
    final sessionStore = _FakeCookingFlowSessionLocalStore(
      saveSucceeds: false,
    );

    await tester.pumpWidget(
      _buildRouterHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[_template(id: 'template-1')],
      ),
    );
    await tester.pumpAndSettle();

    final saveCallCountBeforeBack = sessionStore.saveCallCount;

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(sessionStore.saveCallCount, greaterThan(saveCallCountBeforeBack));
    expect(find.text('Template list route'), findsOneWidget);
  });

  testWidgets('restored intro shopping selection shows shopping CTA', (
    tester,
  ) async {
    final sessionStore = _FakeCookingFlowSessionLocalStore(
      initialSession: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.start,
        taraText: '1000',
        adjustmentInputText: '',
        adjustments: <String>[],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[],
        grossWeightText: '',
        splitIntoPortions: true,
        portionCount: 3,
        introDraft: CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: '300g Linsen',
              action: CookingFlowIntroRowAction.shoppingCart,
            ),
          ],
        ),
        introShoppingHandled: false,
        introShoppingBaselineInventoryItemIds: <String>[],
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[_template(id: 'template-1')],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Zur Einkaufsliste hinzufügen und später fortsetzen'),
      findsOneWidget,
    );
    expect(find.text('Später'), findsOneWidget);
  });

  testWidgets('restores preparation step from saved session', (tester) async {
    final sessionStore = _FakeCookingFlowSessionLocalStore(
      initialSession: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.preparation,
        taraText: '777',
        adjustmentInputText: '',
        adjustments: <String>[],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[],
        grossWeightText: '',
        splitIntoPortions: true,
        portionCount: 3,
        introDraft: CookingFlowIntroDraft(),
        introShoppingHandled: false,
        introShoppingBaselineInventoryItemIds: <String>[],
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[_template(id: 'template-1')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Phase 1 / 4'), findsNothing);
    expect(find.byKey(cookingFlowProgressIndicatorKey), findsOneWidget);
    expect(find.text('1. Vorbereitung'), findsOneWidget);
    expect(find.text('777'), findsOneWidget);
    expect(find.text('Originalrezept: 4 Portionen'), findsNothing);
  });

  testWidgets('preparation applies saved utensil tare and persists session', (
    tester,
  ) async {
    final sessionStore = _FakeCookingFlowSessionLocalStore(
      initialSession: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.preparation,
        taraText: '777',
        adjustmentInputText: '',
        adjustments: <String>[],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[],
        grossWeightText: '',
        splitIntoPortions: true,
        portionCount: 3,
        introDraft: CookingFlowIntroDraft(),
        introShoppingHandled: false,
        introShoppingBaselineInventoryItemIds: <String>[],
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[_template(id: 'template-1')],
        kitchenUtensils: <KitchenUtensil>[
          _kitchenUtensil(
            id: 'pot-1',
            name: 'Suppentopf',
            weightGrams: 420,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Suppentopf'), findsOneWidget);
    expect(find.text('420 g'), findsOneWidget);

    final selectedPot = find.byKey(const Key('cookflow_tare_utensil_pot-1'));
    await tester.ensureVisible(selectedPot);
    await tester.pumpAndSettle();
    await tester.tap(selectedPot);
    await tester.pumpAndSettle();

    expect(find.text('420'), findsOneWidget);
    expect(sessionStore.savedSession?.taraText, '420');
    expect(sessionStore.savedSession?.taraUtensilId, 'pot-1');
  });

  testWidgets('preparation can add and assign multiple containers', (
    tester,
  ) async {
    final sessionStore = _FakeCookingFlowSessionLocalStore(
      initialSession: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.preparation,
        taraText: '777',
        adjustmentInputText: '',
        adjustments: <String>[],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[],
        grossWeightText: '',
        splitIntoPortions: true,
        portionCount: 3,
        introDraft: CookingFlowIntroDraft(),
        introShoppingHandled: false,
        introShoppingBaselineInventoryItemIds: <String>[],
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[_template(id: 'template-1')],
        kitchenUtensils: <KitchenUtensil>[
          _kitchenUtensil(
            id: 'pot-1',
            name: 'Suppentopf',
            weightGrams: 420,
          ),
          _kitchenUtensil(
            id: 'pot-2',
            name: 'Saucenbox',
            weightGrams: 180,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Behälter',
      ),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Behälter hinzufügen'));
    await tester.pumpAndSettle();

    final secondPot = find.byKey(const Key('cookflow_tare_utensil_pot-2')).last;
    await tester.ensureVisible(secondPot);
    await tester.pumpAndSettle();
    await tester.tap(secondPot);
    await tester.pumpAndSettle();

    expect(sessionStore.savedSession?.storageContainers, hasLength(2));
    expect(
      sessionStore.savedSession?.storageContainers.last.label,
      'Saucenbox',
    );
    expect(sessionStore.savedSession?.storageContainers.last.taraText, '180');
    expect(
      sessionStore.savedSession?.storageContainers.last.taraUtensilId,
      'pot-2',
    );

    final removeContainerButton = find
        .byIcon(Icons.delete_outline_rounded)
        .last;
    await tester.ensureVisible(removeContainerButton);
    await tester.pumpAndSettle();
    await tester.tap(removeContainerButton);
    await tester.pumpAndSettle();

    expect(sessionStore.savedSession?.storageContainers, hasLength(1));
  });

  testWidgets('preparation opens utensil library route after saving session', (
    tester,
  ) async {
    final sessionStore = _FakeCookingFlowSessionLocalStore(
      initialSession: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.preparation,
        taraText: '321',
        adjustmentInputText: '',
        adjustments: <String>[],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[],
        grossWeightText: '',
        splitIntoPortions: true,
        portionCount: 3,
        introDraft: CookingFlowIntroDraft(),
        introShoppingHandled: false,
        introShoppingBaselineInventoryItemIds: <String>[],
      ),
    );

    await tester.pumpWidget(
      _buildRouterHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[_template(id: 'template-1')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Utensil hinzufügen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Utensil hinzufügen'));
    await tester.pumpAndSettle();

    expect(find.text('Kitchen utensil route'), findsOneWidget);
    expect(sessionStore.savedSession?.taraText, '321');
  });

  testWidgets('preparation can swap selected cooking utensil', (tester) async {
    final sessionStore = _FakeCookingFlowSessionLocalStore(
      initialSession: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.preparation,
        taraText: '420',
        taraUtensilId: 'pot-1',
        adjustmentInputText: '',
        adjustments: <String>[],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[],
        grossWeightText: '2500',
        splitIntoPortions: true,
        portionCount: 3,
        introDraft: CookingFlowIntroDraft(),
        introShoppingHandled: false,
        introShoppingBaselineInventoryItemIds: <String>[],
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[_template(id: 'template-1')],
        kitchenUtensils: <KitchenUtensil>[
          _kitchenUtensil(
            id: 'pot-1',
            name: 'Suppentopf',
            weightGrams: 420,
          ),
          _kitchenUtensil(
            id: 'pot-2',
            name: 'Bräter',
            weightGrams: 800,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gespeicherte Utensilien'), findsOneWidget);
    expect(find.text('Suppentopf'), findsOneWidget);

    final secondPot = find.byKey(const Key('cookflow_tare_utensil_pot-2'));
    await tester.ensureVisible(secondPot);
    await tester.pumpAndSettle();
    await tester.tap(secondPot);
    await tester.pumpAndSettle();

    expect(sessionStore.savedSession?.taraText, '800');
    expect(sessionStore.savedSession?.taraUtensilId, 'pot-2');
  });

  testWidgets('finalize does not show utensil library controls', (
    tester,
  ) async {
    final sessionStore = _FakeCookingFlowSessionLocalStore(
      initialSession: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.finalize,
        taraText: '420',
        taraUtensilId: 'pot-1',
        adjustmentInputText: '',
        adjustments: <String>[],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[],
        grossWeightText: '2500',
        splitIntoPortions: true,
        portionCount: 3,
        introDraft: CookingFlowIntroDraft(),
        introShoppingHandled: false,
        introShoppingBaselineInventoryItemIds: <String>[],
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[_template(id: 'template-1')],
        kitchenUtensils: <KitchenUtensil>[
          _kitchenUtensil(
            id: 'pot-1',
            name: 'Suppentopf',
            weightGrams: 420,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Utensil hinzufügen'), findsNothing);
    expect(find.text('Gespeicherte Utensilien'), findsNothing);
  });

  testWidgets('intro portion scaler scales assignment amounts', (
    tester,
  ) async {
    final sessionStore = _FakeCookingFlowSessionLocalStore(
      initialSession: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.start,
        taraText: '1000',
        adjustmentInputText: '',
        adjustments: <String>[],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[],
        grossWeightText: '',
        splitIntoPortions: true,
        portionCount: 6,
        introDraft: CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: '300g Linsen',
              action: CookingFlowIntroRowAction.assigned,
              selections: <CookingFlowIntroSelectionDraft>[
                CookingFlowIntroSelectionDraft(itemId: 'item-1'),
              ],
            ),
          ],
        ),
        introShoppingHandled: false,
        introShoppingBaselineInventoryItemIds: <String>[],
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[_template(id: 'template-1')],
        inventoryItems: <InventoryItem>[
          _inventoryItem(id: 'item-1', name: 'Linsen', amount: 1000),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Originalrezept: 4 Portionen'), findsOneWidget);
    expect(find.text('450 g'), findsOneWidget);

    await tester.tap(find.text('Flow starten'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    expect(find.text('450'), findsOneWidget);
  });

  testWidgets('intro portion input has no upper limit', (tester) async {
    final sessionStore = _FakeCookingFlowSessionLocalStore(
      initialSession: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.start,
        taraText: '1000',
        adjustmentInputText: '',
        adjustments: <String>[],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[],
        grossWeightText: '',
        splitIntoPortions: true,
        portionCount: 6,
        introDraft: CookingFlowIntroDraft(),
        introShoppingHandled: false,
        introShoppingBaselineInventoryItemIds: <String>[],
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[_template(id: 'template-1')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '100');
    await tester.pumpAndSettle();

    expect(find.text('7500 g'), findsOneWidget);
  });

  testWidgets('intro keeps fractional piece amounts', (tester) async {
    final sessionStore = _FakeCookingFlowSessionLocalStore();

    await tester.pumpWidget(
      _buildHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[
          _template(
            id: 'template-1',
            recipeIngredients: const <String>['1,5 Stück Zwiebeln'],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1.5'), findsOneWidget);
  });

  testWidgets('intro converts piece requirement to inventory grams', (
    tester,
  ) async {
    final sessionStore = _FakeCookingFlowSessionLocalStore(
      initialSession: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.start,
        taraText: '1000',
        adjustmentInputText: '',
        adjustments: <String>[],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[],
        grossWeightText: '',
        splitIntoPortions: true,
        portionCount: 4,
        introDraft: CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: '2 Stück Speisezwiebeln',
              action: CookingFlowIntroRowAction.assigned,
              selections: <CookingFlowIntroSelectionDraft>[
                CookingFlowIntroSelectionDraft(itemId: 'onions'),
              ],
            ),
          ],
        ),
        introShoppingHandled: false,
        introShoppingBaselineInventoryItemIds: <String>[],
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[
          _template(
            id: 'template-1',
            recipeIngredients: const <String>['2 Stück Speisezwiebeln'],
          ),
        ],
        inventoryItems: <InventoryItem>[
          _inventoryItem(id: 'onions', name: 'Speisezwiebeln', amount: 500),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Einheiten-Konflikt'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Umrechnen'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Umrechnen'));
    await tester.pumpAndSettle();

    expect(find.text('200 g'), findsOneWidget);
    expect(find.text('Abzug 200g · übrig 300g'), findsOneWidget);
  });

  testWidgets('intro ingredient edit is flow-local', (tester) async {
    final sessionStore = _FakeCookingFlowSessionLocalStore(
      initialSession: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.start,
        taraText: '1000',
        adjustmentInputText: '',
        adjustments: <String>[],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[],
        grossWeightText: '',
        splitIntoPortions: true,
        portionCount: 4,
        introDraft: CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: '500g Hackfleisch',
              action: CookingFlowIntroRowAction.assigned,
              selections: <CookingFlowIntroSelectionDraft>[
                CookingFlowIntroSelectionDraft(itemId: 'hack'),
              ],
            ),
          ],
        ),
        introShoppingHandled: false,
        introShoppingBaselineInventoryItemIds: <String>[],
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[
          _template(
            id: 'template-1',
            recipeIngredients: const <String>['500g Hackfleisch'],
          ),
        ],
        inventoryItems: <InventoryItem>[
          _inventoryItem(id: 'hack', name: 'Hackfleisch', amount: 1500),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byIcon(Icons.edit_outlined).first,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();

    final sheetFields = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(sheetFields.at(1), '800');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speichern').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Flow starten'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    expect(find.text('800'), findsOneWidget);
    expect(
      sessionStore.savedSession?.introDraft.rowStates.single.editedAmountLabel,
      '800 g',
    );
  });

  testWidgets('cooking phase voice input fills and adds on-the-fly note', (
    tester,
  ) async {
    final voiceSearchService = _FakeCookingFlowVoiceSearchService();
    final sessionStore = _FakeCookingFlowSessionLocalStore(
      initialSession: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.cooking,
        taraText: '1000',
        adjustmentInputText: '',
        adjustments: <String>[],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[],
        grossWeightText: '',
        splitIntoPortions: true,
        portionCount: 3,
        introDraft: CookingFlowIntroDraft(),
        introShoppingHandled: false,
        introShoppingBaselineInventoryItemIds: <String>[],
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[_template(id: 'template-1')],
        voiceSearchService: voiceSearchService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cookflow_on_the_fly_voice_button')));
    await tester.pump();
    voiceSearchService.emitTranscript('50 g Butter');
    await tester.pump();

    final field = tester.widget<TextField>(
      find.byKey(const Key('cookflow_on_the_fly_field')),
    );
    expect(field.controller?.text, '50 g Butter');

    await tester.tap(find.byKey(const Key('cookflow_on_the_fly_add_button')));
    await tester.pumpAndSettle();

    expect(find.text('50 g Butter'), findsOneWidget);
    expect(sessionStore.savedSession?.adjustments, <String>['50 g Butter']);
  });

  testWidgets('cooking phase removes on-the-fly note from recent list', (
    tester,
  ) async {
    final sessionStore = _FakeCookingFlowSessionLocalStore(
      initialSession: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.cooking,
        taraText: '1000',
        adjustmentInputText: '',
        adjustments: <String>[
          '100 g Erbsen',
          '50 g Butter',
          '1 TL Salz',
        ],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[],
        grossWeightText: '',
        splitIntoPortions: true,
        portionCount: 3,
        introDraft: CookingFlowIntroDraft(),
        introShoppingHandled: false,
        introShoppingBaselineInventoryItemIds: <String>[],
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[_template(id: 'template-1')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('cookflow_on_the_fly_remove_button')).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('50 g Butter'), findsNothing);
    expect(
      sessionStore.savedSession?.adjustments,
      <String>['100 g Erbsen', '1 TL Salz'],
    );
  });

  testWidgets('cooking phase voice input shows permission failure', (
    tester,
  ) async {
    final voiceSearchService = _FakeCookingFlowVoiceSearchService();
    final sessionStore = _FakeCookingFlowSessionLocalStore(
      initialSession: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.cooking,
        taraText: '1000',
        adjustmentInputText: '',
        adjustments: <String>[],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[],
        grossWeightText: '',
        splitIntoPortions: true,
        portionCount: 3,
        introDraft: CookingFlowIntroDraft(),
        introShoppingHandled: false,
        introShoppingBaselineInventoryItemIds: <String>[],
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[_template(id: 'template-1')],
        voiceSearchService: voiceSearchService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cookflow_on_the_fly_voice_button')));
    await tester.pump();
    voiceSearchService.emitError(VoiceSearchFailure.permissionDenied);
    await tester.pump();

    expect(
      find.text(
        'Bitte erlaube Mikrofonzugriff, um die Spracheingabe zu verwenden.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('summary add ingredient button adds inventory item', (
    tester,
  ) async {
    final inventoryItem = _inventoryItem(
      id: 'butter',
      name: 'Butter',
      amount: 200,
    );
    final sessionStore = _FakeCookingFlowSessionLocalStore(
      initialSession: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.summary,
        taraText: '1000',
        adjustmentInputText: '',
        adjustments: <String>[],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[],
        grossWeightText: '',
        splitIntoPortions: true,
        portionCount: 3,
        introDraft: CookingFlowIntroDraft(),
        introShoppingHandled: false,
        introShoppingBaselineInventoryItemIds: <String>[],
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[_template(id: 'template-1')],
        inventoryItems: <InventoryItem>[inventoryItem],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('cookflow_summary_add_ingredient_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('cookflow_summary_add_source_inventory')).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('cookflow_summary_inventory_item_butter')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Butter'), findsWidgets);
    expect(
      sessionStore.savedSession?.summaryIngredients.single.name,
      'Butter',
    );
    expect(
      sessionStore.savedSession?.summaryIngredients.single.inventoryItemIds,
      <String>['butter'],
    );
  });

  testWidgets('summary unresolved adjustment can choose inventory item', (
    tester,
  ) async {
    final inventoryItem = _inventoryItem(
      id: 'butter',
      name: 'Butter',
      amount: 200,
    );
    final sessionStore = _FakeCookingFlowSessionLocalStore(
      initialSession: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.summary,
        taraText: '1000',
        adjustmentInputText: '',
        adjustments: <String>['50g Butter'],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[],
        grossWeightText: '',
        splitIntoPortions: true,
        portionCount: 3,
        introDraft: CookingFlowIntroDraft(),
        introShoppingHandled: false,
        introShoppingBaselineInventoryItemIds: <String>[],
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[_template(id: 'template-1')],
        inventoryItems: <InventoryItem>[inventoryItem],
      ),
    );
    await tester.pumpAndSettle();

    final adjustmentButton = find.byKey(
      const Key('cookflow_summary_adjustment_add_button'),
    );
    await tester.ensureVisible(adjustmentButton);
    await tester.pumpAndSettle();
    await tester.tap(adjustmentButton);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('cookflow_summary_add_source_inventory')).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('cookflow_summary_inventory_item_butter')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ungelöste Anpassungen'), findsNothing);
    expect(sessionStore.savedSession?.adjustments, <String>[]);
    expect(
      sessionStore.savedSession?.summaryIngredients.single.name,
      'Butter',
    );
    expect(
      sessionStore.savedSession?.summaryIngredients.single.amount,
      '50',
    );
  });

  testWidgets('intro parses embedded package weights from imports', (
    tester,
  ) async {
    final sessionStore = _FakeCookingFlowSessionLocalStore();

    await tester.pumpWidget(
      _buildHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[
          _template(
            id: 'template-1',
            recipeIngredients: const <String>[
              '1 Dose Tomaten, passiert (ca 800g)',
            ],
          ),
        ],
        inventoryItems: <InventoryItem>[
          _inventoryItem(
            id: 'tomatoes',
            name: 'Tomaten, passiert',
            amount: 800,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tomaten, passiert'), findsOneWidget);
    expect(find.text('1x 800g'), findsOneWidget);
  });

  testWidgets('intro shows subtracted and remaining inventory amounts', (
    tester,
  ) async {
    final sessionStore = _FakeCookingFlowSessionLocalStore(
      initialSession: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.start,
        taraText: '1000',
        adjustmentInputText: '',
        adjustments: <String>[],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[],
        grossWeightText: '',
        splitIntoPortions: true,
        portionCount: 3,
        introDraft: CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: '1 Dose Tomaten, passiert (ca 800g)',
              action: CookingFlowIntroRowAction.assigned,
              selections: <CookingFlowIntroSelectionDraft>[
                CookingFlowIntroSelectionDraft(itemId: 'tomatoes'),
              ],
            ),
          ],
        ),
        introShoppingHandled: false,
        introShoppingBaselineInventoryItemIds: <String>[],
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[
          _template(
            id: 'template-1',
            recipeIngredients: const <String>[
              '1 Dose Tomaten, passiert (ca 800g)',
            ],
          ),
        ],
        inventoryItems: <InventoryItem>[
          _inventoryItem(
            id: 'tomatoes',
            name: 'Tomaten, passiert',
            amount: 1000,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Abzug 600g · übrig 400g'), findsOneWidget);
  });

  testWidgets('finalize save uses parsed imported package weights', (
    tester,
  ) async {
    final inventoryItem = _inventoryItem(
      id: 'tomatoes',
      name: 'Tomaten, passiert',
      amount: 800,
    );
    final preparedMealsController = _CapturingPreparedMealsController(
      result: const PreparedMealCreationResult.success('meal-1'),
    );
    final sessionStore = _FakeCookingFlowSessionLocalStore(
      initialSession: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.finalize,
        taraText: '1000',
        adjustmentInputText: '',
        adjustments: <String>[],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[],
        grossWeightText: '2500',
        splitIntoPortions: true,
        portionCount: 3,
        introDraft: CookingFlowIntroDraft(
          rowStates: <CookingFlowIntroRowDraft>[
            CookingFlowIntroRowDraft(
              rawIngredient: '1 Dose Tomaten, passiert (ca 800g)',
              action: CookingFlowIntroRowAction.assigned,
              selections: <CookingFlowIntroSelectionDraft>[
                CookingFlowIntroSelectionDraft(itemId: 'tomatoes'),
              ],
            ),
          ],
        ),
        introShoppingHandled: false,
        introShoppingBaselineInventoryItemIds: <String>[],
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[
          _template(
            id: 'template-1',
            recipeIngredients: const <String>[
              '1 Dose Tomaten, passiert (ca 800g)',
            ],
          ),
        ],
        inventoryItems: <InventoryItem>[inventoryItem],
        preparedMealsController: preparedMealsController,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mahlzeit speichern'));
    await tester.pumpAndSettle();

    expect(
      preparedMealsController._capturedAssignments,
      <String, List<String>>{
        '600g Tomaten, passiert': <String>['tomatoes'],
      },
    );
    expect(preparedMealsController._capturedTotalPortions, 3);
    expect(preparedMealsController._capturedTemplatePortions, 3);
  });

  testWidgets('finalize save success clears session and shows success page', (
    tester,
  ) async {
    final inventoryItem = _inventoryItem(
      id: 'item-1',
      name: 'Linsen',
      amount: 300,
    );
    final preparedMealsController = _CapturingPreparedMealsController(
      result: const PreparedMealCreationResult.success('meal-1'),
    );
    final sessionStore = _FakeCookingFlowSessionLocalStore(
      initialSession: const CookingFlowSession(
        templateId: 'template-1',
        step: CookingFlowSessionStep.finalize,
        taraText: '1000',
        adjustmentInputText: '',
        adjustments: <String>[],
        summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[
          CookingFlowSummaryIngredientSessionDraft(
            key: 'template-ingredient-1',
            name: 'Linsen',
            amount: '300',
            unitCode: 'g',
            inventoryItemIds: <String>['item-1'],
            kind: CookingFlowSummaryIngredientKind.template,
            sourceIngredient: '300g Linsen',
          ),
        ],
        grossWeightText: '2500',
        splitIntoPortions: true,
        portionCount: 3,
        introDraft: CookingFlowIntroDraft(),
        introShoppingHandled: false,
        introShoppingBaselineInventoryItemIds: <String>[],
      ),
    );

    await tester.pumpWidget(
      _buildHarness(
        sessionStore: sessionStore,
        templates: <PreparedMeal>[_template(id: 'template-1')],
        inventoryItems: <InventoryItem>[inventoryItem],
        preparedMealsController: preparedMealsController,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mahlzeit speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Mahlzeit gespeichert'), findsOneWidget);
    expect(find.text('Herzhafter Linseneintopf'), findsOneWidget);
    expect(sessionStore.clearCallCount, 1);
    expect(preparedMealsController._capturedFinalNetWeight, 1500);
    expect(
      preparedMealsController._capturedAssignments,
      <String, List<String>>{
        '300g Linsen': <String>['item-1'],
      },
    );
  });

  testWidgets(
    'finalize save without portions keeps base portions and net weight',
    (
      tester,
    ) async {
      final inventoryItem = _inventoryItem(
        id: 'item-1',
        name: 'Linsen',
        amount: 300,
      );
      final preparedMealsController = _CapturingPreparedMealsController(
        result: const PreparedMealCreationResult.success('meal-1'),
      );
      final sessionStore = _FakeCookingFlowSessionLocalStore(
        initialSession: const CookingFlowSession(
          templateId: 'template-1',
          step: CookingFlowSessionStep.finalize,
          taraText: '1000',
          adjustmentInputText: '',
          adjustments: <String>[],
          summaryIngredients: <CookingFlowSummaryIngredientSessionDraft>[
            CookingFlowSummaryIngredientSessionDraft(
              key: 'template-ingredient-1',
              name: 'Linsen',
              amount: '300',
              unitCode: 'g',
              inventoryItemIds: <String>['item-1'],
              kind: CookingFlowSummaryIngredientKind.template,
              sourceIngredient: '300g Linsen',
            ),
          ],
          grossWeightText: '2500',
          splitIntoPortions: false,
          portionCount: 3,
          introDraft: CookingFlowIntroDraft(),
          introShoppingHandled: false,
          introShoppingBaselineInventoryItemIds: <String>[],
        ),
      );

      await tester.pumpWidget(
        _buildHarness(
          sessionStore: sessionStore,
          templates: <PreparedMeal>[_template(id: 'template-1')],
          inventoryItems: <InventoryItem>[inventoryItem],
          preparedMealsController: preparedMealsController,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mahlzeit speichern'));
      await tester.pumpAndSettle();

      expect(preparedMealsController._capturedFinalNetWeight, 1500);
      expect(preparedMealsController._capturedTotalPortions, 3);
      expect(preparedMealsController._capturedTemplatePortions, 3);
      expect(
        preparedMealsController._capturedContainers?.single.totalPortions,
        3,
      );
    },
  );
}
