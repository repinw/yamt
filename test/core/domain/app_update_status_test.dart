import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/core/domain/app_update_status.dart';
import 'package:yamt/core/domain/app_version.dart';

void main() {
  group('AppVersion', () {
    test('parses a version and ignores the build number', () {
      expect(AppVersion.parse('3.6.0+38'), const AppVersion(3, 6, 0));
      expect(AppVersion.parse('3.6.0').toString(), '3.6.0');
    });

    test('rejects anything else', () {
      for (final value in ['3.6', '3.6.0-beta', 'v3.6.0', '']) {
        expect(() => AppVersion.parse(value), throwsFormatException);
      }
    });

    test('compares part by part, not as text', () {
      expect(
        AppVersion.parse('3.10.0').isBefore(AppVersion.parse('3.9.9')),
        isFalse,
      );
      expect(
        AppVersion.parse('3.5.9').isBefore(AppVersion.parse('3.6.0')),
        isTrue,
      );
      expect(
        AppVersion.parse('3.6.0').isBefore(AppVersion.parse('3.6.0')),
        isFalse,
      );
    });
  });

  group('AppUpdateStatus.of', () {
    final config = AppVersionConfig(
      minVersion: AppVersion.parse('3.5.0'),
      latestVersion: AppVersion.parse('3.7.0'),
    );

    test('opens without a config', () {
      expect(
        AppUpdateStatus.of(AppVersion.parse('1.0.0'), null),
        isA<AppUpToDate>(),
      );
    });

    test('requires an update below the minimum version', () {
      expect(
        AppUpdateStatus.of(AppVersion.parse('3.4.9'), config),
        isA<AppUpdateRequired>(),
      );
    });

    test('names the latest version between minimum and latest', () {
      final status = AppUpdateStatus.of(AppVersion.parse('3.5.0'), config);
      expect(
        status,
        isA<AppUpdateAvailable>().having(
          (status) => status.latestVersion,
          'latestVersion',
          AppVersion.parse('3.7.0'),
        ),
      );
    });

    test('is up to date at the latest version', () {
      expect(
        AppUpdateStatus.of(AppVersion.parse('3.7.0'), config),
        isA<AppUpToDate>(),
      );
    });
  });

  group('AppVersionConfig.fromJson', () {
    test('reads both versions', () {
      final config = AppVersionConfig.fromJson(const {
        'min_version': '3.5.0',
        'latest_version': '3.6.0',
      });
      expect(config.minVersion, AppVersion.parse('3.5.0'));
      expect(config.latestVersion, AppVersion.parse('3.6.0'));
    });

    test('throws when a field is missing or no version', () {
      expect(
        () => AppVersionConfig.fromJson(const {'latest_version': '3.6.0'}),
        throwsA(isA<CheckedFromJsonException>()),
      );
      expect(
        () => AppVersionConfig.fromJson(const {
          'min_version': '3.5',
          'latest_version': '3.6.0',
        }),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });
  });
}
