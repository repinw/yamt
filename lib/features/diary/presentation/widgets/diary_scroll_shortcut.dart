import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Floating shortcut for jumping between diary header and meals.
class DiaryScrollShortcut extends StatefulWidget {
  /// Creates a diary scroll shortcut.
  const DiaryScrollShortcut({
    required this.showJumpToMeals,
    required this.showScrollToTop,
    required this.onJumpToMeals,
    required this.onScrollToTop,
    super.key,
  });

  /// Whether the jump-to-meals action should be visible.
  final bool showJumpToMeals;

  /// Whether the scroll-to-top action should be visible.
  final bool showScrollToTop;

  /// Called when the user jumps to the meals section.
  final VoidCallback onJumpToMeals;

  /// Called when the user scrolls back to the top.
  final VoidCallback onScrollToTop;

  @override
  State<DiaryScrollShortcut> createState() => _DiaryScrollShortcutState();
}

class _DiaryScrollShortcutState extends State<DiaryScrollShortcut>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late bool _showScrollToTopContent;

  @override
  void initState() {
    super.initState();
    _showScrollToTopContent = widget.showScrollToTop;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    unawaited(_pulseController.repeat(reverse: true));
  }

  @override
  void didUpdateWidget(covariant DiaryScrollShortcut oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showJumpToMeals || widget.showScrollToTop) {
      _showScrollToTopContent = widget.showScrollToTop;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showButton = widget.showJumpToMeals || widget.showScrollToTop;
    final icon = _showScrollToTopContent
        ? Icons.keyboard_arrow_up_rounded
        : Icons.keyboard_arrow_down_rounded;
    final label = _showScrollToTopContent
        ? l10n.diaryScrollToTopAction
        : l10n.diaryJumpToMealsAction;
    final onPressed = _showScrollToTopContent
        ? widget.onScrollToTop
        : widget.onJumpToMeals;

    return AnimatedScale(
      scale: showButton ? 1 : 0.82,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: showButton ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: IgnorePointer(
          ignoring: !showButton,
          child: AnimatedBuilder(
            animation: _pulseController,
            child: _DiaryScrollShortcutButton(
              icon: icon,
              label: label,
              onPressed: onPressed,
            ),
            builder: (context, child) {
              final pulse = Curves.easeInOut.transform(_pulseController.value);
              return Transform.translate(
                offset: Offset(0, _showScrollToTopContent ? 0 : pulse * 2),
                child: Transform.scale(
                  scale: _showScrollToTopContent ? 1 : 1 + pulse * 0.025,
                  child: Opacity(
                    opacity: _showScrollToTopContent ? 1 : 0.82 + pulse * 0.18,
                    child: child,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DiaryScrollShortcutButton extends StatelessWidget {
  const _DiaryScrollShortcutButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          enableFeedback: false,
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(icon, color: colors.primary, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
