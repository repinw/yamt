// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_dashboard_layout_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The diary dashboard layout of the signed-in user, resolved against
/// [diaryDashboardTileSpecs]. Drags change it live; [save] stores it.
///
/// The actions that save return false when the layout was not saved; the
/// layout on screen keeps the change.

@ProviderFor(DiaryDashboardLayoutController)
final diaryDashboardLayoutControllerProvider =
    DiaryDashboardLayoutControllerProvider._();

/// The diary dashboard layout of the signed-in user, resolved against
/// [diaryDashboardTileSpecs]. Drags change it live; [save] stores it.
///
/// The actions that save return false when the layout was not saved; the
/// layout on screen keeps the change.
final class DiaryDashboardLayoutControllerProvider
    extends
        $NotifierProvider<
          DiaryDashboardLayoutController,
          DiaryDashboardLayout
        > {
  /// The diary dashboard layout of the signed-in user, resolved against
  /// [diaryDashboardTileSpecs]. Drags change it live; [save] stores it.
  ///
  /// The actions that save return false when the layout was not saved; the
  /// layout on screen keeps the change.
  DiaryDashboardLayoutControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryDashboardLayoutControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryDashboardLayoutControllerHash();

  @$internal
  @override
  DiaryDashboardLayoutController create() => DiaryDashboardLayoutController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryDashboardLayout value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryDashboardLayout>(value),
    );
  }
}

String _$diaryDashboardLayoutControllerHash() =>
    r'6d8b1e8b50dfccd3b385d639db08f1d8424f37f5';

/// The diary dashboard layout of the signed-in user, resolved against
/// [diaryDashboardTileSpecs]. Drags change it live; [save] stores it.
///
/// The actions that save return false when the layout was not saved; the
/// layout on screen keeps the change.

abstract class _$DiaryDashboardLayoutController
    extends $Notifier<DiaryDashboardLayout> {
  DiaryDashboardLayout build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DiaryDashboardLayout, DiaryDashboardLayout>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DiaryDashboardLayout, DiaryDashboardLayout>,
              DiaryDashboardLayout,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
