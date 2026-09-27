// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_training_edit_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drafts the training days of the current run, shows what they change, and
/// saves them.

@ProviderFor(ProfileTrainingEditController)
final profileTrainingEditControllerProvider =
    ProfileTrainingEditControllerProvider._();

/// Drafts the training days of the current run, shows what they change, and
/// saves them.
final class ProfileTrainingEditControllerProvider
    extends
        $NotifierProvider<
          ProfileTrainingEditController,
          ProfileTrainingEditState
        > {
  /// Drafts the training days of the current run, shows what they change, and
  /// saves them.
  ProfileTrainingEditControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileTrainingEditControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileTrainingEditControllerHash();

  @$internal
  @override
  ProfileTrainingEditController create() => ProfileTrainingEditController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileTrainingEditState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileTrainingEditState>(value),
    );
  }
}

String _$profileTrainingEditControllerHash() =>
    r'513330a86b9a1a00933e12d0252b8c0cc65600f5';

/// Drafts the training days of the current run, shows what they change, and
/// saves them.

abstract class _$ProfileTrainingEditController
    extends $Notifier<ProfileTrainingEditState> {
  ProfileTrainingEditState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<ProfileTrainingEditState, ProfileTrainingEditState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfileTrainingEditState, ProfileTrainingEditState>,
              ProfileTrainingEditState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
