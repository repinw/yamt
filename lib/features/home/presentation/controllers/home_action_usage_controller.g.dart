// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_action_usage_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Counts how often each action of the home action panel was tapped on this
/// device, so the panel can mark the most used one.

@ProviderFor(HomeActionUsageController)
final homeActionUsageControllerProvider = HomeActionUsageControllerProvider._();

/// Counts how often each action of the home action panel was tapped on this
/// device, so the panel can mark the most used one.
final class HomeActionUsageControllerProvider
    extends $NotifierProvider<HomeActionUsageController, Map<String, int>> {
  /// Counts how often each action of the home action panel was tapped on this
  /// device, so the panel can mark the most used one.
  HomeActionUsageControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeActionUsageControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeActionUsageControllerHash();

  @$internal
  @override
  HomeActionUsageController create() => HomeActionUsageController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, int>>(value),
    );
  }
}

String _$homeActionUsageControllerHash() =>
    r'33de518fd4f09b980fa28cb928ab5b54e7cadd02';

/// Counts how often each action of the home action panel was tapped on this
/// device, so the panel can mark the most used one.

abstract class _$HomeActionUsageController extends $Notifier<Map<String, int>> {
  Map<String, int> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<String, int>, Map<String, int>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, int>, Map<String, int>>,
              Map<String, int>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
