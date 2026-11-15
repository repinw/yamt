import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_controller.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_timer_controller.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_timer_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_weigh_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Runs the actions of the cooking page and says when one fails.
///
/// The flows read the controller from the page's container, never through
/// a `WidgetRef`, so an action and its undo may finish after the page
/// closed.
abstract final class KochmodusActionFlow {
  const new _();

  /// Key of the snack bar after "Verwerfen".
  static const discardedKey = ValueKey<String>('kochmodus-discarded');

  /// Key of the snack bar after a line was removed on "Portion".
  static const lineRemovedKey = ValueKey<String>('kochmodus-line-removed');

  /// Runs [action] on the controller of [target]. When it fails, an error
  /// snack bar says [failed], else that the cooking could not be saved;
  /// not when the run ended meanwhile, because the page says that. Returns
  /// whether it worked.
  static Future<bool> run(
    BuildContext context,
    KochmodusTarget target,
    Future<bool> Function(KochmodusController controller) action, {
    String? failed,
  }) async =>
      await result(
        context,
        target,
        (controller) async => await action(controller) ? true : null,
        failed: failed,
      ) ??
      false;

  /// Like [run] for an action that returns a value, `null` when it failed.
  static Future<T?> result<T extends Object>(
    BuildContext context,
    KochmodusTarget target,
    Future<T?> Function(KochmodusController controller) action, {
    String? failed,
  }) async {
    final message = failed ?? AppLocalizations.of(context)!.kochmodusSaveFailed;
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    final provider = kochmodusControllerProvider(target);
    final value = await action(container.read(provider.notifier));
    if (value != null || !messenger.mounted) return value;
    final ended =
        container.read(provider.exists) &&
        (container.read(provider).value?.ended ?? false);
    if (!ended) {
      messenger.showAppSnackBar(message, tone: AppSnackBarTone.error);
    }
    return null;
  }

  /// The first "Timer N" that none of [view]'s running timers is called, so
  /// a new timer never shares the name of one that counts.
  static String freeTimerName(AppLocalizations l10n, KochmodusView view) {
    final names = {for (final timer in view.timers) timer.label};
    var number = 1;
    while (names.contains(l10n.kochmodusTimerName(number))) {
      number++;
    }
    return l10n.kochmodusTimerName(number);
  }

  /// Starts the timer [name]: at once with the only one of [choices], else
  /// with the one the cook picks in the sheet.
  static Future<void> startTimer(
    BuildContext context,
    KochmodusTarget target, {
    required String name,
    required List<Duration> choices,
  }) async {
    final duration = choices.length == 1
        ? choices.single
        : await KochmodusTimerSheet.show(context, name: name, choices: choices);
    if (duration == null || !context.mounted) return;
    final container = ProviderScope.containerOf(context, listen: false);
    await run(
      context,
      target,
      (_) => container
          .read(kochmodusTimerControllerProvider(target).notifier)
          .startTimer(name, duration),
    );
  }

  /// "Wiegen" or "Ändern" of [line]: the keypad with the recipe's estimate
  /// or the weight so far as hint, then stores the grams.
  static Future<void> weigh(
    BuildContext context,
    KochmodusTarget target,
    KochmodusLineView line,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final food = line.pictureItem?.name;
    final (hint, sub) = switch (line.weight) {
      CookWeightEstimated(:final grams) => (
        grams,
        food == null
            ? l10n.kochmodusWeighRecipeEstimate(grams)
            : l10n.kochmodusCookLineSub(
                food,
                l10n.kochmodusWeighRecipeEstimate(grams),
              ),
      ),
      CookWeightWeighed(:final grams) => (grams, food),
      _ => (null, food),
    };
    final grams = await KochmodusWeighSheet.show(
      context,
      title: line.text,
      sub: sub,
      hint: hint,
    );
    if (grams == null || !context.mounted) return;
    await run(
      context,
      target,
      (controller) => controller.weigh(line.id, grams),
    );
  }

  /// Removes [line] on "Portion" without asking and offers "Rückgängig",
  /// which brings it back as it was.
  static Future<void> removeLine(
    BuildContext context,
    KochmodusTarget target,
    KochmodusLineView line,
  ) async {
    final message = AppLocalizations.of(context)!
        .kochmodusLineRemoved(line.text);
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    final removed = await result(
      context,
      target,
      (controller) => controller.removeFromPortion(line.id),
    );
    if (removed == null || !messenger.mounted) return;
    messenger.showAppSnackBar(
      message,
      key: lineRemovedKey,
      onUndo: () => container
          .read(kochmodusControllerProvider(target).notifier)
          .undoRemove(removed),
    );
  }

  /// Discards the run of [target] without asking ("Verwerfen"), closes the
  /// page of [context] and offers "Rückgängig", which stores the run again.
  static Future<void> discard(
    BuildContext context,
    KochmodusTarget target,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    final run = await result(
      context,
      target,
      (controller) => controller.discard(),
      failed: l10n.kochmodusDiscardFailed,
    );
    if (run == null) return;
    if (context.mounted) context.pop();
    if (!messenger.mounted) return;
    messenger.showAppSnackBar(
      l10n.kochmodusDiscarded,
      key: discardedKey,
      // Read again: the page's controller is gone by then.
      onUndo: () => container
          .read(kochmodusControllerProvider(target).notifier)
          .restore(run),
    );
  }
}
