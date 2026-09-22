// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_widget_click_action_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Streams the quick-action intent to open: the app's cold-launch URI first
/// (when the app was launched from a widget tap), then every further tap
/// while the app keeps running. A URI that isn't a widget quick-action is
/// dropped.

@ProviderFor(homeWidgetClickAction)
final homeWidgetClickActionProvider = HomeWidgetClickActionProvider._();

/// Streams the quick-action intent to open: the app's cold-launch URI first
/// (when the app was launched from a widget tap), then every further tap
/// while the app keeps running. A URI that isn't a widget quick-action is
/// dropped.

final class HomeWidgetClickActionProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProductSearchHubInitialIntent>,
          ProductSearchHubInitialIntent,
          Stream<ProductSearchHubInitialIntent>
        >
    with
        $FutureModifier<ProductSearchHubInitialIntent>,
        $StreamProvider<ProductSearchHubInitialIntent> {
  /// Streams the quick-action intent to open: the app's cold-launch URI first
  /// (when the app was launched from a widget tap), then every further tap
  /// while the app keeps running. A URI that isn't a widget quick-action is
  /// dropped.
  HomeWidgetClickActionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeWidgetClickActionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeWidgetClickActionHash();

  @$internal
  @override
  $StreamProviderElement<ProductSearchHubInitialIntent> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ProductSearchHubInitialIntent> create(Ref ref) {
    return homeWidgetClickAction(ref);
  }
}

String _$homeWidgetClickActionHash() =>
    r'27379fc211c3e90685d0504894227ddd524a8be9';
