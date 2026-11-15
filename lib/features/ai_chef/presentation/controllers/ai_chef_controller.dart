import 'dart:async';
import 'dart:developer' show log;
import 'dart:math' show Random;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/ai_chef/application/'
    'ai_chef_inventory_input_builder.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

part 'ai_chef_controller.g.dart';

/// The formatted Vorrat and the picked items in it that must go in.
typedef _InventoryInput = ({List<String> available, List<String> mustUse});

const _InventoryInput _noInventory = (
  available: <String>[],
  mustUse: <String>[],
);

/// Puts a recipe idea together; `null` until the cook asks for one.
@riverpod
class AiChefController extends _$AiChefController {
  final _random = Random();

  @override
  FutureOr<AiChefRecipeIdea?> build() => null;

  /// Asks for a recipe idea in German or English with the cook's [wishes],
  /// from the Vorrat when [includeInventory]. The recipe never contains one
  /// of [excludedIngredients] ("Bloß nicht"). With the Vorrat, it contains
  /// the Vorrat items with [mustUseIds] ("Unbedingt rein"), looked up when
  /// the request goes out, so an item eaten since the pick is left out. A
  /// Vorrat that cannot be read leaves it out; with picks it fails the
  /// idea, so the cook's choice is never dropped silently.
  Future<void> generateRecipe({
    required bool isGerman,
    required bool includeInventory,
    String wishes = '',
    List<String> excludedIngredients = const <String>[],
    Set<String> mustUseIds = const <String>{},
  }) async {
    state = const AsyncLoading();
    final nextState = await AsyncValue.guard(() async {
      final seeds = isGerman ? _germanSeeds : _englishSeeds;
      final seed = _buildSeed(
        baseSeed: seeds[_random.nextInt(seeds.length)],
        wishes: wishes,
        isGerman: isGerman,
      );
      final inventory = includeInventory
          ? await _inventory(mustUseIds)
          : _noInventory;
      if (!ref.mounted) {
        return null;
      }
      return await ref
          .read(aiChefRepositoryProvider)
          .loadRecipeIdea(
            languageCode: isGerman ? 'de' : 'en',
            seed: seed,
            now: ref.read(clockProvider)(),
            inventoryIngredients: inventory.available,
            excludedIngredients: excludedIngredients,
            mustUseIngredients: inventory.mustUse,
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

  /// The Vorrat the cook can pick "Unbedingt rein" from, the longest in
  /// stock first. Throws when the Vorrat cannot be read.
  Future<List<InventoryItem>> loadPickableItems() async {
    final items = await ref.read(inventoryItemRepositoryProvider).readAll();
    return const AiChefInventoryInputBuilder().pickableOldestFirst(items);
  }

  Future<_InventoryInput> _inventory(Set<String> mustUseIds) async {
    const builder = AiChefInventoryInputBuilder();
    try {
      final items = await ref.read(inventoryItemRepositoryProvider).readAll();
      return (
        available: builder.build(items),
        mustUse: builder.build([
          for (final item in builder.pickableOldestFirst(items))
            if (mustUseIds.contains(item.id)) item,
        ]),
      );
    } on Object catch (error, stackTrace) {
      log(
        'Failed to load the Vorrat for the recipe idea.',
        name: 'AiChefController',
        error: error,
        stackTrace: stackTrace,
      );
      if (mustUseIds.isNotEmpty) {
        rethrow;
      }
      return _noInventory;
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
