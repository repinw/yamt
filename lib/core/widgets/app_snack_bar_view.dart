import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';

/// The snack bar card: slides in from the top, hides itself after [timeout]
/// (with a screen reader on, only when it has no action), and closes on a
/// swipe up or on its action.
class AppSnackBarView extends StatefulWidget {
  /// Creates the card.
  const new({
    required this.message,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.actionLabel,
    required this.onAction,
    required this.timeout,
    required this.onClosed,
    required this.onGone,
    super.key,
  });

  /// The text.
  final String message;

  /// The icon before the text.
  final IconData icon;

  /// The card color.
  final Color background;

  /// The color of the text, the icon, and the action.
  final Color foreground;

  /// Label of the action beside the text, if any.
  final String? actionLabel;

  /// Called when the user taps the action.
  final VoidCallback? onAction;

  /// How long the card stays; null keeps it until the user closes it.
  final Duration? timeout;

  /// Called when the card closes; true when its action closed it.
  final void Function({required bool byAction}) onClosed;

  /// Called when the card leaves the tree without closing, for example
  /// with its overlay.
  final VoidCallback onGone;

  @override
  State<AppSnackBarView> createState() => _AppSnackBarViewState();
}

class _AppSnackBarViewState extends State<AppSnackBarView>
    with SingleTickerProviderStateMixin {
  late final _slide = AnimationController(
    vsync: this,
    duration: AppGraphit.stateChange,
  );
  Timer? _timeout;
  var _closing = false;

  @override
  void initState() {
    super.initState();
    final timeout = widget.timeout;
    // The time on screen starts once the card is fully in.
    unawaited(
      _slide.forward().then((_) {
        if (timeout != null && mounted) {
          _timeout = Timer(timeout, _onTimeout);
        }
      }),
    );
  }

  void _onTimeout() {
    // Like the Material snack bar: with a screen reader on, a card with an
    // action stays until the user reaches and uses or closes it.
    if (widget.actionLabel != null &&
        MediaQuery.accessibleNavigationOf(context)) {
      return;
    }
    unawaited(_hide());
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _slide.dispose();
    if (!_closing) {
      widget.onGone();
    }
    super.dispose();
  }

  Future<void> _hide() async {
    if (_closing) {
      return;
    }
    _closing = true;
    await _slide.reverse();
    widget.onClosed(byAction: false);
  }

  void _close({required bool byAction}) {
    if (_closing) {
      return;
    }
    _closing = true;
    widget.onClosed(byAction: byAction);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = widget.foreground;
    final actionLabel = widget.actionLabel;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: AppInsets.snackBarMargin,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, AppSizes.snackBarHiddenSlide),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: _slide, curve: Curves.easeOut)),
            child: Dismissible(
              key: const ValueKey<String>('app-snack-bar'),
              direction: DismissDirection.up,
              onDismissed: (_) => _close(byAction: false),
              child: Semantics(
                container: true,
                liveRegion: true,
                onDismiss: () => _close(byAction: false),
                child: Material(
                  color: widget.background,
                  elevation: AppSizes.snackBarElevation,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xs,
                      AppSpacing.xs,
                      AppSpacing.xs,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              widget.icon,
                              color: foreground,
                              size: AppSizes.snackBarIcon,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xs,
                                ),
                                child: Text(
                                  widget.message,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: foreground,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            if (actionLabel != null)
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: foreground,
                                ),
                                onPressed: () {
                                  _close(byAction: true);
                                  widget.onAction?.call();
                                },
                                child: Text(actionLabel),
                              ),
                          ],
                        ),
                        // Shows that the card can be swiped up.
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: foreground.withValues(
                              alpha: AppOpacities.snackBarHandle,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: const SizedBox(
                            width: AppSizes.snackBarHandleWidth,
                            height: AppSizes.snackBarHandleHeight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
