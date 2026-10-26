import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_scaffold.dart';
import 'package:yamt/features/product_search_hub/data/'
    'food_estimate_repository.dart';
import 'package:yamt/features/product_search_hub/data/'
    'product_photo_repository.dart';
import 'package:yamt/features/product_search_hub/domain/food_estimate.dart';
import 'package:yamt/features/product_search_hub/domain/product_photo.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_exceptions.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_ai_search_result.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_ai_search_page.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'food_estimate_photo_input.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'manual_product_search_route_args.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _FakeVoiceSearchService implements VoiceSearchService {
  ValueChanged<VoiceSearchRecognition>? _onResult;
  var _isListening = false;

  @override
  bool get isListening => _isListening;

  @override
  Future<VoiceSearchFailure?> startListening({
    required ValueChanged<VoiceSearchRecognition> onResult,
    required ValueChanged<bool> onListeningStateChanged,
    required ValueChanged<VoiceSearchFailure> onError,
  }) async {
    _onResult = onResult;
    _isListening = true;
    onListeningStateChanged(true);
    return null;
  }

  @override
  Future<void> stopListening() async => _isListening = false;

  @override
  Future<void> cancelListening() async => _isListening = false;

  void say(String transcript) => _onResult?.call(
    VoiceSearchRecognition(transcript: transcript, isFinal: true),
  );
}

final Uint8List _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8'
  'AAAAASUVORK5CYII=',
);

class _FakeFoodEstimateRepository implements FoodEstimateRepository {
  new(this._onLoad);

  final Future<FoodEstimate> Function(String description) _onLoad;
  final List<String> descriptions = <String>[];
  final List<int> sentPhotoCounts = <int>[];
  final List<bool> photoSources = <bool>[];

  @override
  Future<List<FoodEstimatePhoto>> loadPhotos({required bool fromCamera}) async {
    photoSources.add(fromCamera);
    return [(mimeType: 'image/png', bytes: _pixel, address: null)];
  }

  @override
  Future<FoodEstimate> loadEstimate({
    required String description,
    required List<FoodEstimatePhoto> photos,
  }) {
    descriptions.add(description);
    sentPhotoCounts.add(photos.length);
    return _onLoad(description);
  }
}

/// Its upload runs until [upload] completes.
class _FakePhotoRepository extends Fake implements ProductPhotoRepository {
  Exception? saveError;
  final saved = <ProductPhoto>[];
  final upload = Completer<void>();
  final stored = <String, Uint8List>{};

  @override
  Future<Uint8List> readPrivatePhoto(String address) async => stored[address]!;

  @override
  Future<ProductPhotoUpload> savePrivateFrontPhoto(ProductPhoto front) async {
    final error = saveError;
    if (error != null) throw error;
    saved.add(front);
    return ProductPhotoUpload(
      frontAddress: 'gs://yamt/users/u1/food_photos/p${saved.length}.jpg',
      done: upload.future,
    );
  }
}

const _foodPhotoAddress = 'gs://yamt/users/u1/food_photos/p1.jpg';

const _doener = FoodEstimate(
  name: 'Döner Kebab',
  portionGrams: 400,
  kcalLean: 720,
  kcalRich: 960,
  per100: GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
    per100Kcal: 200,
    per100Fat: 9,
    per100SaturatedFat: 3,
    per100Carbs: 19,
    per100Sugar: 3,
    per100Fiber: 1.5,
    per100Protein: 10,
    per100Salt: 1.4,
  ),
  ingredients: [
    FoodEstimateIngredient(name: 'Fladenbrot', grams: 120, kcal: 300),
    FoodEstimateIngredient(name: 'Kalbfleisch', grams: 150, kcal: 330),
    FoodEstimateIngredient(name: 'Knoblauchsoße', grams: 60, kcal: 150),
    FoodEstimateIngredient(name: 'Salat', grams: 70, kcal: 20),
  ],
);

