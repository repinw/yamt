// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_page_flow_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(accountPageFlowService)
final accountPageFlowServiceProvider = AccountPageFlowServiceProvider._();

final class AccountPageFlowServiceProvider
    extends
        $FunctionalProvider<
          AccountPageFlowService,
          AccountPageFlowService,
          AccountPageFlowService
        >
    with $Provider<AccountPageFlowService> {
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
    r'b2542c11297ceec5aa32f216e9fcde3a515fd991';
