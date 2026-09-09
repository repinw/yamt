import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

/// Circular button to toggle the camera torch (flashlight).
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
        child: Material(
          color: isTorchOn ? Colors.amber : Colors.black54,
          shape: const CircleBorder(),
          child: AppInkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Icon(
                isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: isTorchOn ? Colors.black : Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
