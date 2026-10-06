import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

/// A release version such as `3.6.0`. A build number after `+` is ignored,
/// because releases are told apart by their version alone.
@immutable
class AppVersion implements Comparable<AppVersion> {
  /// Creates the version `major.minor.patch`.
  const new(this.major, this.minor, this.patch);

  /// Parses `3.6.0` or `3.6.0+38`. Throws a [FormatException] for anything
  /// else.
  factory parse(String value) {
    final match = _pattern.firstMatch(value.trim());
    if (match == null) {
      throw FormatException('Not an app version.', value);
    }
    return AppVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static final _pattern = RegExp(r'^(\d+)\.(\d+)\.(\d+)(\+\d+)?$');

  /// The major part.
  final int major;

  /// The minor part.
  final int minor;

  /// The patch part.
  final int patch;

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  /// Whether this version is older than [other].
  bool isBefore(AppVersion other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}

/// Reads a version string such as `3.6.0` strictly.
class AppVersionJsonConverter implements JsonConverter<AppVersion, String> {
  /// Creates the converter.
  const new();

  @override
  AppVersion fromJson(String json) => AppVersion.parse(json);

  @override
  String toJson(AppVersion object) => object.toString();
}
