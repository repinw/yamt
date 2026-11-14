// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_suggestion_queue_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The suggestions the user pushed back, as keys in the order of pushing,
/// saved on the device.

@ProviderFor(ShoppingSuggestionQueueController)
final shoppingSuggestionQueueControllerProvider =
    ShoppingSuggestionQueueControllerProvider._();

/// The suggestions the user pushed back, as keys in the order of pushing,
/// saved on the device.
final class ShoppingSuggestionQueueControllerProvider
    extends $NotifierProvider<ShoppingSuggestionQueueController, List<String>> {
  /// The suggestions the user pushed back, as keys in the order of pushing,
  /// saved on the device.
  ShoppingSuggestionQueueControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingSuggestionQueueControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$shoppingSuggestionQueueControllerHash();

  @$internal
  @override
  ShoppingSuggestionQueueController create() =>
      ShoppingSuggestionQueueController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$shoppingSuggestionQueueControllerHash() =>
    r'8d09d4e6fc5a674bfa7b95fb5c15b6cbcd38b80b';

/// The suggestions the user pushed back, as keys in the order of pushing,
/// saved on the device.

abstract class _$ShoppingSuggestionQueueController
    extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
