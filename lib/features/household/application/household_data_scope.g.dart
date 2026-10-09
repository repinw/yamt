// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_data_scope.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The active household's data scope, or `null` while the household key is
/// not ready or Firestore is unavailable (signed out, session shutdown).
///
/// This is the one place that decides "no household key". Repositories that
/// get `null` read empty and refuse writes.

@ProviderFor(householdDataScope)
final householdDataScopeProvider = HouseholdDataScopeProvider._();

/// The active household's data scope, or `null` while the household key is
/// not ready or Firestore is unavailable (signed out, session shutdown).
///
/// This is the one place that decides "no household key". Repositories that
/// get `null` read empty and refuse writes.

final class HouseholdDataScopeProvider
    extends
        $FunctionalProvider<
          HouseholdDataScope?,
          HouseholdDataScope?,
          HouseholdDataScope?
        >
    with $Provider<HouseholdDataScope?> {
  /// The active household's data scope, or `null` while the household key is
  /// not ready or Firestore is unavailable (signed out, session shutdown).
  ///
  /// This is the one place that decides "no household key". Repositories that
  /// get `null` read empty and refuse writes.
  HouseholdDataScopeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdDataScopeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdDataScopeHash();

  @$internal
  @override
  $ProviderElement<HouseholdDataScope?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HouseholdDataScope? create(Ref ref) {
    return householdDataScope(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HouseholdDataScope? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HouseholdDataScope?>(value),
    );
  }
}

String _$householdDataScopeHash() =>
    r'd46028dbc0d5dece125ac789b32745fb20cc69bc';
