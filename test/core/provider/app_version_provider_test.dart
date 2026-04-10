import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yamt/core/provider/app_version_provider.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'YAMT',
      packageName: 'de.yamt.app',
      version: '1.0.0',
      buildNumber: '42',
      buildSignature: '',
    );
  });

  test('returns version and build number when both are present', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final value = await container.read(appVersionProvider.future);

    expect(value, '1.0.0+42');
  });

  test('returns only version when build number is empty', () async {
    PackageInfo.setMockInitialValues(
      appName: 'YAMT',
      packageName: 'de.yamt.app',
      version: '1.0.0',
      buildNumber: '',
      buildSignature: '',
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final value = await container.read(appVersionProvider.future);

    expect(value, '1.0.0');
  });

  test('returns only version when build number equals version', () async {
    PackageInfo.setMockInitialValues(
      appName: 'YAMT',
      packageName: 'de.yamt.app',
      version: '1.0.0',
      buildNumber: '1.0.0',
      buildSignature: '',
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final value = await container.read(appVersionProvider.future);

    expect(value, '1.0.0');
  });
}
