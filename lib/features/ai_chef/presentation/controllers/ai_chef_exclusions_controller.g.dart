// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_chef_exclusions_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the ingredients the user never wants in an AI recipe.

@ProviderFor(AiChefExclusionsController)
final aiChefExclusionsControllerProvider =
    AiChefExclusionsControllerProvider._();

/// Holds the ingredients the user never wants in an AI recipe.
final class AiChefExclusionsControllerProvider
    extends
        $StreamNotifierProvider<AiChefExclusionsController, AiChefExclusions> {
  /// Holds the ingredients the user never wants in an AI recipe.
  AiChefExclusionsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiChefExclusionsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiChefExclusionsControllerHash();

  @$internal
  @override
  AiChefExclusionsController create() => AiChefExclusionsController();
}

String _$aiChefExclusionsControllerHash() =>
    r'b22eb387d86bb224fe7d4a8e1cc92cb14b9c2b8a';

/// Holds the ingredients the user never wants in an AI recipe.

abstract class _$AiChefExclusionsController
    extends $StreamNotifier<AiChefExclusions> {
  Stream<AiChefExclusions> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<AiChefExclusions>, AiChefExclusions>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AiChefExclusions>, AiChefExclusions>,
              AsyncValue<AiChefExclusions>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
