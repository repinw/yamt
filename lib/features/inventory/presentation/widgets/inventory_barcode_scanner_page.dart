import 'dart:async' show unawaited;
import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_candidate_picker_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_lookup_candidate.dart';
import 'package:yamt/l10n/app_localizations.dart';

export 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_candidate_picker_sheet.dart'
    show inventoryBarcodeCandidateSheetKey;
export 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_lookup_candidate.dart'
    show
        InventoryBarcodeCandidateAction,
        InventoryBarcodeLookupCandidate,
        InventoryBarcodeLookupCandidateSource,
        InventoryBarcodeNotFoundCallback,
        InventoryBarcodeProductSelectionCallback,
        inventoryBarcodeCandidateDedupeKey,
        inventoryBarcodeCandidateWidgetKeySuffix,
        mergeInventoryBarcodeCandidates;

const _inventoryBarcodeScannerLogName = 'InventoryBarcodeScannerPage';

/// Defines inventory barcode scanner page.
class InventoryBarcodeScannerPage extends StatelessWidget {
  /// The inventory barcode scanner page.
  const InventoryBarcodeScannerPage({
    required this.title,
    required this.onProductSelected,
    super.key,
    this.onProductNotFound,
    this.showActionButtons = true,
    this.eatOnly = false,
  });

  /// The title.
  final String title;

  /// The on product selected.
  final InventoryBarcodeProductSelectionCallback onProductSelected;

  /// The on product not found.
  final InventoryBarcodeNotFoundCallback? onProductNotFound;

  /// Whether candidate rows show explicit action buttons.
  final bool showActionButtons;

  /// Whether only eat actions should be shown.
  final bool eatOnly;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: InventoryBarcodeScannerView(
        onProductSelected: onProductSelected,
        onProductNotFound: onProductNotFound,
        showActionButtons: showActionButtons,
        eatOnly: eatOnly,
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
    this.showActionButtons = true,
    this.eatOnly = false,
  });

  /// The on product selected.
  final InventoryBarcodeProductSelectionCallback onProductSelected;

  /// The on product not found.
  final InventoryBarcodeNotFoundCallback? onProductNotFound;

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
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isResolving = false;

  @override
  void dispose() {
    unawaited(_scannerController.dispose());
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
          );
    } on Object catch (error, stackTrace) {
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
    } on Object catch (error, stackTrace) {
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

    final selection = await _pickCandidate(candidates);
    if (!mounted || selection == null) {
      return true;
    }

    final handled = await widget.onProductSelected(
      selection.candidate,
      scannedBarcode,
      selection.action,
    );
    return !handled;
  }

  Future<_InventoryBarcodeCandidateSelection?> _pickCandidate(
    List<InventoryBarcodeLookupCandidate> candidates,
  ) {
    return showModalBottomSheet<_InventoryBarcodeCandidateSelection>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return InventoryBarcodeCandidatePickerSheet(
          candidates: candidates,
          showActionButtons: widget.showActionButtons,
          eatOnly: widget.eatOnly,
          onSelect: (candidate, action) => _popRoute(
            sheetContext,
            _InventoryBarcodeCandidateSelection(
              candidate: candidate,
              action: action,
            ),
          ),
        );
      },
    );
  }

  Future<void> _stopScanner() async {
    try {
      await _scannerController.stop();
    } on Object catch (error, stackTrace) {
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
    } on Object catch (error, stackTrace) {
      log(
        'Starting inventory barcode scanner failed.',
        name: _inventoryBarcodeScannerLogName,
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

class _InventoryBarcodeCandidateSelection {
  const _InventoryBarcodeCandidateSelection({
    required this.candidate,
    required this.action,
  });

  final InventoryBarcodeLookupCandidate candidate;
  final InventoryBarcodeCandidateAction action;
}
