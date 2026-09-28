// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_reset_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Household reset repository, or `null` while Firebase is unavailable.

@ProviderFor(householdResetRepository)
final householdResetRepositoryProvider = HouseholdResetRepositoryProvider._();

/// Household reset repository, or `null` while Firebase is unavailable.

final class HouseholdResetRepositoryProvider
    extends
        $FunctionalProvider<
          HouseholdResetRepository?,
          HouseholdResetRepository?,
          HouseholdResetRepository?
        >
    with $Provider<HouseholdResetRepository?> {
  /// Household reset repository, or `null` while Firebase is unavailable.
  HouseholdResetRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdResetRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdResetRepositoryHash();

  @$internal
  @override
  $ProviderElement<HouseholdResetRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HouseholdResetRepository? create(Ref ref) {
    return householdResetRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HouseholdResetRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HouseholdResetRepository?>(value),
    );
  }
}

String _$householdResetRepositoryHash() =>
    r'3e3cef681b58c4c0a44a151edeeabc622c2c395f';
