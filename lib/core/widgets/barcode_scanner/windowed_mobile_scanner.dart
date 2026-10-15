import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:yamt/core/widgets/barcode_scanner/barcode_scanner_overlay.dart';
import 'package:yamt/core/widgets/barcode_scanner/barcode_scanner_overlay_painter.dart';

/// The camera picture that reads barcodes only around the reticle of a
/// [BarcodeScannerOverlay] of the same size and [windowSize], so a code
/// elsewhere in the picture is ignored.
class WindowedMobileScanner extends StatelessWidget {
  /// Creates the scanner for [controller].
  const new({
    required this.controller,
    required this.onDetect,
    this.windowSize = defaultBarcodeScanWindowSize,
    super.key,
  });

  /// The camera controller.
  final MobileScannerController controller;

  /// Takes the codes read around the reticle.
  final void Function(BarcodeCapture capture) onDetect;

  /// The reticle size, as the overlay draws it.
  final Size windowSize;

  /// How far the read area reaches past the drawn frame. Android takes a
  /// code only when all its corners are inside, so a code held a bit larger
  /// than the frame must still fit.
  static const margin = 48.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounds = Offset.zero & constraints.biggest;
        return MobileScanner(
          controller: controller,
          onDetect: onDetect,
          // Without a bounded size there is no reticle to read in.
          scanWindow:
              constraints.hasBoundedWidth && constraints.hasBoundedHeight
              ? barcodeReticleRect(
                  bounds.size,
                  windowSize,
                ).inflate(margin).intersect(bounds)
              : null,
        );
      },
    );
  }
}
