import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/app_version_config_repository.dart';
import 'package:yamt/core/domain/app_update_status.dart';
import 'package:yamt/core/domain/app_version.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/app_update/presentation/controllers/app_update_hint_controller.dart';

import '../../../../helpers/memory_app_preferences.dart';

ProviderContainer _container(
  AppUpdateStatus status,
  MemoryAppPreferences preferences,
) {
  final container = ProviderContainer(
    overrides: [
      appUpdateStatusProvider.overrideWith(
        (ref) => Stream.fromFuture(Future.value(status)),
      ),
      appPreferencesProvider.overrideWithValue(preferences),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<AppVersion?> _hint(ProviderContainer container) async {
  container.listen(appUpdateHintControllerProvider, (_, _) {});
  await container.read(appUpdateStatusProvider.future);
  return await container.read(appUpdateHintControllerProvider.future);
}

void main() {
  final latest = AppVersion.parse('3.6.0');

  test('names a newer version that the hint has not shown', () async {
    final container = _container(
      AppUpdateAvailable(latest),
      MemoryAppPreferences(),
    );

    expect(await _hint(container), latest);
  });

  test('shows nothing while the app is up to date', () async {
    final container = _container(const AppUpToDate(), MemoryAppPreferences());

    expect(await _hint(container), isNull);
  });

  test('shows a version once', () async {
    final preferences = MemoryAppPreferences();
    final container = _container(AppUpdateAvailable(latest), preferences);
    expect(await _hint(container), latest);

    await container
        .read(appUpdateHintControllerProvider.notifier)
        .markShown(latest);

    expect(container.read(appUpdateHintControllerProvider).value, isNull);
    final restarted = _container(AppUpdateAvailable(latest), preferences);
    expect(await _hint(restarted), isNull);
  });
}
