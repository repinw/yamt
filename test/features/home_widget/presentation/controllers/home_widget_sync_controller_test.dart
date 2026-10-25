import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/theme/app_accent.dart';
import 'package:yamt/core/theme/app_accent_controller.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/diary/presentation/controllers/'
    'diary_day_dashboard_controller.dart';
import 'package:yamt/features/home_widget/data/home_widget_plugin_bridge.dart';
import 'package:yamt/features/home_widget/presentation/controllers/'
    'home_widget_sync_controller.dart';
import 'package:yamt/features/home_widget/presentation/controllers/'
    'home_widget_verbose_mode_controller.dart';

import '../../../../helpers/auth_user_data_key_session.dart';
import '../../../../helpers/memory_app_preferences.dart';
import '../../../diary/support/diary_dashboard_test_support.dart';
import '../../support/fake_home_widget_plugin_bridge.dart';

void main() {
  final now = DateTime(2026, 9, 22, 12);
  final normalizedDay = normalizeLocalDay(now);

  /// Holds a listener on the sync controller, like `lib/app.dart` does.
  ProviderContainer containerWith(
    FakeHomeWidgetPluginBridge bridge,
    FakeDiaryDayDashboardController dashboard, {
    UserDataCipher? Function()? dataCipher,
  }) {
    final container = ProviderContainer(
      overrides: [
        userDataCipherProvider.overrideWith(
          (ref) => dataCipher == null ? testUserDataCipher : dataCipher(),
        ),
        // Read only without a data key: then nobody is signed in.
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(null),
        ),
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

  test('writes zeros over the last numbers once signed out', () async {
    final bridge = FakeHomeWidgetPluginBridge();
    UserDataCipher? dataCipher = testUserDataCipher;
    final container = containerWith(
      bridge,
      FakeDiaryDayDashboardController(
        diaryDashboardLoadedStateForTest(selectedDay: normalizedDay),
      ),
      dataCipher: () => dataCipher,
    );
    await Future<void>.delayed(Duration.zero);
    Map<String, dynamic> last() =>
        jsonDecode(bridge.savedSnapshots.last) as Map<String, dynamic>;
    expect(last()['target_kcal'], isNot(0));

    dataCipher = null;
    container.invalidate(userDataCipherProvider);
    await pumpEventQueue();

    expect(bridge.savedSnapshots, hasLength(2));
    expect(last()['eaten_kcal'], 0);
    expect(last()['target_kcal'], 0);
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

  test('re-syncs when the accent changes', () async {
    final bridge = FakeHomeWidgetPluginBridge();
    final container = containerWith(
      bridge,
      FakeDiaryDayDashboardController(
        diaryDashboardLoadedStateForTest(selectedDay: normalizedDay),
      ),
    );

    await container
        .read(appAccentControllerProvider.notifier)
        .select(AppAccent.violet);
    await Future<void>.delayed(Duration.zero);

    expect(
      bridge.savedSnapshots.last,
      contains('"accent_light":${0xFF6D28D9}'),
    );
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
