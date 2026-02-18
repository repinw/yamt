// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthFormController)
final authFormControllerProvider = AuthFormControllerProvider._();

final class AuthFormControllerProvider
    extends $AsyncNotifierProvider<AuthFormController, void> {
  AuthFormControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authFormControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authFormControllerHash();

  @$internal
  @override
  AuthFormController create() => AuthFormController();
}

String _$authFormControllerHash() =>
    r'040a1e62855e8d5d21d965286bec4b4980050522';

abstract class _$AuthFormController extends $AsyncNotifier<void> {
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
