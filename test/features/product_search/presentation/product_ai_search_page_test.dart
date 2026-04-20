import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/data/'
    'product_ai_search_repository.dart';
import 'package:yamt/features/product_search/domain/'
    'product_ai_search_models.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'product_ai_search_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _FakeProductAiSearchRepository extends FirebaseProductAiSearchRepository {
  _FakeProductAiSearchRepository({required this.onGenerateFoodFromText});

  final Future<ProductAiSearchDraft?> Function(String prompt)
  onGenerateFoodFromText;

  @override
  Future<ProductAiSearchDraft?> generateFoodFromText({
    required String prompt,
  }) {
    return onGenerateFoodFromText(prompt);
  }
}

class _FakeAiSpeechService implements VoiceSearchService {
  int startCallCount = 0;
  bool _isListening = false;
  ValueChanged<VoiceSearchRecognition>? _onResult;
  ValueChanged<bool>? _onListeningStateChanged;

  @override
  bool get isListening => _isListening;

  @override
  Future<VoiceSearchFailure?> startListening({
    required ValueChanged<VoiceSearchRecognition> onResult,
    required ValueChanged<bool> onListeningStateChanged,
    required ValueChanged<VoiceSearchFailure> onError,
  }) async {
    startCallCount++;
    _onResult = onResult;
    _onListeningStateChanged = onListeningStateChanged;
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

  void emitTranscript(String transcript, {bool isFinal = false}) {
    _onResult?.call(
      VoiceSearchRecognition(transcript: transcript, isFinal: isFinal),
    );
  }
}

void main() {
  testWidgets('ai page shows error when generation fails', (tester) async {
    final repository = _FakeProductAiSearchRepository(
      onGenerateFoodFromText: (_) async => null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productAiSearchRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ManualProductAiSearchPage(
            item: InventoryItem.create(
              id: 'item-1',
              name: 'Placeholder',
              entryDate: DateTime.parse('2026-04-20T12:00:00Z'),
              storeName: 'Rewe',
              quantity: 1,
            ),
            initialPrompt: 'pelmeni',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('manual_product_ai_generate_button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Could not generate a food estimate. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('ai page voice search fills prompt field', (tester) async {
    final repository = _FakeProductAiSearchRepository(
      onGenerateFoodFromText: (_) async => null,
    );
    final speechService = _FakeAiSpeechService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productAiSearchRepositoryProvider.overrideWithValue(repository),
          voiceSearchServiceProvider.overrideWithValue(speechService),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ManualProductAiSearchPage(
            item: InventoryItem.create(
              id: 'item-1',
              name: 'Placeholder',
              entryDate: DateTime.parse('2026-04-20T12:00:00Z'),
              storeName: 'Rewe',
              quantity: 1,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('manual_product_ai_voice_search_button')),
    );
    await tester.pumpAndSettle();

    expect(speechService.startCallCount, 1);

    speechService.emitTranscript('doener haehnchen');
    await tester.pump();

    final promptField = tester.widget<TextField>(
      find.byKey(const Key('manual_product_ai_prompt_field')),
    );
    expect(promptField.controller?.text, 'doener haehnchen');
  });

  testWidgets('ai page adjusts per-100 kcal and weight before save', (
    tester,
  ) async {
    String? capturedPrompt;
    ManualProductAiSearchResult? pageResult;
    final repository = _FakeProductAiSearchRepository(
      onGenerateFoodFromText: (prompt) async {
        capturedPrompt = prompt;
        return const ProductAiSearchDraft(
          name: 'Pelmeni mit Schweinefleisch',
          ingredients: <ProductAiSearchIngredientRow>[
            ProductAiSearchIngredientRow(
              label: 'Teighuelle',
              amountText: 'ca. 186 g',
              amountGrams: 186,
              kcalMin: 420,
              kcalMax: 420,
              protein: 14,
              carbs: 78,
              fat: 4,
            ),
            ProductAiSearchIngredientRow(
              label: 'Schweinefleischfuellung',
              amountText: 'ca. 99 g',
              amountGrams: 99,
              kcalMin: 306,
              kcalMax: 306,
              protein: 16,
              carbs: 2,
              fat: 30,
            ),
            ProductAiSearchIngredientRow(
              label: 'Zwiebeln und Gewuerze',
              amountText: 'ca. 15 g',
              amountGrams: 15,
              kcalMin: 18,
              kcalMax: 18,
              protein: 1,
              carbs: 3,
              fat: 0,
            ),
          ],
          totalWeightGrams: 400,
          totalKcalMin: 720,
          totalKcalMax: 960,
          defaultKcal: 820,
          portionNutrition: ProductAiSearchNutritionEstimate(
            kcal: 820,
            protein: 40,
            carbs: 72,
            fat: 40,
            salt: 1.5,
          ),
        );
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productAiSearchRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () async {
                      pageResult = await Navigator.of(context).push(
                        MaterialPageRoute<ManualProductAiSearchResult>(
                          builder: (_) => ManualProductAiSearchPage(
                            item: InventoryItem.create(
                              id: 'item-1',
                              name: 'Placeholder',
                              entryDate: DateTime.parse(
                                '2026-04-20T12:00:00Z',
                              ),
                              storeName: 'Rewe',
                              quantity: 1,
                            ),
                            initialPrompt: 'pelmeni mit Schweinefleisch',
                          ),
                        ),
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('manual_product_ai_generate_button')),
    );
    await tester.pumpAndSettle();

    expect(capturedPrompt, 'pelmeni mit Schweinefleisch');
    expect(
      find.byKey(const Key('manual_product_ai_density_slider')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('manual_product_ai_weight_field')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('manual_product_ai_weight_field')),
      '250',
    );
    await tester.pump();

    final slider = tester.widget<Slider>(
      find.byKey(const Key('manual_product_ai_density_slider')),
    );
    slider.onChanged!(slider.max);
    await tester.pump();

    final saveButton = find.byKey(const Key('manual_product_ai_save_button'));
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(pageResult, isNotNull);
    expect(pageResult!.globalPackageWeight, '250 g');
    expect(pageResult!.item.name, 'Pelmeni mit Schweinefleisch');
    expect(pageResult!.item.weight, '250 g');
    expect(pageResult!.item.servingSize, '250 g');
    expect(pageResult!.item.servingQuantity, 250);
    expect(
      pageResult!.item.nutrition?.qualityStatus,
      GlobalFoodNutritionQualityStatus.unverified,
    );
    expect(pageResult!.item.nutrition?.per100Kcal, closeTo(240, 0.01));
  });

  testWidgets(
    'ai page keeps slider value in range when portion kcal is inconsistent',
    (tester) async {
      final repository = _FakeProductAiSearchRepository(
        onGenerateFoodFromText: (_) async {
          return const ProductAiSearchDraft(
            name: 'Doener',
            ingredients: <ProductAiSearchIngredientRow>[
              ProductAiSearchIngredientRow(
                label: 'Bread',
                amountText: '100 g',
                amountGrams: 100,
                kcalMin: 250,
                kcalMax: 250,
              ),
            ],
            totalWeightGrams: 350,
            totalKcalMin: 900,
            totalKcalMax: 975,
            defaultKcal: 950,
            portionNutrition: ProductAiSearchNutritionEstimate(
              kcal: 233,
              protein: 12,
              carbs: 18,
              fat: 9,
            ),
          );
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productAiSearchRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ManualProductAiSearchPage(
              item: InventoryItem.create(
                id: 'item-1',
                name: 'Placeholder',
                entryDate: DateTime.parse('2026-04-20T12:00:00Z'),
                storeName: 'Rewe',
                quantity: 1,
              ),
              initialPrompt: 'doener',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('manual_product_ai_generate_button')),
      );
      await tester.pumpAndSettle();

      final slider = tester.widget<Slider>(
        find.byKey(const Key('manual_product_ai_density_slider')),
      );

      expect(slider.value, 271);
      expect(slider.value, greaterThanOrEqualTo(slider.min));
      expect(slider.value, lessThanOrEqualTo(slider.max));
    },
  );
}
