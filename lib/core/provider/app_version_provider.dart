import 'package:meta/meta.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_version_provider.g.dart';

typedef PackageInfoLoader = Future<PackageInfo> Function();

Future<PackageInfo> _defaultPackageInfoLoader() {
  return PackageInfo.fromPlatform();
}

@visibleForTesting
PackageInfoLoader debugPackageInfoLoader = _defaultPackageInfoLoader;

@visibleForTesting
void resetAppVersionProviderDebugHooks() {
  debugPackageInfoLoader = _defaultPackageInfoLoader;
}

@riverpod
Future<String> appVersion(Ref ref) async {
  final packageInfo = await debugPackageInfoLoader();
  final version = packageInfo.version.trim();
  final buildNumber = packageInfo.buildNumber.trim();

  if (buildNumber.isEmpty || buildNumber == version) {
    return version;
  }

  return '$version+$buildNumber';
}
