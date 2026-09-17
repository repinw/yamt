// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_balance_details_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the daily balance card shows all numbers instead of only what is
/// left. The choice is saved on the device.

@ProviderFor(DiaryBalanceDetailsController)
final diaryBalanceDetailsControllerProvider =
    DiaryBalanceDetailsControllerProvider._();

/// Whether the daily balance card shows all numbers instead of only what is
/// left. The choice is saved on the device.
final class DiaryBalanceDetailsControllerProvider
    extends $NotifierProvider<DiaryBalanceDetailsController, bool> {
  /// Whether the daily balance card shows all numbers instead of only what is
  /// left. The choice is saved on the device.
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
    r'789aed5f0761a8a3b3f0a3378804e8947ae15f67';

/// Whether the daily balance card shows all numbers instead of only what is
/// left. The choice is saved on the device.

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
