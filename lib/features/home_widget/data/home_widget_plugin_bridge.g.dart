// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_widget_plugin_bridge.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [HomeWidgetPluginBridge].

@ProviderFor(homeWidgetPluginBridge)
final homeWidgetPluginBridgeProvider = HomeWidgetPluginBridgeProvider._();

/// Provides the [HomeWidgetPluginBridge].

final class HomeWidgetPluginBridgeProvider
    extends
        $FunctionalProvider<
          HomeWidgetPluginBridge,
          HomeWidgetPluginBridge,
          HomeWidgetPluginBridge
        >
    with $Provider<HomeWidgetPluginBridge> {
  /// Provides the [HomeWidgetPluginBridge].
  HomeWidgetPluginBridgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeWidgetPluginBridgeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeWidgetPluginBridgeHash();

  @$internal
  @override
  $ProviderElement<HomeWidgetPluginBridge> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HomeWidgetPluginBridge create(Ref ref) {
    return homeWidgetPluginBridge(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeWidgetPluginBridge value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeWidgetPluginBridge>(value),
    );
  }
}

String _$homeWidgetPluginBridgeHash() =>
    r'd4061d556ebd2294833e09c2e4dfda94d3a93800';
