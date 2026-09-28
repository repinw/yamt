// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kitchen_utensil_image_url_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads the download URL of a stored kitchen utensil image.

@ProviderFor(kitchenUtensilImageUrl)
final kitchenUtensilImageUrlProvider = KitchenUtensilImageUrlFamily._();

/// Loads the download URL of a stored kitchen utensil image.

final class KitchenUtensilImageUrlProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Loads the download URL of a stored kitchen utensil image.
  KitchenUtensilImageUrlProvider._({
    required KitchenUtensilImageUrlFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'kitchenUtensilImageUrlProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kitchenUtensilImageUrlHash();

  @override
  String toString() {
    return r'kitchenUtensilImageUrlProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return kitchenUtensilImageUrl(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KitchenUtensilImageUrlProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kitchenUtensilImageUrlHash() =>
    r'3f712d05f54a87d813905730e71008a8c9defa93';

/// Loads the download URL of a stored kitchen utensil image.

final class KitchenUtensilImageUrlFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  KitchenUtensilImageUrlFamily._()
    : super(
        retry: null,
        name: r'kitchenUtensilImageUrlProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads the download URL of a stored kitchen utensil image.

  KitchenUtensilImageUrlProvider call(String imageStoragePath) =>
      KitchenUtensilImageUrlProvider._(argument: imageStoragePath, from: this);

  @override
  String toString() => r'kitchenUtensilImageUrlProvider';
}
