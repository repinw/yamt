import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Frosted glass circular button to toggle the camera torch (flashlight).
class BarcodeScannerTorchToggleButton extends StatelessWidget {
  /// Creates a torch toggle button.
  const BarcodeScannerTorchToggleButton({
    required this.isTorchOn,
    required this.onPressed,
    super.key,
  });

  /// Whether the torch is currently enabled.
  final bool isTorchOn;

  /// Callback when the button is tapped.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = isTorchOn
        ? 'Taschenlampe ausschalten'
        : 'Taschenlampe einschalten';
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: isTorchOn
                ? Colors.amber.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.4),
            shape: CircleBorder(
              side: BorderSide(
                color: isTorchOn
                    ? Colors.amber.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.2),
                width: 1.2,
              ),
            ),
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Icon(
                  isTorchOn
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  color: isTorchOn ? Colors.amberAccent : Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
