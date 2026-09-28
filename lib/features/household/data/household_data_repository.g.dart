// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_data_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Household data repository, or `null` while Firebase is unavailable.

@ProviderFor(householdDataRepository)
final householdDataRepositoryProvider = HouseholdDataRepositoryProvider._();

/// Household data repository, or `null` while Firebase is unavailable.

final class HouseholdDataRepositoryProvider
    extends
        $FunctionalProvider<
          HouseholdDataRepository?,
          HouseholdDataRepository?,
          HouseholdDataRepository?
        >
    with $Provider<HouseholdDataRepository?> {
  /// Household data repository, or `null` while Firebase is unavailable.
  HouseholdDataRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdDataRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdDataRepositoryHash();

  @$internal
  @override
  $ProviderElement<HouseholdDataRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HouseholdDataRepository? create(Ref ref) {
    return householdDataRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HouseholdDataRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HouseholdDataRepository?>(value),
    );
  }
}

String _$householdDataRepositoryHash() =>
    r'05c8cc78e9e08cbdd579bbe3e7de641adecea635';
