// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_entry_day_change.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Refreshes the diary overview and marks the weekly check-ins from the
/// entry's day as stale. A failed check-in update is logged.

@ProviderFor(calorieEntryDayChange)
final calorieEntryDayChangeProvider = CalorieEntryDayChangeProvider._();

/// Refreshes the diary overview and marks the weekly check-ins from the
/// entry's day as stale. A failed check-in update is logged.

final class CalorieEntryDayChangeProvider
    extends
        $FunctionalProvider<
          CalorieEntryDayChange,
          CalorieEntryDayChange,
          CalorieEntryDayChange
        >
    with $Provider<CalorieEntryDayChange> {
  /// Refreshes the diary overview and marks the weekly check-ins from the
  /// entry's day as stale. A failed check-in update is logged.
  CalorieEntryDayChangeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieEntryDayChangeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieEntryDayChangeHash();

  @$internal
  @override
  $ProviderElement<CalorieEntryDayChange> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieEntryDayChange create(Ref ref) {
    return calorieEntryDayChange(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieEntryDayChange value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieEntryDayChange>(value),
    );
  }
}

String _$calorieEntryDayChangeHash() =>
    r'c0d21aee87c850b0b02b3a5c1963c667ce81a9b9';
