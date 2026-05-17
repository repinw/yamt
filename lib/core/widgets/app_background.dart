import 'package:flutter/material.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';

/// Global app background with central editorial gradient.
class AppBackground extends StatelessWidget {
  /// Creates app background wrapper.
  const AppBackground({super.key, this.child});

  /// Content placed above the shared background.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppEditorialSurfaces.backdropGradient(colors),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }
}
