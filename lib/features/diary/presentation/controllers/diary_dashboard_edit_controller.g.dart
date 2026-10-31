// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_dashboard_edit_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the diary dashboard is in edit mode, for every day page at once.
/// Not saved: the dashboard opens outside edit mode.

@ProviderFor(DiaryDashboardEditController)
final diaryDashboardEditControllerProvider =
    DiaryDashboardEditControllerProvider._();

/// Whether the diary dashboard is in edit mode, for every day page at once.
/// Not saved: the dashboard opens outside edit mode.
final class DiaryDashboardEditControllerProvider
    extends $NotifierProvider<DiaryDashboardEditController, bool> {
  /// Whether the diary dashboard is in edit mode, for every day page at once.
  /// Not saved: the dashboard opens outside edit mode.
  DiaryDashboardEditControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryDashboardEditControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryDashboardEditControllerHash();

  @$internal
  @override
  DiaryDashboardEditController create() => DiaryDashboardEditController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$diaryDashboardEditControllerHash() =>
    r'26f886ab7a51299ebf5206ef07502d780820b546';

/// Whether the diary dashboard is in edit mode, for every day page at once.
/// Not saved: the dashboard opens outside edit mode.

abstract class _$DiaryDashboardEditController extends $Notifier<bool> {
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
