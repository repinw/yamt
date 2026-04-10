// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(secondaryAuthClient)
final secondaryAuthClientProvider = SecondaryAuthClientProvider._();

final class SecondaryAuthClientProvider
    extends
        $FunctionalProvider<
          SecondaryAuthClient,
          SecondaryAuthClient,
          SecondaryAuthClient
        >
    with $Provider<SecondaryAuthClient> {
  SecondaryAuthClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'secondaryAuthClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$secondaryAuthClientHash();

  @$internal
  @override
  $ProviderElement<SecondaryAuthClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SecondaryAuthClient create(Ref ref) {
    return secondaryAuthClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SecondaryAuthClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SecondaryAuthClient>(value),
    );
  }
}

String _$secondaryAuthClientHash() =>
    r'8ecfce9b38fd112781068553f10e45f381588e66';

@ProviderFor(AccountController)
final accountControllerProvider = AccountControllerProvider._();

final class AccountControllerProvider
    extends $AsyncNotifierProvider<AccountController, void> {
  AccountControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountControllerHash();

  @$internal
  @override
  AccountController create() => AccountController();
}

String _$accountControllerHash() => r'cb40c00d17817d03970f4f68fd4e5c8ef126f64f';

abstract class _$AccountController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
