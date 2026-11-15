// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cook_run_finish_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The end of the household's cook runs.

@ProviderFor(cookRunFinishService)
final cookRunFinishServiceProvider = CookRunFinishServiceProvider._();

/// The end of the household's cook runs.

final class CookRunFinishServiceProvider
    extends
        $FunctionalProvider<
          CookRunFinishService,
          CookRunFinishService,
          CookRunFinishService
        >
    with $Provider<CookRunFinishService> {
  /// The end of the household's cook runs.
  CookRunFinishServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookRunFinishServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookRunFinishServiceHash();

  @$internal
  @override
  $ProviderElement<CookRunFinishService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CookRunFinishService create(Ref ref) {
    return cookRunFinishService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CookRunFinishService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CookRunFinishService>(value),
    );
  }
}

String _$cookRunFinishServiceHash() =>
    r'b9e6d256c40fc0cb0e2eaebc755de065287a4572';
