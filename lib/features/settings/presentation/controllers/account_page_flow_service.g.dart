// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_page_flow_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The account page flow service provider.

@ProviderFor(accountPageFlowService)
final accountPageFlowServiceProvider = AccountPageFlowServiceProvider._();

/// The account page flow service provider.

final class AccountPageFlowServiceProvider
    extends
        $FunctionalProvider<
          AccountPageFlowService,
          AccountPageFlowService,
          AccountPageFlowService
        >
    with $Provider<AccountPageFlowService> {
  /// The account page flow service provider.
  AccountPageFlowServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountPageFlowServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountPageFlowServiceHash();

  @$internal
  @override
  $ProviderElement<AccountPageFlowService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AccountPageFlowService create(Ref ref) {
    return accountPageFlowService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountPageFlowService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountPageFlowService>(value),
    );
  }
}

String _$accountPageFlowServiceHash() =>
    r'818f5b01fd7bd66f8bde1b83472001b8412ea7f6';
