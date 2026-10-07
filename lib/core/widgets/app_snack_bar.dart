import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_snack_bar_view.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Visual tone of an app snack bar.
enum AppSnackBarTone {
  /// An action completed.
  success,

  /// An action failed.
  error,

  /// A neutral notice.
  info,
}

/// Label and callback of a snack bar action other than undo.
typedef AppSnackBarAction = ({String label, VoidCallback onPressed});

/// A snack bar on screen.
final class AppSnackBarController {
  new _(this.closed);

  /// Completes once the snack bar is gone: true when the user tapped its
  /// action, false when it timed out, was swiped away, or was replaced.
  final Future<bool> closed;
}

/// The snack bar shown in each overlay, so a new one replaces it.
final _shown = Expando<_ShownSnackBar>();

/// The overlay found below each app messenger, so the search runs once.
final _overlays = Expando<OverlayState>();

/// Shows the one snack bar design of the app.
///
/// The snack bar sits at the top of the screen, under the status bar, in the
/// root overlay of the app. So it looks the same on every page and never
/// depends on the bottom bar, buttons, or sheets of the page that shows it.
extension AppSnackBar on ScaffoldMessengerState {
  /// Replaces the current snack bar with [message].
  ///
  /// The snack bar hides itself after four seconds, also when it has an
  /// action, unless [staysUntilClosed]; the user can swipe it up. [onUndo]
  /// adds the undo action; when it completes with false, a failure snack bar
  /// follows. [action] adds a different action; pass at most one of them.
  AppSnackBarController showAppSnackBar(
    String message, {
    AppSnackBarTone tone = AppSnackBarTone.success,
    Future<bool> Function()? onUndo,
    AppSnackBarAction? action,
    bool staysUntilClosed = false,
    Key? key,
  }) {
    assert(
      onUndo == null || action == null,
      'Pass either onUndo or action, not both.',
    );
    final AppSnackBarAction? effectiveAction;
    if (onUndo == null) {
      effectiveAction = action;
    } else {
      final l10n = AppLocalizations.of(context)!;
      effectiveAction = (
        label: l10n.commonUndoAction,
        onPressed: () => unawaited(_undo(onUndo, l10n.commonUndoFailed)),
      );
    }

    final overlay = _rootOverlay();
    _shown[overlay]?.close(byAction: false);
    final shown = _ShownSnackBar(overlay);
    shown.entry = OverlayEntry(
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        final (background, foreground, icon) = switch (tone) {
          AppSnackBarTone.success => (
            colors.primaryContainer,
            colors.onPrimaryContainer,
            Icons.check_circle,
          ),
          AppSnackBarTone.error => (
            colors.errorContainer,
            colors.onErrorContainer,
            Icons.error_outline_rounded,
          ),
          AppSnackBarTone.info => (
            colors.primaryContainer,
            colors.onPrimaryContainer,
            Icons.info_outline_rounded,
          ),
        };
        return AppSnackBarView(
          key: key,
          message: message,
          icon: icon,
          background: background,
          foreground: foreground,
          actionLabel: effectiveAction?.label,
          onAction: effectiveAction?.onPressed,
          timeout: staysUntilClosed ? null : AppDurations.snackBar,
          onClosed: shown.close,
          onGone: shown.forget,
        );
      },
    );
    _shown[overlay] = shown;
    overlay.insert(shown.entry);
    return AppSnackBarController._(shown.closed.future);
  }

  /// Removes the current snack bar right away.
  void hideAppSnackBar() {
    _shown[_rootOverlay()]?.close(byAction: false);
  }

  /// The overlay above every route. A messenger inside a route finds it
  /// above itself; the messenger of the app sits above the navigator and
  /// finds it below.
  OverlayState _rootOverlay() {
    final above = Overlay.maybeOf(context, rootOverlay: true);
    if (above != null) {
      return above;
    }
    final cached = _overlays[this];
    if (cached != null && cached.mounted) {
      return cached;
    }
    return _overlays[this] = _overlayBelow();
  }

  OverlayState _overlayBelow() {
    var level = <Element>[context as Element];
    while (level.isNotEmpty) {
      final next = <Element>[];
      for (final element in level) {
        element.visitChildElements(next.add);
      }
      for (final element in next) {
        if (element case StatefulElement(:final OverlayState state)) {
          return state;
        }
      }
      level = next;
    }
    throw StateError('No overlay below the scaffold messenger.');
  }

  Future<void> _undo(
    Future<bool> Function() onUndo,
    String failureMessage,
  ) async {
    if (await onUndo() || !mounted) {
      return;
    }
    showAppSnackBar(failureMessage, tone: AppSnackBarTone.error);
  }
}

final class _ShownSnackBar {
  new(this.overlay);

  final OverlayState overlay;
  late final OverlayEntry entry;
  final closed = Completer<bool>();

  void close({required bool byAction}) {
    if (closed.isCompleted) {
      return;
    }
    closed.complete(byAction);
    forget();
    entry
      ..remove()
      ..dispose();
  }

  /// Completes [closed] without touching the entry, which left the tree with
  /// its overlay.
  void forget() {
    if (!closed.isCompleted) {
      closed.complete(false);
    }
    if (_shown[overlay] == this) {
      _shown[overlay] = null;
    }
  }
}
