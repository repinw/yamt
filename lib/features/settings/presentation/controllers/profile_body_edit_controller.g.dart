// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_body_edit_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Checks a draft of one body fact, shows what it changes, and saves it.

@ProviderFor(ProfileBodyEditController)
final profileBodyEditControllerProvider = ProfileBodyEditControllerProvider._();

/// Checks a draft of one body fact, shows what it changes, and saves it.
final class ProfileBodyEditControllerProvider
    extends $NotifierProvider<ProfileBodyEditController, ProfileBodyEditState> {
  /// Checks a draft of one body fact, shows what it changes, and saves it.
  ProfileBodyEditControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileBodyEditControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileBodyEditControllerHash();

  @$internal
  @override
  ProfileBodyEditController create() => ProfileBodyEditController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileBodyEditState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileBodyEditState>(value),
    );
  }
}

String _$profileBodyEditControllerHash() =>
    r'00f15d74d1e420c64bcf07921304c45357f2f3b9';

/// Checks a draft of one body fact, shows what it changes, and saves it.

abstract class _$ProfileBodyEditController
    extends $Notifier<ProfileBodyEditState> {
  ProfileBodyEditState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProfileBodyEditState, ProfileBodyEditState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfileBodyEditState, ProfileBodyEditState>,
              ProfileBodyEditState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
