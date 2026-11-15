import 'dart:async';
import 'dart:developer' show log;
import 'dart:math' show Random;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/ai_chef/application/'
    'ai_chef_inventory_input_builder.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';

part 'ai_chef_controller.g.dart';

/// Puts a recipe idea together; `null` until the cook asks for one.
@riverpod
class AiChefController extends _$AiChefController {
  final _random = Random();

  @override
  FutureOr<AiChefRecipeIdea?> build() => null;

  /// Asks for a recipe idea in German or English with the cook's [wishes],
  /// from the Vorrat when [includeInventory]. A Vorrat that cannot be read
  /// leaves it out.
  Future<void> generateRecipe({
    required bool isGerman,
    required bool includeInventory,
    String wishes = '',
  }) async {
    state = const AsyncLoading();
    final nextState = await AsyncValue.guard(() async {
      final seeds = isGerman ? _germanSeeds : _englishSeeds;
      final seed = _buildSeed(
        baseSeed: seeds[_random.nextInt(seeds.length)],
        wishes: wishes,
        isGerman: isGerman,
      );
      final inventoryIngredients = includeInventory
          ? await _inventoryIngredients()
          : const <String>[];
      if (!ref.mounted) {
        return null;
      }
      return await ref
          .read(aiChefRepositoryProvider)
          .loadRecipeIdea(
            languageCode: isGerman ? 'de' : 'en',
            seed: seed,
            now: ref.read(clockProvider)(),
            inventoryIngredients: inventoryIngredients,
          );
    });
    if (nextState case AsyncError(:final error, :final stackTrace)) {
      log(
        'The recipe idea failed.',
        name: 'AiChefController',
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (!ref.mounted) {
      return;
    }
    state = nextState;
  }

  Future<List<String>> _inventoryIngredients() async {
    try {
      final items = await ref.read(inventoryItemRepositoryProvider).readAll();
      return const AiChefInventoryInputBuilder().build(items);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to load the Vorrat for the recipe idea.',
        name: 'AiChefController',
        error: error,
        stackTrace: stackTrace,
      );
      return const <String>[];
    }
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
