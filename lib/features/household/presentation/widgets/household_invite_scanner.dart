import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/widgets/barcode_scanner/barcode_scanner_overlay.dart';
import 'package:yamt/features/household/domain/household_invite.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the camera and returns the first household invite QR code it reads,
/// or `null` when the user closes the scanner.
Future<HouseholdInvite?> openHouseholdInviteScanner(BuildContext context) {
  return showModalBottomSheet<HouseholdInvite>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (_) => const FractionallySizedBox(
      heightFactor: 1,
      child: _HouseholdInviteScannerPage(),
    ),
  );
}

class _HouseholdInviteScannerPage extends StatefulWidget {
  const new();

  @override
  State<_HouseholdInviteScannerPage> createState() =>
      _HouseholdInviteScannerPageState();
}

class _HouseholdInviteScannerPageState
    extends State<_HouseholdInviteScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isTorchOn = false;
  bool _isDone = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.householdJoinScanQr)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          BarcodeScannerOverlay(
            isLocked: _isDone,
            isTorchOn: _isTorchOn,
            onToggleTorch: _toggleTorch,
            windowSize: const Size.square(AppSizes.qrScanWindow),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (mounted) {
      setState(() => _isTorchOn = !_isTorchOn);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isDone) {
      return;
    }
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      final invite = rawValue == null
          ? null
          : HouseholdInvite.tryParse(rawValue);
      if (invite != null) {
        setState(() => _isDone = true);
        Navigator.of(context).pop(invite);
        return;
      }
    }
  }
}
