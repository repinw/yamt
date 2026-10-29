// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_balance_details_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the budget card shows its details: the eaten grams, the ledger
/// and the week strip. Starts closed whenever the diary opens.

@ProviderFor(DiaryBalanceDetailsController)
final diaryBalanceDetailsControllerProvider =
    DiaryBalanceDetailsControllerProvider._();

/// Whether the budget card shows its details: the eaten grams, the ledger
/// and the week strip. Starts closed whenever the diary opens.
final class DiaryBalanceDetailsControllerProvider
    extends $NotifierProvider<DiaryBalanceDetailsController, bool> {
  /// Whether the budget card shows its details: the eaten grams, the ledger
  /// and the week strip. Starts closed whenever the diary opens.
  DiaryBalanceDetailsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryBalanceDetailsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryBalanceDetailsControllerHash();

  @$internal
  @override
  DiaryBalanceDetailsController create() => DiaryBalanceDetailsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$diaryBalanceDetailsControllerHash() =>
    r'8c9ef6727b0d933ec6634414363763647bbb4bd0';

/// Whether the budget card shows its details: the eaten grams, the ledger
/// and the week strip. Starts closed whenever the diary opens.

abstract class _$DiaryBalanceDetailsController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
