// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_balance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Actions needed by diary balance presentation widgets.

@ProviderFor(diaryBalanceActions)
final diaryBalanceActionsProvider = DiaryBalanceActionsProvider._();

/// Actions needed by diary balance presentation widgets.

final class DiaryBalanceActionsProvider
    extends
        $FunctionalProvider<
          DiaryBalanceActions,
          DiaryBalanceActions,
          DiaryBalanceActions
        >
    with $Provider<DiaryBalanceActions> {
  /// Actions needed by diary balance presentation widgets.
  DiaryBalanceActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryBalanceActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryBalanceActionsHash();

  @$internal
  @override
  $ProviderElement<DiaryBalanceActions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryBalanceActions create(Ref ref) {
    return diaryBalanceActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryBalanceActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryBalanceActions>(value),
    );
  }
}

String _$diaryBalanceActionsHash() =>
    r'a5281f5532ca9c49e65c89a22eae57549da14bb1';
