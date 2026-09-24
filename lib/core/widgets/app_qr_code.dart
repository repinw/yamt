import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// A QR code for [data], drawn dark on a light card in both themes so that
/// every camera can read it.
class AppQrCode extends StatelessWidget {
  /// Creates the QR code.
  const new({required this.data, required this.size, super.key});

  /// The encoded text.
  final String data;

  /// The edge length of the code without its padding.
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: QrImageView(
          data: data,
          size: size,
          padding: EdgeInsets.zero,
          eyeStyle: const QrEyeStyle(color: Colors.black),
          dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
        ),
      ),
    );
  }
}
