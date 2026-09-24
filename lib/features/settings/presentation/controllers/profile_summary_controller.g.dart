// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_summary_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Combines the user's name, calculator profile, and macro targets for the
/// profile summary card.

@ProviderFor(ProfileSummaryController)
final profileSummaryControllerProvider = ProfileSummaryControllerProvider._();

/// Combines the user's name, calculator profile, and macro targets for the
/// profile summary card.
final class ProfileSummaryControllerProvider
    extends
        $StreamNotifierProvider<ProfileSummaryController, ProfileSummaryState> {
  /// Combines the user's name, calculator profile, and macro targets for the
  /// profile summary card.
  ProfileSummaryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileSummaryControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileSummaryControllerHash();

  @$internal
  @override
  ProfileSummaryController create() => ProfileSummaryController();
}

String _$profileSummaryControllerHash() =>
    r'd1cc325e8fe9e1263463dad695af2551428eda9a';

/// Combines the user's name, calculator profile, and macro targets for the
/// profile summary card.

abstract class _$ProfileSummaryController
    extends $StreamNotifier<ProfileSummaryState> {
  Stream<ProfileSummaryState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ProfileSummaryState>, ProfileSummaryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ProfileSummaryState>, ProfileSummaryState>,
              AsyncValue<ProfileSummaryState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
