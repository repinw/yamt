// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secondary_auth_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Secondary auth client provider.

@ProviderFor(secondaryAuthClient)
final secondaryAuthClientProvider = SecondaryAuthClientProvider._();

/// Secondary auth client provider.

final class SecondaryAuthClientProvider
    extends
        $FunctionalProvider<
          SecondaryAuthClient,
          SecondaryAuthClient,
          SecondaryAuthClient
        >
    with $Provider<SecondaryAuthClient> {
  /// Secondary auth client provider.
  SecondaryAuthClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'secondaryAuthClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$secondaryAuthClientHash();

  @$internal
  @override
  $ProviderElement<SecondaryAuthClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SecondaryAuthClient create(Ref ref) {
    return secondaryAuthClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SecondaryAuthClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SecondaryAuthClient>(value),
    );
  }
}

String _$secondaryAuthClientHash() =>
    r'8ecfce9b38fd112781068553f10e45f381588e66';
