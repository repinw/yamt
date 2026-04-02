import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _inventoryBarcodeScannerLogName = 'InventoryBarcodeScannerPage';
const inventoryBarcodeCandidateSheetKey = Key(
  'inventory_barcode_candidate_sheet',
);

typedef InventoryBarcodeProductSelectionCallback =
    Future<bool> Function(
      OffProductSearchResult candidate,
      String scannedBarcode,
    );

typedef InventoryBarcodeNotFoundCallback =
    Future<bool> Function(String scannedBarcode);

class InventoryBarcodeScannerPage extends StatelessWidget {
  const InventoryBarcodeScannerPage({
    super.key,
    required this.title,
    required this.onProductSelected,
    this.onProductNotFound,
  });

  final String title;
  final InventoryBarcodeProductSelectionCallback onProductSelected;
  final InventoryBarcodeNotFoundCallback? onProductNotFound;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: InventoryBarcodeScannerView(
        onProductSelected: onProductSelected,
        onProductNotFound: onProductNotFound,
      ),
    );
  }
}

class InventoryBarcodeScannerView extends ConsumerStatefulWidget {
  const InventoryBarcodeScannerView({
    super.key,
    required this.onProductSelected,
    this.onProductNotFound,
  });

  final InventoryBarcodeProductSelectionCallback onProductSelected;
  final InventoryBarcodeNotFoundCallback? onProductNotFound;

  @override
  ConsumerState<InventoryBarcodeScannerView> createState() =>
      _InventoryBarcodeScannerViewState();
}

class _InventoryBarcodeScannerViewState
    extends ConsumerState<InventoryBarcodeScannerView> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isResolving = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_isMobileBarcodeScanSupported()) {
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
        _ScannerHintCard(message: l10n.inventoryManualAddHint),
        if (_isResolving)
          ColoredBox(
            color: Colors.black45,
            child: Center(
              child: Card(
                child: Padding(
                  padding: AppInsets.card,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const SizedBox.square(
                        dimension: AppSizes.inlineProgressIndicator,
                        child: CircularProgressIndicator(
                          strokeWidth: AppSizes.progressStrokeWidth,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(l10n.inventoryManualAddResolving),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final rawBarcode = capture.barcodes.firstOrNull?.rawValue;
    if (rawBarcode == null || rawBarcode.trim().isEmpty) {
      return;
    }
    await _handleDetectedBarcode(rawBarcode);
  }

  Future<void> _handleDetectedBarcode(String rawBarcode) async {
    if (!mounted || _isResolving) {
      return;
    }

    final barcode = normalizeBarcode(rawBarcode);
    if (barcode.isEmpty || !isSupportedBarcode(barcode)) {
      _showSnackBar(
        AppLocalizations.of(context)!.inventoryManualAddLookupFailed,
      );
      return;
    }

    setState(() {
      _isResolving = true;
    });
    await _stopScanner();

    var shouldRestartScanner = true;
    try {
      final candidates = await ref
          .read(offProductSearchRepositoryProvider)
          .lookupCandidatesByBarcode(barcode: barcode);
      if (!mounted) {
        return;
      }
      shouldRestartScanner = await _handleCandidates(
        candidates: candidates,
        scannedBarcode: barcode,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResolving = false;
        });
        if (shouldRestartScanner) {
          await _startScanner();
        }
      }
    }
  }

  Future<bool> _handleCandidates({
    required List<OffProductSearchResult> candidates,
    required String scannedBarcode,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (scannedBarcode.isEmpty || !isSupportedBarcode(scannedBarcode)) {
      _showSnackBar(l10n.inventoryManualAddLookupFailed);
      return true;
    }

    if (candidates.isEmpty) {
      final handled =
          await widget.onProductNotFound?.call(scannedBarcode) ?? false;
      if (!mounted) {
        return false;
      }
      if (!handled) {
        _showSnackBar(l10n.inventoryManualAddNotFound);
      }
      return !handled;
    }

    final selected = candidates.length == 1
        ? candidates.single
        : await _pickCandidate(candidates);
    if (!mounted || selected == null) {
      return true;
    }

    final handled = await widget.onProductSelected(selected, scannedBarcode);
    return !handled;
  }

  Future<OffProductSearchResult?> _pickCandidate(
    List<OffProductSearchResult> candidates,
  ) {
    return showModalBottomSheet<OffProductSearchResult>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _InventoryBarcodeCandidatePickerSheet(
          candidates: candidates,
          onSelect: (candidate) => Navigator.of(sheetContext).pop(candidate),
        );
      },
    );
  }

  Future<void> _stopScanner() async {
    try {
      await _scannerController.stop();
    } catch (error, stackTrace) {
      log(
        'Stopping inventory barcode scanner failed.',
        name: _inventoryBarcodeScannerLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _startScanner() async {
    try {
      await _scannerController.start();
    } catch (error, stackTrace) {
      log(
        'Starting inventory barcode scanner failed.',
        name: _inventoryBarcodeScannerLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ScannerHintCard extends StatelessWidget {
  const _ScannerHintCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: AppInsets.page,
          child: Card(
            child: Padding(
              padding: AppInsets.card,
              child: Text(message, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}

class _InventoryBarcodeCandidatePickerSheet extends StatelessWidget {
  const _InventoryBarcodeCandidatePickerSheet({
    required this.candidates,
    required this.onSelect,
  });

  final List<OffProductSearchResult> candidates;
  final ValueChanged<OffProductSearchResult> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Column(
        key: inventoryBarcodeCandidateSheetKey,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            title: Text(l10n.inventoryManualAddCandidateTitle),
            subtitle: Text(l10n.inventoryManualAddCandidateSubtitle),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: candidates.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final candidate = candidates[index];
                return ListTile(
                  title: Text(candidate.name),
                  subtitle: Text(
                    candidate.brand?.trim().isNotEmpty == true
                        ? candidate.brand!.trim()
                        : l10n.inventoryManualAddUnknownBrand,
                  ),
                  trailing: _CandidateKcalLabel(candidate: candidate),
                  onTap: () => onSelect(candidate),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateKcalLabel extends StatelessWidget {
  const _CandidateKcalLabel({required this.candidate});

  final OffProductSearchResult candidate;

  @override
  Widget build(BuildContext context) {
    final kcal = candidate.nutrition?.per100Kcal;
    if (kcal == null) {
      return const SizedBox.shrink();
    }

    return Text(
      '${kcal.toStringAsFixed(0)} '
      '${AppLocalizations.of(context)!.caloriesUnitKcal}',
    );
  }
}

bool _isMobileBarcodeScanSupported() {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}
