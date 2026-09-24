// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_key_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether this platform can save the recovery key in the password manager.

@ProviderFor(canSaveRecoveryKeyToPasswordManager)
final canSaveRecoveryKeyToPasswordManagerProvider =
    CanSaveRecoveryKeyToPasswordManagerProvider._();

/// Whether this platform can save the recovery key in the password manager.

final class CanSaveRecoveryKeyToPasswordManagerProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether this platform can save the recovery key in the password manager.
  CanSaveRecoveryKeyToPasswordManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'canSaveRecoveryKeyToPasswordManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$canSaveRecoveryKeyToPasswordManagerHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return canSaveRecoveryKeyToPasswordManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$canSaveRecoveryKeyToPasswordManagerHash() =>
    r'6a45a5164cec745a0023dd0dbf84c5de4897710f';

/// Runs the actions of the data key pages.

@ProviderFor(DataKeyController)
final dataKeyControllerProvider = DataKeyControllerProvider._();

/// Runs the actions of the data key pages.
final class DataKeyControllerProvider
    extends $AsyncNotifierProvider<DataKeyController, void> {
  /// Runs the actions of the data key pages.
  DataKeyControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataKeyControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataKeyControllerHash();

  @$internal
  @override
  DataKeyController create() => DataKeyController();
}

String _$dataKeyControllerHash() => r'd43cbe7de3019922177094a2fc5384231e9e0f12';

/// Runs the actions of the data key pages.

abstract class _$DataKeyController extends $AsyncNotifier<void> {
  FutureOr<void> build();
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
    return element.handleCreate(ref, build);
  }
}
