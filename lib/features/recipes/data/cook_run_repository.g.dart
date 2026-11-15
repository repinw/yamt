// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cook_run_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The cook run repository of the active household.

@ProviderFor(cookRunRepository)
final cookRunRepositoryProvider = CookRunRepositoryProvider._();

/// The cook run repository of the active household.

final class CookRunRepositoryProvider
    extends
        $FunctionalProvider<
          CookRunRepository,
          CookRunRepository,
          CookRunRepository
        >
    with $Provider<CookRunRepository> {
  /// The cook run repository of the active household.
  CookRunRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookRunRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookRunRepositoryHash();

  @$internal
  @override
  $ProviderElement<CookRunRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CookRunRepository create(Ref ref) {
    return cookRunRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CookRunRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CookRunRepository>(value),
    );
  }
}

String _$cookRunRepositoryHash() => r'ffe2568b056eb6744ff5d9114fbc9fd9ea869cad';
