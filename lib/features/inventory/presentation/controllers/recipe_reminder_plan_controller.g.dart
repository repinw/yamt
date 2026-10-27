// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_reminder_plan_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Gives the plans of Kochbuch recipes their values whenever a change of
/// the household's recipes lets a reminder count or gives a recipe other
/// saved Vorrat items. It lives as long as
/// `RecipeReminderPlanListener` around the app watches it.

@ProviderFor(RecipeReminderPlanController)
final recipeReminderPlanControllerProvider =
    RecipeReminderPlanControllerProvider._();

/// Gives the plans of Kochbuch recipes their values whenever a change of
/// the household's recipes lets a reminder count or gives a recipe other
/// saved Vorrat items. It lives as long as
/// `RecipeReminderPlanListener` around the app watches it.
final class RecipeReminderPlanControllerProvider
    extends $NotifierProvider<RecipeReminderPlanController, void> {
  /// Gives the plans of Kochbuch recipes their values whenever a change of
  /// the household's recipes lets a reminder count or gives a recipe other
  /// saved Vorrat items. It lives as long as
  /// `RecipeReminderPlanListener` around the app watches it.
  RecipeReminderPlanControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeReminderPlanControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeReminderPlanControllerHash();

  @$internal
  @override
  RecipeReminderPlanController create() => RecipeReminderPlanController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$recipeReminderPlanControllerHash() =>
    r'736e054ce17de5acbb4f4573825978f87704a393';

/// Gives the plans of Kochbuch recipes their values whenever a change of
/// the household's recipes lets a reminder count or gives a recipe other
/// saved Vorrat items. It lives as long as
/// `RecipeReminderPlanListener` around the app watches it.

abstract class _$RecipeReminderPlanController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
