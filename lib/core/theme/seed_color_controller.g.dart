// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seed_color_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages persisted seed color selection.

@ProviderFor(SeedColorController)
final seedColorControllerProvider = SeedColorControllerProvider._();

/// Manages persisted seed color selection.
final class SeedColorControllerProvider
    extends $NotifierProvider<SeedColorController, Color> {
  /// Manages persisted seed color selection.
  SeedColorControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seedColorControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seedColorControllerHash();

  @$internal
  @override
  SeedColorController create() => SeedColorController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Color value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Color>(value),
    );
  }
}

String _$seedColorControllerHash() =>
    r'95e792ba13d0c1d1d5776a452887a4e94617fcaa';

/// Manages persisted seed color selection.

abstract class _$SeedColorController extends $Notifier<Color> {
  Color build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Color, Color>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Color, Color>,
              Color,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
