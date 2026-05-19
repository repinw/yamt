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
    final isDark = colors.brightness == Brightness.dark;
    final baseSurface = AppEditorialSurfaces.liftedCard(colors);

    if (!framed) {
      return child;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: baseSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppEditorialSurfaces.solidCardBorder(colors)),
        boxShadow: [
          BoxShadow(
            color: AppEditorialSurfaces.ambientShadow(colors),
            blurRadius: isDark ? 22 : 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: child,
      ),
    );
  }
}