InventoryItem _placeholderItem() {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Placeholder',
    entryDate: DateTime.parse('2026-04-20T12:00:00Z'),
    storeName: 'Rewe',
    quantity: 1,
  );
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required FoodEstimateRepository repository,
  required ValueChanged<ManualProductAiSearchResult?> onResult,
  _FakePhotoRepository? photos,
  bool fromDiary = true,
  bool offersEatInstead = false,
  String initialPrompt = '',
  VoiceSearchService? voice,
  InventoryItem? item,
  bool reestimates = false,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                if (reestimates) {
                  // The hub passes this flag; the route args have none.
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ManualProductAiSearchPage(
                        item: item ?? _placeholderItem(),
                        reestimates: true,
                        onResult: onResult,
                      ),
                    ),
                  );
                  return;
                }
                onResult(
                  await pushManualProductSearchPage<
                    ManualProductAiSearchResult
                  >(
                    context: context,
                    args: ManualProductSearchRouteArgs.aiSearch(
                      item: item ?? _placeholderItem(),
                      initialPrompt: initialPrompt,
                      showEatImmediatelyOption: fromDiary || offersEatInstead,
                      initialAction:
                          InventoryReceiptManualProductAction.addToInventory,
                      quickEatConfig: InventoryManualAddQuickEatConfig(
                        quickEatOnly: fromDiary,
                      ),
                    ),
                  ),
                );
              },
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
        foodEstimateRepositoryProvider.overrideWithValue(repository),
        productPhotoRepositoryProvider.overrideWithValue(
          photos ?? _FakePhotoRepository(),
        ),
        voiceSearchServiceProvider.overrideWithValue(
          voice ?? _FakeVoiceSearchService(),
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _analyze(WidgetTester tester) async {
  await tester.tap(find.byKey(ManualProductAiSearchPage.analyzeKey));
  await tester.pumpAndSettle();
}

ButtonStyleButton _analyzeButton(WidgetTester tester) =>
    tester.widget(find.byKey(ManualProductAiSearchPage.analyzeKey));

void main() {
  testWidgets('analyze needs a photo or a description', (tester) async {
    await _pumpPage(
      tester,
      repository: _FakeFoodEstimateRepository((_) async => _doener),
      onResult: (_) {},
    );

    expect(find.text('What are you eating?'), findsOneWidget);
    expect(_analyzeButton(tester).onPressed, isNull);

    await tester.enterText(
      find.byKey(ManualProductAiSearchPage.descriptionKey),
      'Döner',
    );
    await tester.pump();

    expect(_analyzeButton(tester).onPressed, isNotNull);
  });

  testWidgets('a gallery photo is enough to analyze', (tester) async {
    final repository = _FakeFoodEstimateRepository((_) async => _doener);
    await _pumpPage(tester, repository: repository, onResult: (_) {});

    await tester.tap(find.byKey(FoodEstimatePhotoInput.galleryKey));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Remove photo 1'), findsOneWidget);
    expect(_analyzeButton(tester).onPressed, isNotNull);
    await _analyze(tester);
    expect(repository.sentPhotoCounts, [1]);
  });

  testWidgets('the camera comes first and offers one more after a photo', (
    tester,
  ) async {
    final repository = _FakeFoodEstimateRepository((_) async => _doener);
    await _pumpPage(tester, repository: repository, onResult: (_) {});

    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('or pick from gallery'), findsOneWidget);

    await tester.tap(find.byKey(FoodEstimatePhotoInput.cameraKey));
    await tester.pumpAndSettle();

    expect(repository.photoSources, [true]);
    expect(find.text('Take a photo'), findsNothing);
    expect(find.text('One more'), findsOneWidget);
    expect(find.text('or pick from gallery'), findsOneWidget);
    expect(_analyzeButton(tester).onPressed, isNotNull);
  });

  testWidgets('two photos are the most, then only analyzing is left', (
    tester,
  ) async {
    final repository = _FakeFoodEstimateRepository((_) async => _doener);
    await _pumpPage(tester, repository: repository, onResult: (_) {});

    await tester.tap(find.byKey(FoodEstimatePhotoInput.cameraKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FoodEstimatePhotoInput.cameraKey));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Remove photo 2'), findsOneWidget);
    expect(find.byKey(FoodEstimatePhotoInput.cameraKey), findsNothing);
    expect(find.byKey(FoodEstimatePhotoInput.galleryKey), findsNothing);
    await _analyze(tester);
    expect(repository.sentPhotoCounts, [2]);
  });

  testWidgets('dictation fills the description', (tester) async {
    final voice = _FakeVoiceSearchService();
    final repository = _FakeFoodEstimateRepository((_) async => _doener);
    await _pumpPage(
      tester,
      repository: repository,
      onResult: (_) {},
      voice: voice,
    );

    await tester.tap(find.byKey(ManualProductAiSearchPage.voiceKey));
    await tester.pump();
    voice.say('Döner mit extra Soße');
    await tester.pump();

    expect(find.text('Döner mit extra Soße'), findsOneWidget);
    await _analyze(tester);
    expect(repository.descriptions, ['Döner mit extra Soße']);
  });

  testWidgets('quick chips extend the description', (tester) async {
    final repository = _FakeFoodEstimateRepository((_) async => _doener);
    await _pumpPage(
      tester,
      repository: repository,
      onResult: (_) {},
      initialPrompt: 'Döner',
    );

    await tester.tap(find.text('large portion'));
    await tester.pump();
    await _analyze(tester);

    expect(repository.descriptions, ['Döner, large portion']);
  });

  testWidgets('estimate opens on the eat page and logs from the diary', (
    tester,
  ) async {
    ManualProductAiSearchResult? pageResult;
    await _pumpPage(
      tester,
      repository: _FakeFoodEstimateRepository((_) async => _doener),
      onResult: (result) => pageResult = result,
      initialPrompt: 'Döner ohne Zwiebeln',
    );

    await _analyze(tester);

    expect(find.text('Döner Kebab'), findsOneWidget);
    expect(find.text('AI ESTIMATE'), findsOneWidget);
    expect(find.text('Döner ohne Zwiebeln'), findsOneWidget);
    expect(find.text('Kalbfleisch'), findsOneWidget);
    expect(find.text('800 kcal'), findsWidgets);

    await tester.tap(find.text('To diary'));
    await tester.pumpAndSettle();

    expect(pageResult?.action, InventoryReceiptManualProductAction.eatNow);
    expect(pageResult?.item.name, 'Döner Kebab');
    expect(pageResult?.eatSelection?.inventoryAmount, 400);
  });

  testWidgets('the first photo becomes the private image of the item '
      'without waiting for its upload (#845)', (tester) async {
    ManualProductAiSearchResult? pageResult;
    final photos = _FakePhotoRepository();
    await _pumpPage(
      tester,
      repository: _FakeFoodEstimateRepository((_) async => _doener),
      photos: photos,
      onResult: (result) => pageResult = result,
    );
    await tester.tap(find.byKey(FoodEstimatePhotoInput.cameraKey));
    await tester.pumpAndSettle();
    await _analyze(tester);

    await tester.tap(find.text('To diary'));
    await tester.pumpAndSettle();

    expect(photos.upload.isCompleted, isFalse);
    expect(photos.saved.single.bytes, _pixel);
    expect(pageResult?.item.imageUrl, _foodPhotoAddress);
  });

  testWidgets('every photo is stored and kept on the AI estimate (#763)', (
    tester,
  ) async {
    ManualProductAiSearchResult? pageResult;
    final photos = _FakePhotoRepository();
    await _pumpPage(
      tester,
      repository: _FakeFoodEstimateRepository((_) async => _doener),
      photos: photos,
      onResult: (result) => pageResult = result,
    );
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(FoodEstimatePhotoInput.cameraKey));
      await tester.pumpAndSettle();
    }
    await _analyze(tester);

    await tester.tap(find.text('To diary'));
    await tester.pumpAndSettle();

    expect(photos.saved, hasLength(2));
    expect(pageResult?.item.imageUrl, _foodPhotoAddress);
    expect(pageResult?.item.productSnapshot.aiEstimate?.photoUrls, [
      _foodPhotoAddress,
      'gs://yamt/users/u1/food_photos/p2.jpg',
    ]);
  });

  testWidgets('an upload that fails after the page closed tells the user '
      'that the photo goes up later (#845, #849)', (tester) async {
    ManualProductAiSearchResult? pageResult;
    final photos = _FakePhotoRepository();
    await _pumpPage(
      tester,
      repository: _FakeFoodEstimateRepository((_) async => _doener),
      photos: photos,
      onResult: (result) => pageResult = result,
    );
    await tester.tap(find.byKey(FoodEstimatePhotoInput.cameraKey));
    await tester.pumpAndSettle();
    await _analyze(tester);
    await tester.tap(find.text('To diary'));
    await tester.pumpAndSettle();
    expect(pageResult?.item.imageUrl, _foodPhotoAddress);

    photos.upload.completeError(Exception('offline'));
    // The first frame delivers the error, the second shows the snack bar.
    await tester.pump();
    await tester.pump();

    expect(find.text('Photos will be uploaded later.'), findsOneWidget);
  });

  testWidgets('a failed photo upload still saves the food', (tester) async {
    ManualProductAiSearchResult? pageResult;
    await _pumpPage(
      tester,
      repository: _FakeFoodEstimateRepository((_) async => _doener),
      photos: _FakePhotoRepository()..saveError = Exception('offline'),
      onResult: (result) => pageResult = result,
    );
    await tester.tap(find.byKey(FoodEstimatePhotoInput.cameraKey));
    await tester.pumpAndSettle();
    await _analyze(tester);

    await tester.tap(find.text('To diary'));
    await tester.pump();

    expect(
      find.text(
        'The photo could not be saved. The food is saved without an image.',
      ),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(pageResult?.item.name, 'Döner Kebab');
    expect(pageResult?.item.imageUrl, isNull);
  });

  testWidgets('a rich preparation raises the energy', (tester) async {
    await _pumpPage(
      tester,
      repository: _FakeFoodEstimateRepository((_) async => _doener),
      onResult: (_) {},
      initialPrompt: 'Döner',
    );
    await _analyze(tester);

    await tester.ensureVisible(find.text('rich'));
    await tester.tap(find.text('rich'));
    await tester.pumpAndSettle();

    expect(find.text('960 kcal'), findsWidgets);
  });

  testWidgets('from the Vorrat the estimate goes to stock', (tester) async {
    ManualProductAiSearchResult? pageResult;
    await _pumpPage(
      tester,
      repository: _FakeFoodEstimateRepository((_) async => _doener),
      onResult: (result) => pageResult = result,
      fromDiary: false,
      initialPrompt: 'Döner',
    );
    await _analyze(tester);

    await tester.tap(find.text('Add to stock'));
    await tester.pumpAndSettle();

    expect(
      pageResult?.action,
      InventoryReceiptManualProductAction.addToInventory,
    );
    expect(pageResult?.eatSelection, isNull);
  });

  testWidgets('a picked ingredient offers no eat or plan icon', (tester) async {
    await _pumpPage(
      tester,
      repository: _FakeFoodEstimateRepository((_) async => _doener),
      onResult: (_) {},
      fromDiary: false,
      initialPrompt: 'Döner',
    );
    await _analyze(tester);

    expect(find.byKey(EatPageScaffold.diaryButtonKey), findsNothing);
    expect(find.byKey(EatPageScaffold.planButtonKey), findsNothing);
  });

  testWidgets('from the Vorrat the icons eat or plan the food instead', (
    tester,
  ) async {
    final results = <ManualProductAiSearchResult?>[];
    for (final icon in [
      EatPageScaffold.diaryButtonKey,
      EatPageScaffold.planButtonKey,
    ]) {
      await _pumpPage(
        tester,
        repository: _FakeFoodEstimateRepository((_) async => _doener),
        onResult: results.add,
        fromDiary: false,
        offersEatInstead: true,
        initialPrompt: 'Döner',
      );
      await _analyze(tester);
      await tester.tap(find.byKey(icon));
      await tester.pumpAndSettle();
      if (icon == EatPageScaffold.planButtonKey) {
        // The day picker starts on today.
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      }
    }

    final [eaten, planned] = results;
    expect(eaten?.action, InventoryReceiptManualProductAction.eatNow);
    expect(eaten?.eatSelection?.inventoryAmount, 400);
    expect(eaten?.eatRequest?.isPlan, isFalse);
    expect(planned?.action, InventoryReceiptManualProductAction.eatNow);
    // The plan flag survives, so a plan for today stays a plan.
    expect(planned?.eatRequest?.isPlan, isTrue);
  });

  testWidgets('analyze again returns to the input', (tester) async {
    await _pumpPage(
      tester,
      repository: _FakeFoodEstimateRepository((_) async => _doener),
      onResult: (_) {},
      initialPrompt: 'Döner',
    );
    await _analyze(tester);

    await tester.tap(find.text('Analyze again'));
    await tester.pumpAndSettle();

    expect(find.text('What are you eating?'), findsOneWidget);
    expect(find.text('Döner'), findsOneWidget);
  });

  testWidgets('no food shows a message', (tester) async {
    await _pumpPage(
      tester,
      repository: _FakeFoodEstimateRepository(
        (_) async => throw const FoodEstimateNotFoodException(),
      ),
      onResult: (_) {},
      initialPrompt: 'Tisch',
    );
    await _analyze(tester);

    expect(find.text('The photos show no food.'), findsOneWidget);
    expect(find.text('What are you eating?'), findsOneWidget);
  });

  testWidgets('a stored AI food starts from its photos and description and '
      'takes the new estimate without storing them again (#763)', (
    tester,
  ) async {
    const stored = 'gs://yamt/users/u1/food_photos/old.jpg';
    final placeholder = _placeholderItem();
    final item = placeholder.copyWith(
      productSnapshot: placeholder.productSnapshot.copyWith(
        aiEstimate: const SavedFoodEstimate(
          estimate: _doener,
          level: FoodEstimateLevel.normal,
          description: 'Restaurant',
          photoUrls: [stored],
        ),
      ),
    );
    ManualProductAiSearchResult? pageResult;
    final photos = _FakePhotoRepository()..stored[stored] = _pixel;
    final repository = _FakeFoodEstimateRepository((_) async => _doener);
    await _pumpPage(
      tester,
      repository: repository,
      photos: photos,
      item: item,
      reestimates: true,
      onResult: (result) => pageResult = result,
    );

    expect(find.text('Restaurant'), findsOneWidget);
    expect(
      tester
          .widget<FoodEstimatePhotoInput>(find.byType(FoodEstimatePhotoInput))
          .photos,
      hasLength(1),
    );
    await _analyze(tester);
    expect(repository.descriptions.last, 'Restaurant');
    expect(repository.sentPhotoCounts.last, 1);

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(photos.saved, isEmpty);
    expect(pageResult?.item.productSnapshot.aiEstimate?.photoUrls, [stored]);
  });
}
