// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cook_finish_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The service that ends a cooking with "In Vorrat".

@ProviderFor(cookFinishService)
final cookFinishServiceProvider = CookFinishServiceProvider._();

/// The service that ends a cooking with "In Vorrat".

final class CookFinishServiceProvider
    extends
        $FunctionalProvider<
          CookFinishService,
          CookFinishService,
          CookFinishService
        >
    with $Provider<CookFinishService> {
  /// The service that ends a cooking with "In Vorrat".
  CookFinishServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookFinishServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookFinishServiceHash();

  @$internal
  @override
  $ProviderElement<CookFinishService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CookFinishService create(Ref ref) {
    return cookFinishService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CookFinishService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CookFinishService>(value),
    );
  }
}

String _$cookFinishServiceHash() => r'e13266ce88412e66f755b44655b4e8bc2fd5b00c';
