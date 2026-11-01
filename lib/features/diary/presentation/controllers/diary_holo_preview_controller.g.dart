// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_holo_preview_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Debug switch that puts the budget card in holo foil without hitting the
/// target. Off on every start. Kept alive so the switch holds after the
/// menu that set it closes, also before a budget card watches it.

@ProviderFor(DiaryHoloPreviewController)
final diaryHoloPreviewControllerProvider =
    DiaryHoloPreviewControllerProvider._();

/// Debug switch that puts the budget card in holo foil without hitting the
/// target. Off on every start. Kept alive so the switch holds after the
/// menu that set it closes, also before a budget card watches it.
final class DiaryHoloPreviewControllerProvider
    extends $NotifierProvider<DiaryHoloPreviewController, bool> {
  /// Debug switch that puts the budget card in holo foil without hitting the
  /// target. Off on every start. Kept alive so the switch holds after the
  /// menu that set it closes, also before a budget card watches it.
  DiaryHoloPreviewControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryHoloPreviewControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryHoloPreviewControllerHash();

  @$internal
  @override
  DiaryHoloPreviewController create() => DiaryHoloPreviewController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$diaryHoloPreviewControllerHash() =>
    r'f1ce69c5afd42fcbb294a50873eb0c17d259e2d3';

/// Debug switch that puts the budget card in holo foil without hitting the
/// target. Off on every start. Kept alive so the switch holds after the
/// menu that set it closes, also before a budget card watches it.

abstract class _$DiaryHoloPreviewController extends $Notifier<bool> {
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
