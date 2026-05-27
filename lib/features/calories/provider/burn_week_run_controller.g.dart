// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'burn_week_run_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Real Burn Week run controller.

@ProviderFor(BurnWeekRunController)
final burnWeekRunControllerProvider = BurnWeekRunControllerProvider._();

/// Real Burn Week run controller.
final class BurnWeekRunControllerProvider
    extends $AsyncNotifierProvider<BurnWeekRunController, BurnWeekRunState> {
  /// Real Burn Week run controller.
  BurnWeekRunControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'burnWeekRunControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$burnWeekRunControllerHash();

  @$internal
  @override
  BurnWeekRunController create() => BurnWeekRunController();
}

String _$burnWeekRunControllerHash() =>
    r'ac22eb2c45fef52f27d4e9702ee38ff81ed1f8e2';

/// Real Burn Week run controller.

abstract class _$BurnWeekRunController
    extends $AsyncNotifier<BurnWeekRunState> {
  FutureOr<BurnWeekRunState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<BurnWeekRunState>, BurnWeekRunState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BurnWeekRunState>, BurnWeekRunState>,
              AsyncValue<BurnWeekRunState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
