// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_intro_banner_dismissal_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tracks whether the week 1 diary intro banner has been dismissed.

@ProviderFor(DiaryIntroBannerDismissalController)
final diaryIntroBannerDismissalControllerProvider =
    DiaryIntroBannerDismissalControllerProvider._();

/// Tracks whether the week 1 diary intro banner has been dismissed.
final class DiaryIntroBannerDismissalControllerProvider
    extends $NotifierProvider<DiaryIntroBannerDismissalController, bool> {
  /// Tracks whether the week 1 diary intro banner has been dismissed.
  DiaryIntroBannerDismissalControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryIntroBannerDismissalControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$diaryIntroBannerDismissalControllerHash();

  @$internal
  @override
  DiaryIntroBannerDismissalController create() =>
      DiaryIntroBannerDismissalController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$diaryIntroBannerDismissalControllerHash() =>
    r'd26dc66eb7e1247ed7d20b469b04ff2de4b8f473';

/// Tracks whether the week 1 diary intro banner has been dismissed.

abstract class _$DiaryIntroBannerDismissalController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
