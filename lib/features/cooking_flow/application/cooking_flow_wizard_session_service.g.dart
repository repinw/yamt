// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_flow_wizard_session_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides wizard session persistence operations.

@ProviderFor(cookingFlowWizardSessionService)
final cookingFlowWizardSessionServiceProvider =
    CookingFlowWizardSessionServiceProvider._();

/// Provides wizard session persistence operations.

final class CookingFlowWizardSessionServiceProvider
    extends
        $FunctionalProvider<
          CookingFlowWizardSessionService,
          CookingFlowWizardSessionService,
          CookingFlowWizardSessionService
        >
    with $Provider<CookingFlowWizardSessionService> {
  /// Provides wizard session persistence operations.
  CookingFlowWizardSessionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookingFlowWizardSessionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookingFlowWizardSessionServiceHash();

  @$internal
  @override
  $ProviderElement<CookingFlowWizardSessionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CookingFlowWizardSessionService create(Ref ref) {
    return cookingFlowWizardSessionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CookingFlowWizardSessionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CookingFlowWizardSessionService>(
        value,
      ),
    );
  }
}

String _$cookingFlowWizardSessionServiceHash() =>
    r'815a851b1f09b4cdfda8257721c0040713dda91f';
