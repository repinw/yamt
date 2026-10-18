// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_weight_health_hint_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the weight list still shows the large card that connects Health.
/// Once a user dismissed it on this device, the page shows them a small icon
/// instead.

@ProviderFor(ProgressWeightHealthHintController)
final progressWeightHealthHintControllerProvider =
    ProgressWeightHealthHintControllerProvider._();

/// Whether the weight list still shows the large card that connects Health.
/// Once a user dismissed it on this device, the page shows them a small icon
/// instead.
final class ProgressWeightHealthHintControllerProvider
    extends $NotifierProvider<ProgressWeightHealthHintController, bool> {
  /// Whether the weight list still shows the large card that connects Health.
  /// Once a user dismissed it on this device, the page shows them a small icon
  /// instead.
  ProgressWeightHealthHintControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressWeightHealthHintControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$progressWeightHealthHintControllerHash();

  @$internal
  @override
  ProgressWeightHealthHintController create() =>
      ProgressWeightHealthHintController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$progressWeightHealthHintControllerHash() =>
    r'94536b0f92d525cdfc74ca056a19767ff7496a6f';

/// Whether the weight list still shows the large card that connects Health.
/// Once a user dismissed it on this device, the page shows them a small icon
/// instead.

abstract class _$ProgressWeightHealthHintController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
