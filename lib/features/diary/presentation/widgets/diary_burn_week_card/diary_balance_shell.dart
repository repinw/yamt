import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Outer shell for diary Burn Week card states.
class DiaryBalanceShell extends StatelessWidget {
  /// Creates a Burn Week card shell.
  const DiaryBalanceShell({
    required this.child,
    this.framed = true,
    super.key,
  });

  /// Shell content.
  final Widget child;

  /// Whether to draw the full card frame.
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (!framed) {
      return child;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: child,
      ),
    );
  }
}
