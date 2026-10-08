import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_page_scaffold.dart';
import 'package:yamt/features/product_search_hub/data/'
    'food_estimate_repository.dart';
import 'package:yamt/features/product_search_hub/domain/food_estimate.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'food_estimate_result_page.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_ai_search_result.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_ai_search_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_route_args.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _openKey = Key('open_ai_page');
const _confirmKey = Key('inventory_item_amount_dialog_confirm_button');

class _Voice implements VoiceSearchService {
  @override
  bool get isListening => false;

  @override
  Future<VoiceSearchFailure?> startListening({
    required ValueChanged<VoiceSearchRecognition> onResult,
    required ValueChanged<bool> onListeningStateChanged,
    required ValueChanged<VoiceSearchFailure> onError,
  }) async => null;

  @override
  Future<void> stopListening() async {}

  @override
  Future<void> cancelListening() async {}
}

/// Answers every description with an apple after a real async gap.
class _Estimates implements FoodEstimateRepository {
  @override
  Future<List<FoodEstimatePhoto>> loadPhotos({
    required bool fromCamera,
  }) async => const [];

  @override
  Future<FoodEstimate> loadEstimate({
    required String description,
    required List<FoodEstimatePhoto> photos,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return const FoodEstimate(
      name: 'Apfel',
      portionGrams: 180,
      kcalLean: 85,
      kcalRich: 100,
      per100: GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
        per100Kcal: 52,
        per100Fat: 0.2,
        per100SaturatedFat: 0,
        per100Carbs: 12,
        per100Sugar: 10,
        per100Protein: 0.3,
        per100Salt: 0,
      ),
      ingredients: [
        FoodEstimateIngredient(name: 'Apfel', grams: 180, kcal: 94),
      ],
    );
  }

  @override
  Future<String> saveFoodPhoto(FoodEstimatePhoto photo) async => '';
}

/// Opens the AI page as the Vorrat's own add sheet does, and records what
/// it returns.
Future<List<ManualProductAiSearchResult?>> _pump(WidgetTester tester) async {
  final results = <ManualProductAiSearchResult?>[];
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: FilledButton(
              key: _openKey,
              onPressed: () async => results.add(
                await pushManualProductSearchPage<ManualProductAiSearchResult>(
                  context: context,
                  args: ManualProductSearchRouteArgs.aiSearch(
                    item: InventoryItem.create(
                      id: 'draft',
                      name: '',
                      entryDate: DateTime(2026, 10, 7),
                      storeName: '',
                      quantity: 1,
                    ),
                    initialPrompt: 'Apfel',
                    showEatImmediatelyOption: true,
                    initialAction:
                        InventoryReceiptManualProductAction.addToInventory,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.productSearchChildFlow,
        pageBuilder: buildManualProductSearchRoutePage,
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        foodEstimateRepositoryProvider.overrideWithValue(_Estimates()),
        voiceSearchServiceProvider.overrideWithValue(_Voice()),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 7, 12)),
      ],
      child: MaterialApp.router(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(_openKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ManualProductAiSearchPage.analyzeKey));
  await tester.pumpAndSettle();
  expect(find.byType(FoodEstimateResultPage), findsOneWidget);
  return results;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('"In Vorrat" on the AI page returns the food for the Vorrat', (
    tester,
  ) async {
    final results = await _pump(tester);

    await tester.tap(find.byKey(_confirmKey));
    await tester.pumpAndSettle();

    expect(find.byKey(_openKey), findsOneWidget);
    expect(
      results.single?.action,
      InventoryReceiptManualProductAction.addToInventory,
    );
    expect(results.single?.item.name, 'Apfel');
  });

  testWidgets('the diary icon on the AI page eats the food instead', (
    tester,
  ) async {
    final results = await _pump(tester);

    await tester.tap(find.byKey(EatPageScaffold.diaryButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(_openKey), findsOneWidget);
    expect(results.single?.action, InventoryReceiptManualProductAction.eatNow);
    expect(results.single?.eatRequest?.isPlan, isFalse);
  });

  testWidgets('the plan icon on the AI page plans the food for today', (
    tester,
  ) async {
    final results = await _pump(tester);

    await tester.tap(find.byKey(EatPageScaffold.planButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byKey(_openKey), findsOneWidget);
    expect(results.single?.action, InventoryReceiptManualProductAction.eatNow);
    expect(results.single?.eatRequest?.isPlan, isTrue);
    expect(
      dateOnly(results.single!.eatRequest!.loggedAt),
      DateTime(2026, 10, 7),
    );
  });
}
