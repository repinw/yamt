// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kochmodus_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Assigning or cooking a [KochmodusTarget]: the household's run, or a draft
/// until its first change; `null` when the recipe or run never existed.
/// Edits are `KochmodusActions`, timers `KochmodusTimerController`.

@ProviderFor(KochmodusController)
final kochmodusControllerProvider = KochmodusControllerFamily._();

/// Assigning or cooking a [KochmodusTarget]: the household's run, or a draft
/// until its first change; `null` when the recipe or run never existed.
/// Edits are `KochmodusActions`, timers `KochmodusTimerController`.
final class KochmodusControllerProvider
    extends $AsyncNotifierProvider<KochmodusController, KochmodusView?> {
  /// Assigning or cooking a [KochmodusTarget]: the household's run, or a draft
  /// until its first change; `null` when the recipe or run never existed.
  /// Edits are `KochmodusActions`, timers `KochmodusTimerController`.
  KochmodusControllerProvider._({
    required KochmodusControllerFamily super.from,
    required KochmodusTarget super.argument,
  }) : super(
         retry: null,
         name: r'kochmodusControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kochmodusControllerHash();

  @override
  String toString() {
    return r'kochmodusControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  KochmodusController create() => KochmodusController();

  @override
  bool operator ==(Object other) {
    return other is KochmodusControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kochmodusControllerHash() =>
    r'aeefd5e335c8f74c2cccc4d549333555df6eab63';

/// Assigning or cooking a [KochmodusTarget]: the household's run, or a draft
/// until its first change; `null` when the recipe or run never existed.
/// Edits are `KochmodusActions`, timers `KochmodusTimerController`.

final class KochmodusControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          KochmodusController,
          AsyncValue<KochmodusView?>,
          KochmodusView?,
          FutureOr<KochmodusView?>,
          KochmodusTarget
        > {
  KochmodusControllerFamily._()
    : super(
        retry: null,
        name: r'kochmodusControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Assigning or cooking a [KochmodusTarget]: the household's run, or a draft
  /// until its first change; `null` when the recipe or run never existed.
  /// Edits are `KochmodusActions`, timers `KochmodusTimerController`.

  KochmodusControllerProvider call(KochmodusTarget target) =>
      KochmodusControllerProvider._(argument: target, from: this);

  @override
  String toString() => r'kochmodusControllerProvider';
}

/// Assigning or cooking a [KochmodusTarget]: the household's run, or a draft
/// until its first change; `null` when the recipe or run never existed.
/// Edits are `KochmodusActions`, timers `KochmodusTimerController`.

abstract class _$KochmodusController extends $AsyncNotifier<KochmodusView?> {
  late final _$args = ref.$arg as KochmodusTarget;
  KochmodusTarget get target => _$args;

  FutureOr<KochmodusView?> build(KochmodusTarget target);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<KochmodusView?>, KochmodusView?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<KochmodusView?>, KochmodusView?>,
              AsyncValue<KochmodusView?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
