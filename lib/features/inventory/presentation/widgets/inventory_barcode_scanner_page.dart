import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/l10n/app_localizations.dart';

import 'inventory_barcode_candidate_picker_sheet.dart';
import 'inventory_barcode_lookup_candidate.dart';

export 'inventory_barcode_candidate_picker_sheet.dart'
    show inventoryBarcodeCandidateSheetKey;
export 'inventory_barcode_lookup_candidate.dart'
    show
        InventoryBarcodeLookupCandidate,
        InventoryBarcodeLookupCandidateSource,
        InventoryBarcodeNotFoundCallback,
        InventoryBarcodeProductSelectionCallback,
        inventoryBarcodeCandidateDedupeKey,
        mergeInventoryBarcodeCandidates;

const _inventoryBarcodeScannerLogName = 'InventoryBarcodeScannerPage';
const _inventoryBarcodeCandidateLimit = 5;

/// Defines inventory barcode scanner page.
class InventoryBarcodeScannerPage extends StatelessWidget {
  /// The inventory barcode scanner page.
  const InventoryBarcodeScannerPage({
    required this.title,
    required this.onProductSelected,
    super.key,
    this.onProductNotFound,
  });

  /// The title.
  final String title;

  /// The on product selected.
  final InventoryBarcodeProductSelectionCallback onProductSelected;

  /// The on product not found.
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

/// Defines inventory barcode scanner view.
class InventoryBarcodeScannerView extends ConsumerStatefulWidget {
  /// The inventory barcode scanner view.
  const InventoryBarcodeScannerView({
    required this.onProductSelected,
    super.key,
    this.onProductNotFound,
  });

  /// The on product selected.
  final InventoryBarcodeProductSelectionCallback onProductSelected;

  /// The on product not found.
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
      final learnedCandidatesFuture = _readLearnedCandidates(barcode);
      final offCandidatesFuture = _readOffCandidates(barcode);
      final learnedCandidates = await learnedCandidatesFuture;
      final offCandidates = await offCandidatesFuture;
      if (!mounted) {
        return;
      }
      final candidates = mergeInventoryBarcodeCandidates(
        learnedCandidates: learnedCandidates,
        offCandidates: offCandidates,
      );
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

  Future<List<GlobalBarcodeCandidate>> _readLearnedCandidates(
    String barcode,
  ) async {
    try {
      return await ref
          .read(globalBarcodeCandidateRepositoryProvider)
          .readCandidates(
            barcode: barcode,
            limit: _inventoryBarcodeCandidateLimit,
          );
    } catch (error, stackTrace) {
      log(
        'Learned barcode candidate lookup failed for $barcode.',
        name: _inventoryBarcodeScannerLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <GlobalBarcodeCandidate>[];
    }
  }

  Future<List<OffProductSearchResult>> _readOffCandidates(
    String barcode,
  ) async {
    try {
      return await ref
          .read(offProductSearchRepositoryProvider)
          .lookupCandidatesByBarcode(barcode: barcode);
    } catch (error, stackTrace) {
      log(
        'OFF barcode candidate lookup failed for $barcode.',
        name: _inventoryBarcodeScannerLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <OffProductSearchResult>[];
    }
  }

  Future<bool> _handleCandidates({
    required List<InventoryBarcodeLookupCandidate> candidates,
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

  Future<InventoryBarcodeLookupCandidate?> _pickCandidate(
    List<InventoryBarcodeLookupCandidate> candidates,
  ) {
    return showModalBottomSheet<InventoryBarcodeLookupCandidate>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return InventoryBarcodeCandidatePickerSheet(
          candidates: candidates,
          onSelect: (candidate) => _popRoute(sheetContext, candidate),
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

  void _popRoute<T extends Object?>(BuildContext context, [T? result]) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.pop(result);
      return;
    }
    Navigator.of(context).pop(result);
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

bool _isMobileBarcodeScanSupported() {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}
