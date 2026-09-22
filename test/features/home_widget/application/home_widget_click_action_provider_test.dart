import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/home_widget/application/'
    'home_widget_click_action_provider.dart';
import 'package:yamt/features/home_widget/data/home_widget_plugin_bridge.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';

import '../support/fake_home_widget_plugin_bridge.dart';

void main() {
  Future<List<ProductSearchHubInitialIntent>> collect(
    FakeHomeWidgetPluginBridge bridge,
    void Function() act,
  ) async {
    final container = ProviderContainer(
      overrides: [homeWidgetPluginBridgeProvider.overrideWithValue(bridge)],
    );
    addTearDown(container.dispose);
    addTearDown(bridge.dispose);
    final intents = <ProductSearchHubInitialIntent>[];
    final subscription = container.listen(homeWidgetClickActionProvider, (
      _,
      next,
    ) {
      if (next case AsyncData(:final value)) {
        intents.add(value);
      }
    });
    addTearDown(subscription.close);
    await Future<void>.delayed(Duration.zero);
    act();
    await Future<void>.delayed(Duration.zero);
    return intents;
  }

  test('emits the cold-launch quick-add intent first', () async {
    final bridge = FakeHomeWidgetPluginBridge(
      initialLaunchUri: Uri.parse('homewidget://quick-add?intent=ai'),
    );

    final intents = await collect(bridge, () {});

    expect(intents, [ProductSearchHubInitialIntent.ai]);
  });

  test('emits taps while running and drops non-quick-add uris', () async {
    final bridge = FakeHomeWidgetPluginBridge();

    final intents = await collect(bridge, () {
      bridge
        ..click(Uri.parse('homewidget://open'))
        ..click(Uri.parse('homewidget://quick-add?intent=barcode'));
    });

    expect(intents, [ProductSearchHubInitialIntent.barcode]);
  });
}
