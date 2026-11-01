// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cook_finish_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Runs "In Vorrat" for a cooking of the recipe `recipeId`.

@ProviderFor(CookFinishController)
final cookFinishControllerProvider = CookFinishControllerFamily._();

/// Runs "In Vorrat" for a cooking of the recipe `recipeId`.
final class CookFinishControllerProvider
    extends $AsyncNotifierProvider<CookFinishController, void> {
  /// Runs "In Vorrat" for a cooking of the recipe `recipeId`.
  CookFinishControllerProvider._({
    required CookFinishControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cookFinishControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cookFinishControllerHash();

  @override
  String toString() {
    return r'cookFinishControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CookFinishController create() => CookFinishController();

  @override
  bool operator ==(Object other) {
    return other is CookFinishControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cookFinishControllerHash() =>
    r'ebf95dc2739abae022a4720a5d8e5627b275ab4f';

/// Runs "In Vorrat" for a cooking of the recipe `recipeId`.

final class CookFinishControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          CookFinishController,
          AsyncValue<void>,
          void,
          FutureOr<void>,
          String
        > {
  CookFinishControllerFamily._()
    : super(
        retry: null,
        name: r'cookFinishControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Runs "In Vorrat" for a cooking of the recipe `recipeId`.

  CookFinishControllerProvider call(String recipeId) =>
      CookFinishControllerProvider._(argument: recipeId, from: this);

  @override
  String toString() => r'cookFinishControllerProvider';
}

/// Runs "In Vorrat" for a cooking of the recipe `recipeId`.

abstract class _$CookFinishController extends $AsyncNotifier<void> {
  late final _$args = ref.$arg as String;
  String get recipeId => _$args;

  FutureOr<void> build(String recipeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
