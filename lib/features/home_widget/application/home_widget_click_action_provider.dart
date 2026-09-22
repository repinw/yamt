import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/home_widget/application/home_widget_action_uri_codec.dart';
import 'package:yamt/features/home_widget/data/home_widget_plugin_bridge.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';

part 'home_widget_click_action_provider.g.dart';

/// Streams the quick-action intent to open: the app's cold-launch URI first
/// (when the app was launched from a widget tap), then every further tap
/// while the app keeps running. A URI that isn't a widget quick-action is
/// dropped.
@riverpod
Stream<ProductSearchHubInitialIntent> homeWidgetClickAction(Ref ref) async* {
  final bridge = ref.watch(homeWidgetPluginBridgeProvider);
  final initialIntent = parseHomeWidgetActionUri(
    await bridge.loadInitialLaunchUri(),
  );
  if (initialIntent != null) {
    yield initialIntent;
  }
  await for (final uri in bridge.watchClicks()) {
    final intent = parseHomeWidgetActionUri(uri);
    if (intent != null) {
      yield intent;
    }
  }
}
