import 'dart:async';
import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/ai_chef/data/'
    'ai_chef_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'ai_chef_controller.g.dart';

/// Loads already-formatted inventory prompt entries.
typedef AiChefInventoryIngredientsLoader = Future<List<String>> Function();

/// Controller for generating a random recipe with AI.
@riverpod
class AiChefController extends _$AiChefController {
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
    AiChefInventoryIngredientsLoader inventoryIngredientsLoader =
        _emptyInventoryIngredients,
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
      final inventoryIngredients = includeInventory
          ? await inventoryIngredientsLoader()
          : const <String>[];
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

Future<List<String>> _emptyInventoryIngredients() async {
  return const <String>[];
}
