import 'package:flutter/material.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';

/// Globaler App-Hintergrund mit dem zentralen Editorial-Verlauf.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppInventoryEditorialSurfaces.backdropGradient(colors),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }
}
