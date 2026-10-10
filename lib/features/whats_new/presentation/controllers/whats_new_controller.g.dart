// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whats_new_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The notice the app shows once per version after an update, or null.
///
/// A fresh install stores the version without a notice, so only users who
/// had the app before see what is new.
// ponytail: one version's notes only; a user who skipped versions sees the
// running version's notes, never merged ones (#496).

@ProviderFor(WhatsNewController)
final whatsNewControllerProvider = WhatsNewControllerProvider._();

/// The notice the app shows once per version after an update, or null.
///
/// A fresh install stores the version without a notice, so only users who
/// had the app before see what is new.
// ponytail: one version's notes only; a user who skipped versions sees the
// running version's notes, never merged ones (#496).
final class WhatsNewControllerProvider
    extends $AsyncNotifierProvider<WhatsNewController, WhatsNewNotice?> {
  /// The notice the app shows once per version after an update, or null.
  ///
  /// A fresh install stores the version without a notice, so only users who
  /// had the app before see what is new.
  // ponytail: one version's notes only; a user who skipped versions sees the
  // running version's notes, never merged ones (#496).
  WhatsNewControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'whatsNewControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$whatsNewControllerHash();

  @$internal
  @override
  WhatsNewController create() => WhatsNewController();
}

String _$whatsNewControllerHash() =>
    r'70226fc3d74c451a64bf76de8c699e1ac82a2e5a';

/// The notice the app shows once per version after an update, or null.
///
/// A fresh install stores the version without a notice, so only users who
/// had the app before see what is new.
// ponytail: one version's notes only; a user who skipped versions sees the
// running version's notes, never merged ones (#496).

abstract class _$WhatsNewController extends $AsyncNotifier<WhatsNewNotice?> {
  FutureOr<WhatsNewNotice?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<WhatsNewNotice?>, WhatsNewNotice?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WhatsNewNotice?>, WhatsNewNotice?>,
              AsyncValue<WhatsNewNotice?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
