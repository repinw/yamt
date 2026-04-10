import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_version_provider.g.dart';

@riverpod
Future<String> appVersion(Ref ref) async {
  final packageInfo = await PackageInfo.fromPlatform();
  final version = packageInfo.version.trim();
  final buildNumber = packageInfo.buildNumber.trim();

  if (buildNumber.isEmpty || buildNumber == version) {
    return version;
  }

  return '$version+$buildNumber';
}
