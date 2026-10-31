// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_dashboard_layout_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The diary dashboard layout of the signed-in user, resolved against the
/// tile catalog. Drags change it live; [save] stores it.

@ProviderFor(DiaryDashboardLayoutController)
final diaryDashboardLayoutControllerProvider =
    DiaryDashboardLayoutControllerProvider._();

/// The diary dashboard layout of the signed-in user, resolved against the
/// tile catalog. Drags change it live; [save] stores it.
final class DiaryDashboardLayoutControllerProvider
    extends
        $NotifierProvider<
          DiaryDashboardLayoutController,
          DiaryDashboardLayout
        > {
  /// The diary dashboard layout of the signed-in user, resolved against the
  /// tile catalog. Drags change it live; [save] stores it.
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
    r'b815e6b54cefa00114eb17cac8dacf42fd959532';

/// The diary dashboard layout of the signed-in user, resolved against the
/// tile catalog. Drags change it live; [save] stores it.

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
