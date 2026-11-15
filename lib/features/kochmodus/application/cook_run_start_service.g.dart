// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cook_run_start_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The start of a cooking for the signed-in member on this device.

@ProviderFor(cookRunStartService)
final cookRunStartServiceProvider = CookRunStartServiceProvider._();

/// The start of a cooking for the signed-in member on this device.

final class CookRunStartServiceProvider
    extends
        $FunctionalProvider<
          CookRunStartService,
          CookRunStartService,
          CookRunStartService
        >
    with $Provider<CookRunStartService> {
  /// The start of a cooking for the signed-in member on this device.
  CookRunStartServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookRunStartServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookRunStartServiceHash();

  @$internal
  @override
  $ProviderElement<CookRunStartService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CookRunStartService create(Ref ref) {
    return cookRunStartService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CookRunStartService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CookRunStartService>(value),
    );
  }
}

String _$cookRunStartServiceHash() =>
    r'1949626427fc5b05ec12f40f0f8f3f9eaccf4327';
