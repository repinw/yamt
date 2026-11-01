import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cooking/application/cook_finish_service.dart';
import 'package:yamt/features/cooking/domain/cook_recipe.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';

part 'cook_finish_controller.g.dart';

/// Runs "In Vorrat" for a cooking of the recipe `recipeId`.
@riverpod
class CookFinishController extends _$CookFinishController {
  @override
  FutureOr<void> build(String recipeId) {}

  /// Puts the meal of [session] into the Vorrat. Returns the failure, `null`
  /// when it worked; a failure also stays in the state.
  Future<Object?> finish({
    required CookRecipe recipe,
    required CookSession session,
    required CookPortioning portioning,
  }) async {
    final link = ref.keepAlive();
    try {
      state = const AsyncLoading();
      final result = await AsyncValue.guard<void>(() async {
        await ref
            .read(cookFinishServiceProvider)
            .finish(recipe: recipe, session: session, portioning: portioning);
      });
      if (ref.mounted) state = result;
      return result.error;
    } finally {
      link.close();
    }
  }
}
