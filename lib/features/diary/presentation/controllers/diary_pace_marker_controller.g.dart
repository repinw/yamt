// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_pace_marker_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether today's kcal line marks where the day should be by now, saved on
/// the device. Off until the user turns it on in the budget card's menu.

@ProviderFor(DiaryPaceMarkerController)
final diaryPaceMarkerControllerProvider = DiaryPaceMarkerControllerProvider._();

/// Whether today's kcal line marks where the day should be by now, saved on
/// the device. Off until the user turns it on in the budget card's menu.
final class DiaryPaceMarkerControllerProvider
    extends $NotifierProvider<DiaryPaceMarkerController, bool> {
  /// Whether today's kcal line marks where the day should be by now, saved on
  /// the device. Off until the user turns it on in the budget card's menu.
  DiaryPaceMarkerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryPaceMarkerControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryPaceMarkerControllerHash();

  @$internal
  @override
  DiaryPaceMarkerController create() => DiaryPaceMarkerController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$diaryPaceMarkerControllerHash() =>
    r'd3dc98812ce2f36291469b81ca2c31c691096830';

/// Whether today's kcal line marks where the day should be by now, saved on
/// the device. Off until the user turns it on in the budget card's menu.

abstract class _$DiaryPaceMarkerController extends $Notifier<bool> {
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
