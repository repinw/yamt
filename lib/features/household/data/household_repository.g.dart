// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Household repository, or `null` while signed out or Firebase is
/// unavailable.

@ProviderFor(householdRepository)
final householdRepositoryProvider = HouseholdRepositoryProvider._();

/// Household repository, or `null` while signed out or Firebase is
/// unavailable.

final class HouseholdRepositoryProvider
    extends
        $FunctionalProvider<
          HouseholdRepository?,
          HouseholdRepository?,
          HouseholdRepository?
        >
    with $Provider<HouseholdRepository?> {
  /// Household repository, or `null` while signed out or Firebase is
  /// unavailable.
  HouseholdRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdRepositoryHash();

  @$internal
  @override
  $ProviderElement<HouseholdRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HouseholdRepository? create(Ref ref) {
    return householdRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HouseholdRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HouseholdRepository?>(value),
    );
  }
}

String _$householdRepositoryHash() =>
    r'dd906082427376fd978759e69f1d6f48f8a6e55e';
