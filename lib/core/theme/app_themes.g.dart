// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_themes.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The themes of the design, accent, own colors and macro coloring the user
/// picked. "Individuell" shows the own colors whatever the system brightness
/// is.

@ProviderFor(appThemes)
final appThemesProvider = AppThemesProvider._();

/// The themes of the design, accent, own colors and macro coloring the user
/// picked. "Individuell" shows the own colors whatever the system brightness
/// is.

final class AppThemesProvider
    extends $FunctionalProvider<AppThemes, AppThemes, AppThemes>
    with $Provider<AppThemes> {
  /// The themes of the design, accent, own colors and macro coloring the user
  /// picked. "Individuell" shows the own colors whatever the system brightness
  /// is.
  AppThemesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appThemesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appThemesHash();

  @$internal
  @override
  $ProviderElement<AppThemes> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppThemes create(Ref ref) {
    return appThemes(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppThemes value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppThemes>(value),
    );
  }
}

String _$appThemesHash() => r'f7b621d275960c34995f6ebd6f92d2827a33b11c';
