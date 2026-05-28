import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';

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
      decoration: AppQuietSurfaces.cardDecoration(colors),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: child,
      ),
    );
  }
}
