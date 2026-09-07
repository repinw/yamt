import 'dart:async' show unawaited;
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'barcode_scanner_overlay/barcode_scanner_overlay.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_lookup_candidate.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_scanner_page/'
    'inventory_barcode_candidate_resolver.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_scanner_page/'
    'inventory_barcode_scanner_resolving_indicator.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_scanner_page/'
    'inventory_barcode_scanner_support.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _scannerLogName = 'InventoryBarcodeScannerView';

/// Defines inventory barcode scanner view.
class InventoryBarcodeScannerView extends ConsumerStatefulWidget {
  /// The inventory barcode scanner view.
  const InventoryBarcodeScannerView({
    super.key,
    this.onBarcodeScanned,
    this.onProductSelected,
    this.onProductNotFound,
    this.onCreateManualProduct,
    this.showActionButtons = true,
    this.eatOnly = false,
  }) : assert(
         onBarcodeScanned != null || onProductSelected != null,
         'Either onBarcodeScanned or onProductSelected must be provided.',
       );

  /// Direct raw barcode scanned callback.
  final InventoryBarcodeScanCallback? onBarcodeScanned;

  /// The on product selected callback.
  final InventoryBarcodeProductSelectionCallback? onProductSelected;

  /// The on product not found callback.
  final InventoryBarcodeNotFoundCallback? onProductNotFound;

  /// The on create manual product callback.
  final InventoryBarcodeManualProductCallback? onCreateManualProduct;

  /// Whether candidate rows show explicit action buttons.
  final bool showActionButtons;

  /// Whether only eat actions should be shown.
  final bool eatOnly;

  @override
  ConsumerState<InventoryBarcodeScannerView> createState() =>
      _InventoryBarcodeScannerViewState();
}

class _InventoryBarcodeScannerViewState
    extends ConsumerState<InventoryBarcodeScannerView> {
  final MobileScannerController _scannerController = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.itf14,
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
    detectionTimeoutMs: 1000,
  );
  bool _isResolving = false;
  bool _isLocked = false;
  bool _isTorchOn = false;
  DateTime? _lastScannedAt;
  String? _lastScannedBarcode;

  @override
  void dispose() {
    unawaited(_scannerController.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!isMobileBarcodeScanSupported()) {
      return Center(
        child: Padding(
          padding: AppInsets.page,
          child: Text(
            l10n.inventoryBarcodeScanUnsupported,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        MobileScanner(controller: _scannerController, onDetect: _onDetect),
        BarcodeScannerOverlay(
          isLocked: _isLocked,
          isTorchOn: _isTorchOn,
          onToggleTorch: _toggleTorch,
          hintMessage: l10n.inventoryManualAddHint,
        ),
        if (_isResolving) const InventoryBarcodeScannerResolvingIndicator(),
      ],
    );
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      if (mounted) {
        setState(() {
          _isTorchOn = !_isTorchOn;
        });
      }
    } on Object catch (error, stackTrace) {
      log(
        'Toggling scanner torch failed.',
        name: _scannerLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!mounted || _isResolving || _isLocked) {
      return;
    }

    final barcode = extractValidBarcodeFromCapture(capture);
    if (barcode == null ||
        isBarcodeScanThrottled(
          barcode: barcode,
          lastScannedBarcode: _lastScannedBarcode,
          lastScannedAt: _lastScannedAt,
        )) {
      return;
    }

    _lastScannedBarcode = barcode;
    _lastScannedAt = DateTime.now();

    setState(() {
      _isLocked = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) {
      return;
    }

    await _handleDetectedBarcode(barcode);
  }

  Future<void> _handleDetectedBarcode(String barcode) async {
    if (!mounted || _isResolving) {
      return;
    }

    final onBarcodeScanned = widget.onBarcodeScanned;
    if (onBarcodeScanned != null) {
      await _stopScanner();
      final handled = await onBarcodeScanned(barcode);
      if (!mounted) {
        return;
      }
      if (!handled) {
        _showSnackBar(
          AppLocalizations.of(context)!.inventoryManualAddLookupFailed,
        );
        setState(() {
          _isLocked = false;
        });
        await _startScanner();
      }
      return;
    }

    setState(() {
      _isResolving = true;
    });
    await _stopScanner();

    var shouldRestartScanner = true;
    try {
      final candidates = await resolveInventoryBarcodeCandidates(
        ref: ref,
        barcode: barcode,
      );
      if (!mounted) {
        return;
      }
      shouldRestartScanner = await handleInventoryBarcodeCandidates(
        context: context,
        candidates: candidates,
        scannedBarcode: barcode,
        showActionButtons: widget.showActionButtons,
        eatOnly: widget.eatOnly,
        onProductSelected: widget.onProductSelected,
        onProductNotFound: widget.onProductNotFound,
        onCreateManualProduct: widget.onCreateManualProduct,
        showSnackBar: _showSnackBar,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResolving = false;
          _isLocked = false;
        });
        if (shouldRestartScanner) {
          await _startScanner();
        }
      }
    }
  }

  Future<void> _stopScanner() async {
    try {
      await _scannerController.stop();
    } on Object catch (error, stackTrace) {
      log(
        'Stopping inventory barcode scanner failed.',
        name: _scannerLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _startScanner() async {
    try {
      await _scannerController.start();
    } on Object catch (error, stackTrace) {
      log(
        'Starting inventory barcode scanner failed.',
        name: _scannerLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
