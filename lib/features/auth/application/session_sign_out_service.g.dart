// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_sign_out_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the sign-out service.

@ProviderFor(sessionSignOutService)
final sessionSignOutServiceProvider = SessionSignOutServiceProvider._();

/// Provides the sign-out service.

final class SessionSignOutServiceProvider
    extends
        $FunctionalProvider<
          SessionSignOutService,
          SessionSignOutService,
          SessionSignOutService
        >
    with $Provider<SessionSignOutService> {
  /// Provides the sign-out service.
  SessionSignOutServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionSignOutServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionSignOutServiceHash();

  @$internal
  @override
  $ProviderElement<SessionSignOutService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SessionSignOutService create(Ref ref) {
    return sessionSignOutService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionSignOutService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionSignOutService>(value),
    );
  }
}

String _$sessionSignOutServiceHash() =>
    r'1581ffa223eb07b3b0cf86b85ef19350b85f078d';
