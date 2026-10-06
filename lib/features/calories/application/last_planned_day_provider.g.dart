// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last_planned_day_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The day of the plan saved last, so the diary can open that day.

@ProviderFor(LastPlannedDay)
final lastPlannedDayProvider = LastPlannedDayProvider._();

/// The day of the plan saved last, so the diary can open that day.
final class LastPlannedDayProvider
    extends $NotifierProvider<LastPlannedDay, PlannedDay?> {
  /// The day of the plan saved last, so the diary can open that day.
  LastPlannedDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastPlannedDayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastPlannedDayHash();

  @$internal
  @override
  LastPlannedDay create() => LastPlannedDay();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlannedDay? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlannedDay?>(value),
    );
  }
}

String _$lastPlannedDayHash() => r'76f531fe92ce8559c982772588615285af2bbc59';

/// The day of the plan saved last, so the diary can open that day.

abstract class _$LastPlannedDay extends $Notifier<PlannedDay?> {
  PlannedDay? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PlannedDay?, PlannedDay?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlannedDay?, PlannedDay?>,
              PlannedDay?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
