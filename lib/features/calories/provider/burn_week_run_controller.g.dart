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
    r'23285eb5590b455fab38e07f08068d1659588229';

/// Real Burn Week run controller.

abstract class _$BurnWeekRunController
    extends $AsyncNotifier<BurnWeekRunState> {
  FutureOr<BurnWeekRunState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, build);
  }
}
