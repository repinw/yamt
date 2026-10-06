import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:yamt/core/domain/app_version.dart';

part 'app_update_status.g.dart';

/// The versions that the release sets in `config/app_version`.
@immutable
@JsonSerializable(
  fieldRename: FieldRename.snake,
  createToJson: false,
  checked: true,
)
@AppVersionJsonConverter()
class AppVersionConfig {
  /// Creates the config.
  const new({required this.minVersion, required this.latestVersion});

  /// Reads the stored document. Throws a [CheckedFromJsonException] when a
  /// field is missing or not a version.
  factory fromJson(Map<String, dynamic> json) =>
      _$AppVersionConfigFromJson(json);

  /// Older apps must update before they open.
  final AppVersion minVersion;

  /// The newest version in both stores.
  final AppVersion latestVersion;
}

/// Whether this app may open, and whether a newer version exists.
@immutable
sealed class AppUpdateStatus {
  const new();

  /// Compares the [current] app with [config]. Without a config (offline on
  /// a first start, or before the first release sets it), the app opens.
  factory of(AppVersion current, AppVersionConfig? config) {
    if (config == null) {
      return const AppUpToDate();
    }
    if (current.isBefore(config.minVersion)) {
      return const AppUpdateRequired();
    }
    if (current.isBefore(config.latestVersion)) {
      return AppUpdateAvailable(config.latestVersion);
    }
    return const AppUpToDate();
  }
}

/// The app is the newest version, or no config is known.
final class AppUpToDate extends AppUpdateStatus {
  /// Creates the status.
  const new();

  @override
  bool operator ==(Object other) => other is AppUpToDate;

  @override
  int get hashCode => (AppUpToDate).hashCode;
}

/// A newer version exists; the app still opens.
final class AppUpdateAvailable extends AppUpdateStatus {
  /// Creates the status for [latestVersion].
  const new(this.latestVersion);

  /// The newest version in both stores.
  final AppVersion latestVersion;

  @override
  bool operator ==(Object other) =>
      other is AppUpdateAvailable && other.latestVersion == latestVersion;

  @override
  int get hashCode => latestVersion.hashCode;
}

/// The app is older than the minimum version and must not open.
final class AppUpdateRequired extends AppUpdateStatus {
  /// Creates the status.
  const new();

  @override
  bool operator ==(Object other) => other is AppUpdateRequired;

  @override
  int get hashCode => (AppUpdateRequired).hashCode;
}
