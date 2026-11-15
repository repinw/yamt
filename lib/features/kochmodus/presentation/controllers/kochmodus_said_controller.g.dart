// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kochmodus_said_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What the lines said or typed while cooking the [KochmodusTarget] did, the
/// last one last, for "nein". The page's `KochmodusController` listens to it,
/// so it lasts as long as the page and stays while the cook switches tabs or
/// between guide and list. Its actions change the run through that
/// controller, which the caller hands in (it cannot read the controller that
/// listens to it).

@ProviderFor(KochmodusSaidController)
final kochmodusSaidControllerProvider = KochmodusSaidControllerFamily._();

/// What the lines said or typed while cooking the [KochmodusTarget] did, the
/// last one last, for "nein". The page's `KochmodusController` listens to it,
/// so it lasts as long as the page and stays while the cook switches tabs or
/// between guide and list. Its actions change the run through that
/// controller, which the caller hands in (it cannot read the controller that
/// listens to it).
final class KochmodusSaidControllerProvider
    extends $NotifierProvider<KochmodusSaidController, List<KochmodusSaid>> {
  /// What the lines said or typed while cooking the [KochmodusTarget] did, the
  /// last one last, for "nein". The page's `KochmodusController` listens to it,
  /// so it lasts as long as the page and stays while the cook switches tabs or
  /// between guide and list. Its actions change the run through that
  /// controller, which the caller hands in (it cannot read the controller that
  /// listens to it).
  KochmodusSaidControllerProvider._({
    required KochmodusSaidControllerFamily super.from,
    required KochmodusTarget super.argument,
  }) : super(
         retry: null,
         name: r'kochmodusSaidControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kochmodusSaidControllerHash();

  @override
  String toString() {
    return r'kochmodusSaidControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  KochmodusSaidController create() => KochmodusSaidController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<KochmodusSaid> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<KochmodusSaid>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is KochmodusSaidControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kochmodusSaidControllerHash() =>
    r'ace1cb92627a8afd39a0a3f91dab4e53982284fb';

/// What the lines said or typed while cooking the [KochmodusTarget] did, the
/// last one last, for "nein". The page's `KochmodusController` listens to it,
/// so it lasts as long as the page and stays while the cook switches tabs or
/// between guide and list. Its actions change the run through that
/// controller, which the caller hands in (it cannot read the controller that
/// listens to it).

final class KochmodusSaidControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          KochmodusSaidController,
          List<KochmodusSaid>,
          List<KochmodusSaid>,
          List<KochmodusSaid>,
          KochmodusTarget
        > {
  KochmodusSaidControllerFamily._()
    : super(
        retry: null,
        name: r'kochmodusSaidControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// What the lines said or typed while cooking the [KochmodusTarget] did, the
  /// last one last, for "nein". The page's `KochmodusController` listens to it,
  /// so it lasts as long as the page and stays while the cook switches tabs or
  /// between guide and list. Its actions change the run through that
  /// controller, which the caller hands in (it cannot read the controller that
  /// listens to it).

  KochmodusSaidControllerProvider call(KochmodusTarget target) =>
      KochmodusSaidControllerProvider._(argument: target, from: this);

  @override
  String toString() => r'kochmodusSaidControllerProvider';
}

/// What the lines said or typed while cooking the [KochmodusTarget] did, the
/// last one last, for "nein". The page's `KochmodusController` listens to it,
/// so it lasts as long as the page and stays while the cook switches tabs or
/// between guide and list. Its actions change the run through that
/// controller, which the caller hands in (it cannot read the controller that
/// listens to it).

abstract class _$KochmodusSaidController
    extends $Notifier<List<KochmodusSaid>> {
  late final _$args = ref.$arg as KochmodusTarget;
  KochmodusTarget get target => _$args;

  List<KochmodusSaid> build(KochmodusTarget target);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<KochmodusSaid>, List<KochmodusSaid>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<KochmodusSaid>, List<KochmodusSaid>>,
              List<KochmodusSaid>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
