// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_widget_sync_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps the home-screen widget's saved snapshot in sync with today's diary
/// summary and the silent/verbose preference.
///
/// Auto-dispose like the providers it listens to. `lib/app.dart` holds a
/// listener on it for the app's lifetime: that keeps it and its `ref.listen`
/// subscriptions active. Without an active listener Riverpod pauses those
/// subscriptions and the diary summary is disposed.

@ProviderFor(HomeWidgetSyncController)
final homeWidgetSyncControllerProvider = HomeWidgetSyncControllerProvider._();

/// Keeps the home-screen widget's saved snapshot in sync with today's diary
/// summary and the silent/verbose preference.
///
/// Auto-dispose like the providers it listens to. `lib/app.dart` holds a
/// listener on it for the app's lifetime: that keeps it and its `ref.listen`
/// subscriptions active. Without an active listener Riverpod pauses those
/// subscriptions and the diary summary is disposed.
final class HomeWidgetSyncControllerProvider
    extends $NotifierProvider<HomeWidgetSyncController, void> {
  /// Keeps the home-screen widget's saved snapshot in sync with today's diary
  /// summary and the silent/verbose preference.
  ///
  /// Auto-dispose like the providers it listens to. `lib/app.dart` holds a
  /// listener on it for the app's lifetime: that keeps it and its `ref.listen`
  /// subscriptions active. Without an active listener Riverpod pauses those
  /// subscriptions and the diary summary is disposed.
  HomeWidgetSyncControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeWidgetSyncControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeWidgetSyncControllerHash();

  @$internal
  @override
  HomeWidgetSyncController create() => HomeWidgetSyncController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$homeWidgetSyncControllerHash() =>
    r'449cfdfd71ee419873679909e6abad315b9a425a';

/// Keeps the home-screen widget's saved snapshot in sync with today's diary
/// summary and the silent/verbose preference.
///
/// Auto-dispose like the providers it listens to. `lib/app.dart` holds a
/// listener on it for the app's lifetime: that keeps it and its `ref.listen`
/// subscriptions active. Without an active listener Riverpod pauses those
/// subscriptions and the diary summary is disposed.

abstract class _$HomeWidgetSyncController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
