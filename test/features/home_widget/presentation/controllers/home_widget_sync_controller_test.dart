import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/presentation/controllers/'
    'diary_day_dashboard_controller.dart';
import 'package:yamt/features/home_widget/data/home_widget_plugin_bridge.dart';
import 'package:yamt/features/home_widget/presentation/controllers/'
    'home_widget_sync_controller.dart';
import 'package:yamt/features/home_widget/presentation/controllers/'
    'home_widget_verbose_mode_controller.dart';

import '../../../../helpers/memory_app_preferences.dart';
import '../../../diary/support/diary_dashboard_test_support.dart';
import '../../support/fake_home_widget_plugin_bridge.dart';

void main() {
  final now = DateTime(2026, 9, 22, 12);
  final normalizedDay = normalizeDiaryDay(now);

  /// Holds a listener on the sync controller, like `lib/app.dart` does.
  ProviderContainer containerWith(
    FakeHomeWidgetPluginBridge bridge,
    FakeDiaryDayDashboardController dashboard,
  ) {
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
        homeWidgetPluginBridgeProvider.overrideWithValue(bridge),
        diaryDayDashboardControllerProvider(normalizedDay)
            .overrideWith(() => dashboard),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      homeWidgetSyncControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    return container;
  }

  test('does not write a snapshot while no diary data is loaded', () async {
    final bridge = FakeHomeWidgetPluginBridge();
    containerWith(
      bridge,
      FakeDiaryDayDashboardController(
        diaryDashboardErrorStateForTest(Exception('boom')),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(bridge.savedSnapshots, isEmpty);
  });

  test('writes the loaded snapshot right away', () async {
    final bridge = FakeHomeWidgetPluginBridge();
    containerWith(
      bridge,
      FakeDiaryDayDashboardController(
        diaryDashboardLoadedStateForTest(selectedDay: normalizedDay),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(bridge.savedSnapshots, hasLength(1));
    expect(bridge.savedSnapshots.single, contains('"verbose":false'));
  });

  test("writes when today's dashboard loads later", () async {
    final bridge = FakeHomeWidgetPluginBridge();
    final dashboard = FakeDiaryDayDashboardController(
      diaryDashboardErrorStateForTest(Exception('boom')),
    );
    containerWith(bridge, dashboard);

    replaceFakeDiaryDashboardState(
      dashboard,
      diaryDashboardLoadedStateForTest(selectedDay: normalizedDay),
    );
    await Future<void>.delayed(Duration.zero);

    expect(bridge.savedSnapshots, hasLength(1));
  });

  test('re-syncs when the verbose preference changes', () async {
    final bridge = FakeHomeWidgetPluginBridge();
    final container = containerWith(
      bridge,
      FakeDiaryDayDashboardController(
        diaryDashboardLoadedStateForTest(selectedDay: normalizedDay),
      ),
    );

    await container
        .read(homeWidgetVerboseModeControllerProvider.notifier)
        .toggle();
    await Future<void>.delayed(Duration.zero);

    expect(bridge.savedSnapshots.last, contains('"verbose":true'));
  });

  test('a failing platform save does not throw', () async {
    final bridge = FakeHomeWidgetPluginBridge(failSave: true);
    containerWith(
      bridge,
      FakeDiaryDayDashboardController(
        diaryDashboardLoadedStateForTest(selectedDay: normalizedDay),
      ),
    );

    await expectLater(Future<void>.delayed(Duration.zero), completes);
    expect(bridge.savedSnapshots, isEmpty);
  });
}
