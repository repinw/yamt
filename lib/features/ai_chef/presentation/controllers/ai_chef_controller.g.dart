// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_chef_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller for generating a random recipe with AI.

@ProviderFor(AiChefController)
final aiChefControllerProvider = AiChefControllerProvider._();

/// Controller for generating a random recipe with AI.
final class AiChefControllerProvider
    extends $AsyncNotifierProvider<AiChefController, PreparedMeal?> {
  /// Controller for generating a random recipe with AI.
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

String _$aiChefControllerHash() => r'f4a367f5b00aed6134e32eeb4f5db230f652ed2f';

/// Controller for generating a random recipe with AI.

abstract class _$AiChefController extends $AsyncNotifier<PreparedMeal?> {
  FutureOr<PreparedMeal?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PreparedMeal?>, PreparedMeal?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PreparedMeal?>, PreparedMeal?>,
              AsyncValue<PreparedMeal?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
