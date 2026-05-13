import 'package:flutter/material.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Callback fired when a Burn Week dialog route is created and pushed.
typedef BurnWeekDialogRouteReady =
    void Function(NavigatorState navigator, Route<void> route);

/// Heart actions available from live Burn Week dialog.
enum BurnWeekLiveHeartAction {
  /// Protect today as a heart day.
  add,
}

/// Recovery actions for below-target live Burn Week dialog.
enum BurnWeekLiveBelowZoneAction {
  /// User will recover by eating more.
  eatMore,

  /// User will recover by spending one heart.
  useHeart,
}

/// Actions for an unrecoverable Burn Week limit state.
enum BurnWeekRunLimitAction {
  /// Keep current run alive, but this week cannot earn a star.
  continueRun,

  /// Start a fresh run.
  startNewRun,
}

/// Shows simple close-only Burn Week dialog.
Future<void> showBurnWeekSimpleDialog({
  required BuildContext context,
  required String title,
  required String message,
  BurnWeekDialogRouteReady? onRouteReady,
}) {
  return _showBurnWeekDialog<void>(
    context: context,
    onRouteReady: onRouteReady,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      );
    },
  );
}

/// Shows live Burn Week use-heart dialog.
Future<BurnWeekLiveHeartAction?> showBurnWeekUseHeartDialog({
  required BuildContext context,
  required int dayKcal,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<BurnWeekLiveHeartAction>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.burnWeekUseHeartTitle),
        content: Text(l10n.burnWeekUseHeartMessage(dayKcal)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.burnWeekActionCancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(BurnWeekLiveHeartAction.add);
            },
            child: Text(l10n.burnWeekZoneUseHeartAction),
          ),
        ],
      );
    },
  );
}

/// Shows live Burn Week "too far below" dialog.
Future<bool?> showBurnWeekBelowNeedsHeartDialog(
  BuildContext context, {
  BurnWeekDialogRouteReady? onRouteReady,
}) {
  final l10n = AppLocalizations.of(context)!;
  return _showBurnWeekDialog<bool>(
    context: context,
    onRouteReady: onRouteReady,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.burnWeekZoneBelowNeedsHeartTitle),
        content: Text(l10n.burnWeekZoneBelowNeedsHeartMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.burnWeekActionNo),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.burnWeekZoneUseHeartAction),
          ),
        ],
      );
    },
  );
}

/// Shows live Burn Week recover-below dialog.
Future<BurnWeekLiveBelowZoneAction?> showBurnWeekBelowRecoverDialog({
  required BuildContext context,
  required bool hasHearts,
  BurnWeekDialogRouteReady? onRouteReady,
}) {
  final l10n = AppLocalizations.of(context)!;
  return _showBurnWeekDialog<BurnWeekLiveBelowZoneAction>(
    context: context,
    onRouteReady: onRouteReady,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.burnWeekZoneOutOfSafeZoneTitle),
        content: Text(
          hasHearts
              ? l10n.burnWeekZoneBelowRecoverMessage
              : l10n.burnWeekZoneBelowRecoverNoHeartsMessage,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(BurnWeekLiveBelowZoneAction.eatMore);
            },
            child: Text(l10n.burnWeekZoneEatMoreAction),
          ),
          if (hasHearts)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(BurnWeekLiveBelowZoneAction.useHeart);
              },
              child: Text(l10n.burnWeekZoneUseHeartAction),
            ),
        ],
      );
    },
  );
}

/// Shows live Burn Week "too far above" dialog.
Future<bool?> showBurnWeekAboveNeedsHeartDialog(
  BuildContext context, {
  BurnWeekDialogRouteReady? onRouteReady,
}) {
  final l10n = AppLocalizations.of(context)!;
  return _showBurnWeekDialog<bool>(
    context: context,
    onRouteReady: onRouteReady,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.burnWeekUseHeartTitle),
        content: Text(l10n.burnWeekZoneAboveNeedsHeartMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.burnWeekActionNo),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.burnWeekActionYes),
          ),
        ],
      );
    },
  );
}

/// Shows dialog when the run can no longer finish perfectly.
Future<BurnWeekRunLimitAction?> showBurnWeekRunLimitDialog({
  required BuildContext context,
  required String message,
  BurnWeekDialogRouteReady? onRouteReady,
}) {
  final l10n = AppLocalizations.of(context)!;
  return _showBurnWeekDialog<BurnWeekRunLimitAction>(
    context: context,
    onRouteReady: onRouteReady,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.burnWeekRunLimitTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(BurnWeekRunLimitAction.continueRun);
            },
            child: Text(l10n.burnWeekRunLimitContinueAction),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(BurnWeekRunLimitAction.startNewRun);
            },
            child: Text(l10n.burnWeekRunLimitStartNewAction),
          ),
        ],
      );
    },
  );
}

Future<T?> _showBurnWeekDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  BurnWeekDialogRouteReady? onRouteReady,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final themes = InheritedTheme.capture(
    from: context,
    to: navigator.context,
  );
  final route = DialogRoute<T>(
    context: context,
    builder: builder,
    themes: themes,
    barrierColor:
        DialogTheme.of(context).barrierColor ??
        Theme.of(context).dialogTheme.barrierColor ??
        Colors.black54,
  );
  onRouteReady?.call(navigator, route);
  return navigator.push(route);
}
