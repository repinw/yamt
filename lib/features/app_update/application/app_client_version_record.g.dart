// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_client_version_record.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Saves the app version of this device whenever a user signs in or the app
/// starts. `lib/app.dart` keeps it alive for the app's lifetime. A failed
/// write only logs: the next start tries again.

@ProviderFor(appClientVersionRecord)
final appClientVersionRecordProvider = AppClientVersionRecordProvider._();

/// Saves the app version of this device whenever a user signs in or the app
/// starts. `lib/app.dart` keeps it alive for the app's lifetime. A failed
/// write only logs: the next start tries again.

final class AppClientVersionRecordProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Saves the app version of this device whenever a user signs in or the app
  /// starts. `lib/app.dart` keeps it alive for the app's lifetime. A failed
  /// write only logs: the next start tries again.
  AppClientVersionRecordProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appClientVersionRecordProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appClientVersionRecordHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return appClientVersionRecord(ref);
  }
}

String _$appClientVersionRecordHash() =>
    r'189e5a690f79af8034560a13edd89dbe833399cb';
