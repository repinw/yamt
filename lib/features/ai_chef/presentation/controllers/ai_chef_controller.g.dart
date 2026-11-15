// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_chef_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Puts a recipe idea together; `null` until the cook asks for one.

@ProviderFor(AiChefController)
final aiChefControllerProvider = AiChefControllerProvider._();

/// Puts a recipe idea together; `null` until the cook asks for one.
final class AiChefControllerProvider
    extends $AsyncNotifierProvider<AiChefController, AiChefRecipeIdea?> {
  /// Puts a recipe idea together; `null` until the cook asks for one.
  AiChefControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiChefControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiChefControllerHash();

  @$internal
  @override
  AiChefController create() => AiChefController();
}

String _$aiChefControllerHash() => r'0c191f65bd347c6dec57dc85aa9df411c8ed9c32';

/// Puts a recipe idea together; `null` until the cook asks for one.

abstract class _$AiChefController extends $AsyncNotifier<AiChefRecipeIdea?> {
  FutureOr<AiChefRecipeIdea?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<AiChefRecipeIdea?>, AiChefRecipeIdea?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AiChefRecipeIdea?>, AiChefRecipeIdea?>,
              AsyncValue<AiChefRecipeIdea?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
