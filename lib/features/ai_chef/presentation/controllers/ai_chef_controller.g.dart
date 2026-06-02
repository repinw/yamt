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
        dependencies: <ProviderOrFamily>[inventoryItemsControllerProvider],
        $allTransitiveDependencies: <ProviderOrFamily>{
          AiChefControllerProvider.$allTransitiveDependencies0,
          AiChefControllerProvider.$allTransitiveDependencies1,
          AiChefControllerProvider.$allTransitiveDependencies2,
          AiChefControllerProvider.$allTransitiveDependencies3,
        },
      );

  static final $allTransitiveDependencies0 = inventoryItemsControllerProvider;
  static final $allTransitiveDependencies1 =
      InventoryItemsControllerProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      InventoryItemsControllerProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 =
      InventoryItemsControllerProvider.$allTransitiveDependencies2;

  @override
  String debugGetCreateSourceHash() => _$aiChefControllerHash();

  @$internal
  @override
  AiChefController create() => AiChefController();
}

String _$aiChefControllerHash() => r'67df9c8389f0694fb8c823e2d6c9d1af55a1b83e';

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
