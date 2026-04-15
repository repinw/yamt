// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_overview_revision_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Global revision counter for diary mutations that affect day/week overviews.

@ProviderFor(CalorieOverviewRevision)
final calorieOverviewRevisionProvider = CalorieOverviewRevisionProvider._();

/// Global revision counter for diary mutations that affect day/week overviews.
final class CalorieOverviewRevisionProvider
    extends $NotifierProvider<CalorieOverviewRevision, int> {
  /// Global revision counter for diary mutations that affect day/week overviews.
  CalorieOverviewRevisionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieOverviewRevisionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieOverviewRevisionHash();

  @$internal
  @override
  CalorieOverviewRevision create() => CalorieOverviewRevision();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$calorieOverviewRevisionHash() =>
    r'34543997a4e1a240ad1e3699ee1eb4c80df2333e';

/// Global revision counter for diary mutations that affect day/week overviews.

abstract class _$CalorieOverviewRevision extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
