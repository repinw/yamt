import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/inventory/data/cooked_meal_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kitchen_utensils/application/kitchen_utensil_list_provider.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kochmodus/application/cook_run_shopping_service.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_controller.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_timer_controller.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/recipes/application/cook_run_providers.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/data/cook_run_repository.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_names_service.dart';

import '../../../../helpers/fake_signed_in_user.dart';
import '../../../../helpers/memory_app_preferences.dart';
import '../../../../support/prepared_meal_test_data.dart';
import '../../../shoppinglist/support/fake_shopping_list_repository.dart';
import '../../application/cook_services_harness.dart';

/// The fixed moment of the controller tests.
final kochmodusNow = DateTime.utc(2026, 11, 7, 12);

/// The kitchen utensil [id] that weighs [grams].
KitchenUtensil utensil(String id, {int grams = 900}) => KitchenUtensil(
  id: id,
  name: 'Topf $id',
  weightGrams: grams,
  createdAt: kochmodusNow,
  updatedAt: kochmodusNow,
);

/// One household of a controller test: the real cook run repositories on
/// `fake_cloud_firestore`, a cookbook with the recipe `t1`, and the
/// container that the controller of a target runs in.
class KochmodusHarness {
  new _(this.cook, this.preferences, this.shoppingList) {
    cook.templates.templates = [
      preparedMealTestData(
        id: 't1',
        name: 'Eintopf',
        totalPortions: 4,
      ).copyWith(
        recipeIngredients: const ['200 g Reis', 'Salz'],
        recipeInstructions: const ['Kochen'],
      ),
    ];
  }

  /// Opens the household.
  static Future<KochmodusHarness> open() async {
    final harness = KochmodusHarness._(
      await CookHarness.open(),
      MemoryAppPreferences(),
      FakeShoppingListRepository(),
    );
    addTearDown(harness.shoppingList.dispose);
    return harness;
  }

  /// The household of the cook services.
  final CookHarness cook;

  /// The preferences of this device.
  final MemoryAppPreferences preferences;

  /// The shopping list "Pausieren" writes to.
  final FakeShoppingListRepository shoppingList;

  /// The utensils the household has.
  List<KitchenUtensil> utensils = [utensil('pot-a')];

  /// Shows these runs instead of the stored ones, when set before the first
  /// page opens.
  List<CookRun>? shownRuns;

  /// Shows what this stream emits as the runs, when set before the first
  /// page opens; takes the place of [shownRuns].
  Stream<List<CookRun>>? shownRunStream;

  /// The cook run repository the controller writes through, when set before
  /// the first page opens; defaults to the household's own.
  CookRunRepository? runsOverride;

  /// The container of the test.
  late final ProviderContainer container = _container();

  /// Every state the opened page went through.
  final states = <AsyncValue<KochmodusView?>>[];

  ProviderContainer _container() {
    final container = ProviderContainer(
      overrides: [
        cookRunRepositoryProvider.overrideWithValue(runsOverride ?? cook.runs),
        inventoryItemRepositoryProvider.overrideWithValue(cook.inventory),
        cookedMealRepositoryProvider.overrideWithValue(cook.meals),
        preparedMealTemplateRepositoryProvider.overrideWithValue(
          cook.templates,
        ),
        kitchenUtensilListProvider.overrideWith(
          (ref) => Stream.fromFuture(Future.value(utensils)),
        ),
        if (shownRunStream case final stream?)
          cookRunsProvider.overrideWith((ref) => stream)
        else if (shownRuns case final runs?)
          cookRunsProvider.overrideWith(
            (ref) => Stream.fromFuture(Future.value(runs)),
          ),
        firebaseAuthProvider.overrideWithValue(
          FakeSignedInAuth(FakeSignedInUser('uid-1', displayName: 'Ada')),
        ),
        appPreferencesProvider.overrideWithValue(preferences),
        clockProvider.overrideWithValue(() => kochmodusNow),
        cookRunShoppingServiceProvider.overrideWithValue(
          CookRunShoppingService(
            runs: cook.runs,
            shopping: ShoppingListNamesService(shoppingList),
            parser: const TemplateIngredientParser(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Puts [items] into the Vorrat before the controller reads it.
  Future<void> stock(List<InventoryItem> items) => cook.stock(items);

  /// Opens the page of `target`, keeps it alive and records every state.
  Future<KochmodusController> openPage(KochmodusTarget target) {
    final provider = kochmodusControllerProvider(target);
    container.listen(provider, (_, next) => states.add(next));
    return container
        .read(provider.future)
        .then((_) => container.read(provider.notifier));
  }

  /// The timer controller of `target`, kept alive for the test.
  KochmodusTimerController timers(KochmodusTarget target) {
    final provider = kochmodusTimerControllerProvider(target);
    container.listen(provider, (_, _) {});
    return container.read(provider.notifier);
  }

  /// The view the page of `target` shows now.
  KochmodusView? view(KochmodusTarget target) =>
      container.read(kochmodusControllerProvider(target)).value;

  /// Lets the writes land and the streams deliver them.
  Future<void> settle() async {
    await cook.settle();
    await pumpEventQueue();
  }
}
