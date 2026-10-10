import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/app_version.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/features/whats_new/data/whats_new_repository.dart';
import 'package:yamt/features/whats_new/domain/whats_new_release.dart';

part 'whats_new_controller.g.dart';

/// The notes of the running version that the "what's new" notice still has
/// to show.
typedef WhatsNewNotice = ({AppVersion version, WhatsNewRelease release});

/// The notice the app shows once per version after an update, or null.
///
/// A fresh install stores the version without a notice, so only users who
/// had the app before see what is new.
// ponytail: one version's notes only; a user who skipped versions sees the
// running version's notes, never merged ones (#496).
@riverpod
class WhatsNewController extends _$WhatsNewController {
  @override
  Future<WhatsNewNotice?> build() async {
    final running = AppVersion.parse(
      await ref.watch(appVersionProvider.future),
    );
    final repository = ref.watch(whatsNewRepositoryProvider);
    final step = whatsNewStep(
      running: running,
      lastSeen: await repository.readLastSeen(),
      usedBefore: await repository.usedBefore(),
    );
    switch (step) {
      case WhatsNewStep.skip:
        return null;
      case WhatsNewStep.markSeen:
        await repository.saveLastSeen(running);
        return null;
      case WhatsNewStep.show:
        final release = await repository.readRelease(running);
        if (release == null ||
            [release.de, release.en].any((notes) => notes.headline == null)) {
          await repository.saveLastSeen(running);
          return null;
        }
        return (version: running, release: release);
    }
  }

  /// Records that the notice of [version] showed, so it does not show again.
  /// A failed save only logs: the notice then shows once more on the next
  /// start.
  Future<void> markShown(AppVersion version) async {
    state = const AsyncData(null);
    final result = await AsyncValue.guard(
      () => ref.read(whatsNewRepositoryProvider).saveLastSeen(version),
    );
    if (!ref.mounted) return;
    if (result case AsyncError(:final error, :final stackTrace)) {
      log(
        'Saving the seen release notes failed.',
        name: 'WhatsNew',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
