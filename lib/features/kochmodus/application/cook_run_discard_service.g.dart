// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cook_run_discard_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The discard of the household's cook runs.

@ProviderFor(cookRunDiscardService)
final cookRunDiscardServiceProvider = CookRunDiscardServiceProvider._();

/// The discard of the household's cook runs.

final class CookRunDiscardServiceProvider
    extends
        $FunctionalProvider<
          CookRunDiscardService,
          CookRunDiscardService,
          CookRunDiscardService
        >
    with $Provider<CookRunDiscardService> {
  /// The discard of the household's cook runs.
  CookRunDiscardServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookRunDiscardServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookRunDiscardServiceHash();

  @$internal
  @override
  $ProviderElement<CookRunDiscardService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CookRunDiscardService create(Ref ref) {
    return cookRunDiscardService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CookRunDiscardService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CookRunDiscardService>(value),
    );
  }
}

String _$cookRunDiscardServiceHash() =>
    r'6111b5ba6128a4e6b596328444632e3b0d88fe34';
