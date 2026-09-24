// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_link_conflict_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolves a guest link whose sign-in method another account already uses.

@ProviderFor(AccountLinkConflictController)
final accountLinkConflictControllerProvider =
    AccountLinkConflictControllerProvider._();

/// Resolves a guest link whose sign-in method another account already uses.
final class AccountLinkConflictControllerProvider
    extends $AsyncNotifierProvider<AccountLinkConflictController, void> {
  /// Resolves a guest link whose sign-in method another account already uses.
  AccountLinkConflictControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountLinkConflictControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountLinkConflictControllerHash();

  @$internal
  @override
  AccountLinkConflictController create() => AccountLinkConflictController();
}

String _$accountLinkConflictControllerHash() =>
    r'628978c174ac1be9a093ff998469232eff49d720';

/// Resolves a guest link whose sign-in method another account already uses.

abstract class _$AccountLinkConflictController extends $AsyncNotifier<void> {
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
