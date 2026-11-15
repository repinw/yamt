import 'dart:async';
import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_image_generator.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_repository.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_view_builder.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/prepared_meal_template_writer.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

part 'recipe_idea_controller.g.dart';

/// The picture of the recipe [idea], which comes after its text, and saving
/// the idea to the Kochbuch.
///
/// A picture that fails is not asked for again: every try is a paid call,
/// and the recipe is fine without one. Its generator depends on nothing that
/// changes, so the picture is asked for once per idea.
@Riverpod(retry: _noRetry)
class RecipeIdeaController extends _$RecipeIdeaController {
  Future<PreparedMeal?>? _saving;

  @override
  Future<Uint8List> build(AiChefRecipeIdea idea) =>
      ref.watch(aiChefImageGeneratorProvider).generate(idea.imagePrompt);

  /// Saves the idea as a new recipe of the Kochbuch, with its estimate, and
  /// returns it; `null` when saving failed. A call while a save runs, or
  /// after one succeeded, gets that save: the idea becomes one recipe. The
  /// picture is not waited for: it goes onto the saved recipe when it comes,
  /// also after the window closed.
  Future<PreparedMeal?> save() => _saving ??= _save().then((saved) {
    if (saved == null) _saving = null;
    return saved;
  });

  Future<PreparedMeal?> _save() async {
    final templates = ref.read(preparedMealTemplateRepositoryProvider);
    final covers = ref.read(aiChefRepositoryProvider);
    final link = ref.keepAlive();
    final PreparedMeal saved;
    try {
      saved = await ref
          .read(preparedMealTemplateWriterProvider)
          .addFromMeal(idea.recipe);
    } on Object catch (error, stackTrace) {
      log(
        'Saving the recipe idea failed.',
        name: 'RecipeIdeaController',
        error: error,
        stackTrace: stackTrace,
      );
      link.close();
      return null;
    }
    unawaited(
      _addPicture(
        saved.id,
        templates: templates,
        covers: covers,
      ).whenComplete(link.close),
    );
    return saved;
  }

  // Stores the picture once it is there and puts it on the saved recipe
  // [recipeId]. Nothing is stored when the recipe is gone by then, as after
  // "Rückgängig". A failure leaves the recipe without a picture.
  Future<void> _addPicture(
    String recipeId, {
    required PreparedMealTemplateRepository templates,
    required FirebaseAiChefRepository covers,
  }) async {
    bool has(List<PreparedMeal> all) =>
        all.any((template) => template.id == recipeId);
    try {
      // The save commits in the background, so the recipe shows a moment
      // after it returned. Wait for it; only then "not there" means gone.
      await _appeared(templates.watchAll(), has);
      final bytes = await future;
      if (!has(await templates.readAll())) {
        return;
      }
      final url = await covers.saveCover(recipeId: recipeId, bytes: bytes);
      await templates.update(
        recipeId,
        (latest) => latest.copyWith(imageUrl: url),
      );
    } on Object catch (error, stackTrace) {
      log(
        'Adding the picture to the recipe idea failed.',
        name: 'RecipeIdeaController',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// The recipe of [idea] as the recipe page shows it, for its own portions,
/// with the Vorrat items of each ingredient ([buildRecipeView]). The Vorrat
/// adds its items when it is there; the recipe never waits for it.
@riverpod
RecipeView recipeIdeaView(Ref ref, AiChefRecipeIdea idea, String localeCode) =>
    buildRecipeView(
      recipeId: idea.recipe.id,
      templates: AsyncData([idea.recipe]),
      items: AsyncData(
        ref.watch(inventoryQuickEatItemsProvider).value ?? const [],
      ),
      parser: ref.watch(templateIngredientParserProvider),
      localeCode: localeCode,
      portions: null,
    ).requireValue!;

Duration? _noRetry(int retryCount, Object error) => null;

// Completes once [templates] emit a list that [has] the recipe; throws a
// [TimeoutException] when none did within [_appearTimeout] in total, a
// [StateError] when the stream ends without it, or the stream's error. The
// subscription ends either way.
Future<void> _appeared(
  Stream<List<PreparedMeal>> templates,
  bool Function(List<PreparedMeal>) has,
) async {
  final appeared = Completer<void>();
  final subscription = templates.listen(
    (all) {
      if (has(all) && !appeared.isCompleted) appeared.complete();
    },
    onError: (Object error, StackTrace stackTrace) {
      if (!appeared.isCompleted) appeared.completeError(error, stackTrace);
    },
    onDone: () {
      if (!appeared.isCompleted) {
        appeared.completeError(StateError('The recipes ended without it'));
      }
    },
  );
  try {
    await appeared.future.timeout(_appearTimeout);
  } finally {
    await subscription.cancel();
  }
}

const _appearTimeout = Duration(seconds: 30);
