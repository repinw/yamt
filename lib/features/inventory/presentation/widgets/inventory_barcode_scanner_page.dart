import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _inventoryBarcodeScannerLogName = 'InventoryBarcodeScannerPage';
const _inventoryBarcodeCandidateLimit = 5;
const _barcodeAmountParser = InventoryAmountParser();
const inventoryBarcodeCandidateSheetKey = Key(
  'inventory_barcode_candidate_sheet',
);

enum InventoryBarcodeLookupCandidateSource { learned, off }

class InventoryBarcodeLookupCandidate {
  const InventoryBarcodeLookupCandidate._({
    required this.source,
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.packageWeight,
    this.servingSize,
    this.servingQuantity,
    this.servingQuantityUnit,
    this.nutrition,
    this.globalFoodItemId,
    this.globalFoodItem,
    this.externalProduct,
    this.selectionCount = 0,
    this.uniqueUserCount = 0,
  });

  factory InventoryBarcodeLookupCandidate.fromLearned(
    GlobalBarcodeCandidate candidate,
  ) {
    final item = candidate.globalFoodItem;
    return InventoryBarcodeLookupCandidate._(
      source: InventoryBarcodeLookupCandidateSource.learned,
      barcode: candidate.barcode,
      name: item.name,
      brand: item.brand,
      imageUrl: item.imageUrl,
      packageWeight: item.packageWeight,
      servingSize: item.servingSize,
      servingQuantity: item.servingQuantity,
      servingQuantityUnit: item.servingQuantityUnit,
      nutrition: item.nutrition,
      globalFoodItemId: candidate.globalFoodItemId,
      globalFoodItem: item,
      selectionCount: candidate.selectionCount,
      uniqueUserCount: candidate.uniqueUserCount,
    );
  }

  factory InventoryBarcodeLookupCandidate.fromOffProduct(
    OffProductSearchResult product,
  ) {
    return InventoryBarcodeLookupCandidate._(
      source: InventoryBarcodeLookupCandidateSource.off,
      barcode: normalizeBarcode(product.code),
      name: product.name,
      brand: product.brand,
      imageUrl: product.imageUrl,
      packageWeight: product.packageWeight,
      servingSize: product.servingSize,
      servingQuantity: product.servingQuantity,
      servingQuantityUnit: product.servingQuantityUnit,
      nutrition: product.nutrition,
      externalProduct: product,
    );
  }

  final InventoryBarcodeLookupCandidateSource source;
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final String? packageWeight;
  final String? servingSize;
  final double? servingQuantity;
  final String? servingQuantityUnit;
  final GlobalFoodNutrition? nutrition;
  final String? globalFoodItemId;
  final GlobalFoodItem? globalFoodItem;
  final OffProductSearchResult? externalProduct;
  final int selectionCount;
  final int uniqueUserCount;
}

typedef InventoryBarcodeProductSelectionCallback =
    Future<bool> Function(
      InventoryBarcodeLookupCandidate candidate,
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
      final results = await Future.wait<Object?>(<Future<Object?>>[
        ref
            .read(globalBarcodeCandidateRepositoryProvider)
            .readCandidates(
              barcode: barcode,
              limit: _inventoryBarcodeCandidateLimit,
            ),
        ref
            .read(offProductSearchRepositoryProvider)
            .lookupCandidatesByBarcode(barcode: barcode),
      ]);
      if (!mounted) {
        return;
      }
      final candidates = mergeInventoryBarcodeCandidates(
        learnedCandidates: results[0]! as List<GlobalBarcodeCandidate>,
        offCandidates: results[1]! as List<OffProductSearchResult>,
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

  final List<InventoryBarcodeLookupCandidate> candidates;
  final ValueChanged<InventoryBarcodeLookupCandidate> onSelect;

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

  final InventoryBarcodeLookupCandidate candidate;

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

List<InventoryBarcodeLookupCandidate> mergeInventoryBarcodeCandidates({
  required List<GlobalBarcodeCandidate> learnedCandidates,
  required List<OffProductSearchResult> offCandidates,
}) {
  final merged = <InventoryBarcodeLookupCandidate>[];
  final learnedKeys = <String>{};
  final seenOffKeys = <String>{};

  for (final candidate in learnedCandidates) {
    final resolved = InventoryBarcodeLookupCandidate.fromLearned(candidate);
    learnedKeys.add(inventoryBarcodeCandidateDedupeKey(resolved));
    merged.add(resolved);
    if (merged.length == _inventoryBarcodeCandidateLimit) {
      return merged;
    }
  }
  for (final candidate in offCandidates) {
    final resolved = InventoryBarcodeLookupCandidate.fromOffProduct(candidate);
    final key = inventoryBarcodeCandidateDedupeKey(resolved);
    if (learnedKeys.contains(key) || !seenOffKeys.add(key)) {
      continue;
    }
    merged.add(resolved);
    if (merged.length == _inventoryBarcodeCandidateLimit) {
      break;
    }
  }
  return merged;
}

String inventoryBarcodeCandidateDedupeKey(
  InventoryBarcodeLookupCandidate candidate,
) {
  final normalizedName = candidate.name.trim().toLowerCase();
  final normalizedBrand = (candidate.brand ?? '').trim().toLowerCase();
  final normalizedWeight = _normalizedBarcodeCandidateWeight(
    candidate.packageWeight,
  );
  return '${candidate.barcode}|$normalizedName|$normalizedBrand|'
      '$normalizedWeight';
}

String _normalizedBarcodeCandidateWeight(String? rawWeight) {
  final parsed = _barcodeAmountParser.tryParse(
    rawWeight: rawWeight,
    quantity: 1,
  );
  if (parsed != null) {
    return '${parsed.amount}${parsed.unit.code}';
  }
  return rawWeight?.trim().toLowerCase() ?? '';
}
