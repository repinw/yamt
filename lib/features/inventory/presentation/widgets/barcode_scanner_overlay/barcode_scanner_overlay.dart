import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'barcode_scanner_overlay/barcode_scanner_guidance_hint_pill.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'barcode_scanner_overlay/barcode_scanner_overlay_painter.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'barcode_scanner_overlay/barcode_scanner_torch_toggle_button.dart';

/// Dimensions for the barcode scanning cutout reticle.
const Size defaultBarcodeScanWindowSize = Size(290, 140);

/// Overlay rendered on top of the live barcode camera stream.
///
/// Features:
/// - Semi-transparent darkened vignette with a clear rounded-rect cutout.
/// - Glowing corner brackets framing the barcode area.
/// - Animated laser sweep line travelling smoothly vertically.
/// - Target lock-on feedback (emerald glow, reticle pulse, checkmark, haptics).
/// - Frosted glass torch (flashlight) toggle button.
/// - Contextual guidance hint below the reticle.
class BarcodeScannerOverlay extends StatefulWidget {
  /// Creates a barcode scanner overlay.
  const BarcodeScannerOverlay({
    super.key,
    this.isLocked = false,
    this.isTorchOn = false,
    this.onToggleTorch,
    this.hintMessage,
    this.windowSize = defaultBarcodeScanWindowSize,
  });

  /// Whether a valid barcode was locked on.
  final bool isLocked;

  /// Whether the camera torch (flashlight) is active.
  final bool isTorchOn;

  /// Callback when the torch button is tapped.
  final VoidCallback? onToggleTorch;

  /// Guidance text displayed below the reticle window.
  final String? hintMessage;

  /// Dimensions of the cutout window.
  final Size windowSize;

  @override
  State<BarcodeScannerOverlay> createState() => _BarcodeScannerOverlayState();
}

class _BarcodeScannerOverlayState extends State<BarcodeScannerOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _laserController;
  late final AnimationController _lockController;
  late final Animation<double> _lockScaleAnimation;
  late final Animation<double> _lockCheckmarkAnimation;
  bool? _animationsDisabled;

  bool get _shouldLoopLaser {
    if (_animationsDisabled ?? false) {
      return false;
    }
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _lockController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _lockScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 60,
      ),
    ]).animate(_lockController);

    _lockCheckmarkAnimation = CurvedAnimation(
      parent: _lockController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void didUpdateWidget(covariant BarcodeScannerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLocked && !oldWidget.isLocked) {
      // Barcode newly locked
      unawaited(HapticFeedback.mediumImpact());
      _laserController.stop();
      unawaited(_lockController.forward(from: 0));
    } else if (!widget.isLocked && oldWidget.isLocked) {
      // Unlocked / resumed scanning
      unawaited(_lockController.reverse());
      if (_shouldLoopLaser) {
        unawaited(_laserController.repeat(reverse: true));
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animationsDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_animationsDisabled == animationsDisabled) {
      return;
    }
    _animationsDisabled = animationsDisabled;
    if (!_shouldLoopLaser) {
      _laserController
        ..stop()
        ..value = 0.5;
      return;
    }
    if (!widget.isLocked && !_laserController.isAnimating) {
      unawaited(_laserController.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    _lockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    const lockColor = Color(0xFF00E676); // Vibrant emerald green

    return Stack(
      fit: StackFit.expand,
      children: [
        // Cutout mask with darkened outer scrim
        AnimatedBuilder(
          animation: Listenable.merge([_laserController, _lockScaleAnimation]),
          builder: (context, _) {
            final activeColor = widget.isLocked ? lockColor : primaryColor;
            return CustomPaint(
              painter: BarcodeScannerOverlayPainter(
                windowSize: widget.windowSize,
                laserProgress: _laserController.value,
                isLocked: widget.isLocked,
                accentColor: activeColor,
                scale: _lockScaleAnimation.value,
              ),
            );
          },
        ),

        // Lock checkmark cue in center of reticle
        if (widget.isLocked)
          Center(
            child: ScaleTransition(
              scale: _lockCheckmarkAnimation,
              child: FadeTransition(
                opacity: _lockCheckmarkAnimation,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: lockColor.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: lockColor.withValues(alpha: 0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.black,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),

        // Torch toggle button (top right)
        if (widget.onToggleTorch != null)
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: BarcodeScannerTorchToggleButton(
                  isTorchOn: widget.isTorchOn,
                  onPressed: widget.onToggleTorch!,
                ),
              ),
            ),
          ),

        // Guidance hint text below the reticle
        if (widget.hintMessage != null)
          Align(
            alignment: const Alignment(0, 0.58),
            child: BarcodeScannerGuidanceHintPill(
              message: widget.hintMessage!,
              isLocked: widget.isLocked,
            ),
          ),
      ],
    );
  }
}
