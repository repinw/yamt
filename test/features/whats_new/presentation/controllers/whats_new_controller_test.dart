import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/app_version.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/features/whats_new/data/whats_new_repository.dart';
import 'package:yamt/features/whats_new/presentation/controllers/whats_new_controller.dart';

import '../../../../helpers/memory_app_preferences.dart';

const _lastSeenKey = 'whats_new_last_seen_version_v1';

/// Preferences that never save, like a device that refuses the write.
class _ReadOnlyPreferences extends MemoryAppPreferences {
  new() : super(completedCalorieGoalOnboardingUserIds: {'user-1'});

  @override
  Future<bool> setString(String key, String value) async => false;
}

/// An asset bundle with one notes file of [text] for 3.7.0.
class _NotesBundle extends CachingAssetBundle {
  new(this.text);

  static const _path = 'assets/whats_new/3.7.0.json';

  final String text;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({
        _path: [
          {'asset': _path},
        ],
      })!;
    }
    if (key == _path) {
      return ByteData.sublistView(utf8.encode(text));
    }
    throw StateError('No asset $key.');
  }
}

ProviderContainer _container(
  AppPreferences preferences, {
  String version = '3.7.0+70',
  AssetBundle? bundle,
}) {
  final container = ProviderContainer(
    // The error itself, not Riverpod's retries.
    retry: (_, _) => null,
    overrides: [
      appVersionProvider.overrideWith((ref) async => version),
      appPreferencesProvider.overrideWithValue(preferences),
      if (bundle != null)
        whatsNewRepositoryProvider.overrideWithValue(
          WhatsNewRepository(bundle, preferences),
        ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// The states of the controller until it settles.
Future<List<AsyncValue<WhatsNewNotice?>>> _states(
  ProviderContainer container,
) async {
  final states = <AsyncValue<WhatsNewNotice?>>[];
  final settled = Completer<void>();
  final subscription = container.listen(whatsNewControllerProvider, (_, next) {
    states.add(next);
    if (!next.isLoading && !settled.isCompleted) settled.complete();
  }, fireImmediately: true);
  addTearDown(subscription.close);
  await settled.future;
  return states;
}

MemoryAppPreferences _usedDevice() =>
    MemoryAppPreferences(completedCalorieGoalOnboardingUserIds: {'user-1'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a device that used the app gets the notes of the new version',
    () async {
      final preferences = _usedDevice();
      final container = _container(preferences);

      final states = await _states(container);

      expect(states, hasLength(2));
      expect(states.first, isA<AsyncLoading<WhatsNewNotice?>>());
      final notice = states.last.requireValue;
      expect(notice?.version, const AppVersion(3, 7, 0));
      expect(notice?.release.de.headline, isNotNull);
      expect(await preferences.getString(_lastSeenKey), isNull);

      await container
          .read(whatsNewControllerProvider.notifier)
          .markShown(notice!.version);
      expect(
        container.read(whatsNewControllerProvider),
        const AsyncData<WhatsNewNotice?>(null),
      );
      expect(await preferences.getString(_lastSeenKey), '3.7.0');
    },
  );

  test('an older seen version shows the notes again', () async {
    final preferences = MemoryAppPreferences(
      initialStrings: {_lastSeenKey: '3.6.0'},
    );

    final states = await _states(_container(preferences));

    expect(states.last.requireValue, isNotNull);
  });

  test('a fresh install stores the version without a notice', () async {
    final preferences = MemoryAppPreferences();

    final states = await _states(_container(preferences));

    expect(states.last, const AsyncData<WhatsNewNotice?>(null));
    expect(await preferences.getString(_lastSeenKey), '3.7.0');
  });

  test('notes seen once do not show again', () async {
    final preferences = MemoryAppPreferences(
      completedCalorieGoalOnboardingUserIds: {'user-1'},
      initialStrings: {_lastSeenKey: '3.7.0'},
    );

    final states = await _states(_container(preferences));

    expect(states.last, const AsyncData<WhatsNewNotice?>(null));
  });

  test('a version without notes shows nothing and is stored', () async {
    final preferences = _usedDevice();

    final states = await _states(_container(preferences, version: '3.7.9'));

    expect(states.last, const AsyncData<WhatsNewNotice?>(null));
    expect(await preferences.getString(_lastSeenKey), '3.7.9');
  });

  test('notes without any point show nothing and are stored', () async {
    final preferences = _usedDevice();
    const empty = '{"new": [], "improved": [], "fixed": []}';
    final bundle = _NotesBundle('{"de": $empty, "en": $empty}');

    final states = await _states(_container(preferences, bundle: bundle));

    expect(states.last, const AsyncData<WhatsNewNotice?>(null));
    expect(await preferences.getString(_lastSeenKey), '3.7.0');
  });

  test('malformed notes are an error and nothing is stored', () async {
    final preferences = _usedDevice();
    final bundle = _NotesBundle('{"de": {"new": []}}');

    final states = await _states(_container(preferences, bundle: bundle));

    expect(states.last, isA<AsyncError<WhatsNewNotice?>>());
    expect(await preferences.getString(_lastSeenKey), isNull);
  });

  test('a failed save after the notice only clears it', () async {
    final container = _container(_ReadOnlyPreferences());
    final notice = (await _states(container)).last.requireValue;

    await container
        .read(whatsNewControllerProvider.notifier)
        .markShown(notice!.version);

    expect(
      container.read(whatsNewControllerProvider),
      const AsyncData<WhatsNewNotice?>(null),
    );
  });
}
