// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cook_view_builder.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The cooking page of the recipe [recipeId]: the recipe, the cook's
/// choices, and each line with its Vorrat suggestion; `null` when the
/// recipe is gone. It loads and fails with the recipe and the Vorrat.

@ProviderFor(cookView)
final cookViewProvider = CookViewFamily._();

/// The cooking page of the recipe [recipeId]: the recipe, the cook's
/// choices, and each line with its Vorrat suggestion; `null` when the
/// recipe is gone. It loads and fails with the recipe and the Vorrat.

final class CookViewProvider
    extends
        $FunctionalProvider<
          AsyncValue<CookView?>,
          AsyncValue<CookView?>,
          AsyncValue<CookView?>
        >
    with $Provider<AsyncValue<CookView?>> {
  /// The cooking page of the recipe [recipeId]: the recipe, the cook's
  /// choices, and each line with its Vorrat suggestion; `null` when the
  /// recipe is gone. It loads and fails with the recipe and the Vorrat.
  CookViewProvider._({
    required CookViewFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'cookViewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cookViewHash();

  @override
  String toString() {
    return r'cookViewProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<CookView?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<CookView?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return cookView(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<CookView?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<CookView?>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CookViewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cookViewHash() => r'8053570d761cd691a082d7c5e7b28a16989b8d81';

/// The cooking page of the recipe [recipeId]: the recipe, the cook's
/// choices, and each line with its Vorrat suggestion; `null` when the
/// recipe is gone. It loads and fails with the recipe and the Vorrat.

final class CookViewFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<CookView?>, (String, String)> {
  CookViewFamily._()
    : super(
        retry: null,
        name: r'cookViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The cooking page of the recipe [recipeId]: the recipe, the cook's
  /// choices, and each line with its Vorrat suggestion; `null` when the
  /// recipe is gone. It loads and fails with the recipe and the Vorrat.

  CookViewProvider call(String recipeId, String localeCode) =>
      CookViewProvider._(argument: (recipeId, localeCode), from: this);

  @override
  String toString() => r'cookViewProvider';
}
