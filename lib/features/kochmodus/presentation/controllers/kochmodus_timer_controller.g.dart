// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kochmodus_timer_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Starts, extends and stops the timers of cooking the [KochmodusTarget];
/// each action is one change of the run (`KochmodusController.change`) and
/// returns whether it worked.

@ProviderFor(KochmodusTimerController)
final kochmodusTimerControllerProvider = KochmodusTimerControllerFamily._();

/// Starts, extends and stops the timers of cooking the [KochmodusTarget];
/// each action is one change of the run (`KochmodusController.change`) and
/// returns whether it worked.
final class KochmodusTimerControllerProvider
    extends $AsyncNotifierProvider<KochmodusTimerController, void> {
  /// Starts, extends and stops the timers of cooking the [KochmodusTarget];
  /// each action is one change of the run (`KochmodusController.change`) and
  /// returns whether it worked.
  KochmodusTimerControllerProvider._({
    required KochmodusTimerControllerFamily super.from,
    required KochmodusTarget super.argument,
  }) : super(
         retry: null,
         name: r'kochmodusTimerControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kochmodusTimerControllerHash();

  @override
  String toString() {
    return r'kochmodusTimerControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  KochmodusTimerController create() => KochmodusTimerController();

  @override
  bool operator ==(Object other) {
    return other is KochmodusTimerControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kochmodusTimerControllerHash() =>
    r'2bec6add3765ff21dbb97433d5d1889864e61a25';

/// Starts, extends and stops the timers of cooking the [KochmodusTarget];
/// each action is one change of the run (`KochmodusController.change`) and
/// returns whether it worked.

final class KochmodusTimerControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          KochmodusTimerController,
          AsyncValue<void>,
          void,
          FutureOr<void>,
          KochmodusTarget
        > {
  KochmodusTimerControllerFamily._()
    : super(
        retry: null,
        name: r'kochmodusTimerControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Starts, extends and stops the timers of cooking the [KochmodusTarget];
  /// each action is one change of the run (`KochmodusController.change`) and
  /// returns whether it worked.

  KochmodusTimerControllerProvider call(KochmodusTarget target) =>
      KochmodusTimerControllerProvider._(argument: target, from: this);

  @override
  String toString() => r'kochmodusTimerControllerProvider';
}

/// Starts, extends and stops the timers of cooking the [KochmodusTarget];
/// each action is one change of the run (`KochmodusController.change`) and
/// returns whether it worked.

abstract class _$KochmodusTimerController extends $AsyncNotifier<void> {
  late final _$args = ref.$arg as KochmodusTarget;
  KochmodusTarget get target => _$args;

  FutureOr<void> build(KochmodusTarget target);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
