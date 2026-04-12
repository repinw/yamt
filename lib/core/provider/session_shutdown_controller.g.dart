// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_shutdown_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionShutdownSignal)
final sessionShutdownSignalProvider = SessionShutdownSignalProvider._();

final class SessionShutdownSignalProvider
    extends
        $FunctionalProvider<
          SessionShutdownSignal,
          SessionShutdownSignal,
          SessionShutdownSignal
        >
    with $Provider<SessionShutdownSignal> {
  SessionShutdownSignalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionShutdownSignalProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionShutdownSignalHash();

  @$internal
  @override
  $ProviderElement<SessionShutdownSignal> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SessionShutdownSignal create(Ref ref) {
    return sessionShutdownSignal(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionShutdownSignal value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionShutdownSignal>(value),
    );
  }
}

String _$sessionShutdownSignalHash() =>
    r'2effb4f7f3e0ab3d2cb57d4dd1a8b68fb60ef83e';

@ProviderFor(SessionShutdownController)
final sessionShutdownControllerProvider = SessionShutdownControllerProvider._();

final class SessionShutdownControllerProvider
    extends $NotifierProvider<SessionShutdownController, bool> {
  SessionShutdownControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionShutdownControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionShutdownControllerHash();

  @$internal
  @override
  SessionShutdownController create() => SessionShutdownController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$sessionShutdownControllerHash() =>
    r'fff8e1eb265b45b392217631120de5a04497f196';

abstract class _$SessionShutdownController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
