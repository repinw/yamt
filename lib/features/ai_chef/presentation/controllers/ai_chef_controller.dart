import 'dart:async';
import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/ai_chef/application/'
    'ai_chef_inventory_input_builder.dart';
import 'package:yamt/features/ai_chef/data/'
    'ai_chef_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';

part 'ai_chef_controller.g.dart';

/// Controller for generating a random recipe with AI.
@Riverpod(dependencies: [InventoryItemsController])
class AiChefController extends _$AiChefController {
  static const _inventoryInputBuilder = AiChefInventoryInputBuilder();
  final _random = Random();

  @override
  FutureOr<PreparedMeal?> build() {
    return null;
  }

  /// Generates a random recipe using Firebase Vertex AI.
  Future<void> generateRecipe({
    required bool isGerman,
    required bool includeInventory,
    String wishes = '',
  }) async {
    state = const AsyncLoading();
    final nextState = await AsyncValue.guard(() async {
      final langCode = isGerman ? 'de' : 'en';
      final seeds = isGerman ? _germanSeeds : _englishSeeds;
      final baseSeed = seeds[_random.nextInt(seeds.length)];
      final seed = _buildSeed(
        baseSeed: baseSeed,
        wishes: wishes,
        isGerman: isGerman,
      );
      final inventoryIngredients = await _inventoryIngredientsForAi(
        includeInventory: includeInventory,
      );
      if (!ref.mounted) {
        return null;
      }

      final repo = ref.read(aiChefRepositoryProvider);
      final recipe = await repo.generateAiRecipe(
        languageCode: langCode,
        seed: seed,
        inventoryIngredients: inventoryIngredients,
      );

      if (!ref.mounted) {
        return null;
      }

      if (recipe == null) {
        throw Exception('Failed to generate AI recipe.');
      }
      return recipe;
    });
    if (!ref.mounted) {
      return;
    }
    state = nextState;
  }

  Future<List<String>> _inventoryIngredientsForAi({
    required bool includeInventory,
  }) async {
    if (!includeInventory) {
      return const <String>[];
    }

    final items = await ref.read(inventoryItemsControllerProvider.future);
    if (!ref.mounted) {
      return const <String>[];
    }

    return _inventoryInputBuilder.build(items);
  }

  String _buildSeed({
    required String baseSeed,
    required String wishes,
    required bool isGerman,
  }) {
    final trimmedWishes = wishes.trim();
    if (trimmedWishes.isEmpty) {
      return baseSeed;
    }
    final label = isGerman ? 'Wünsche' : 'Wishes';
    return '$baseSeed. $label: $trimmedWishes';
  }

  static const _germanSeeds = [
    'Pasta',
    'Fisch',
    'vegetarisch',
    'Hähnchen',
    'Eintopf',
    'Salat',
    'Reisgericht',
    'Suppe',
    'Auflauf',
    'mediterran',
    'schnelles Pfannengericht',
    'Kürbis',
    'Avocado',
    'Frühstück',
  ];

  static const _englishSeeds = [
    'pasta',
    'fish',
    'vegetarian',
    'chicken',
    'stew',
    'salad',
    'rice dish',
    'soup',
    'casserole',
    'mediterranean',
    'quick stir-fry',
    'pumpkin',
    'avocado',
    'breakfast',
  ];
}
