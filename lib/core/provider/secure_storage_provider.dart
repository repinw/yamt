import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage_provider.g.dart';

/// Secure storage for secrets that must stay on the device.
///
/// iOS keeps the values in the iCloud Keychain (`synchronizable`), so a new
/// iPhone of the same Apple account finds them again.
@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(Ref ref) {
  return const FlutterSecureStorage(iOptions: IOSOptions(synchronizable: true));
}
