import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/scanner/data/receipt_gateway_providers.dart';
import 'package:yamt/features/scanner/domain/contracts/receipt_product_resolver.dart';
import 'package:yamt/features/scanner/domain/contracts/receipt_structured_parser.dart';
import 'package:yamt/features/scanner/domain/contracts/receipt_text_extractor.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';
import 'package:yamt/l10n/app_localizations.dart';

part 'receipt_scan_flow_coordinator.g.dart';

/// Signature for camera photo acquisition.
typedef ReceiptCameraPicker = Future<String?> Function();

/// Signature for file acquisition (PDF / images).
typedef ReceiptFilesPicker = Future<List<String>> Function();

/// Signature for opening the receipt review screen.
typedef ReceiptReviewLauncher =
    Future<bool?> Function(
      BuildContext context,
      ScannedReceipt receipt,
    );

/// Provider for [ReceiptScanFlowCoordinator].
@Riverpod(
  dependencies: [
    receiptStructuredParser,
    receiptTextExtractor,
    receiptProductResolver,
  ],
)
ReceiptScanFlowCoordinator receiptScanFlowCoordinator(Ref ref) {
  return ReceiptScanFlowCoordinator(
    parser: ref.watch(receiptStructuredParserProvider),
    extractor: ref.watch(receiptTextExtractorProvider),
    resolver: ref.watch(receiptProductResolverProvider),
  );
}

/// Orchestrates receipt capturing, text extraction, structured AI parsing,
/// product pre-resolution, and the review screen flow.
class ReceiptScanFlowCoordinator {
  /// Creates a [ReceiptScanFlowCoordinator].
  ReceiptScanFlowCoordinator({
    required ReceiptStructuredParser parser,
    required ReceiptTextExtractor extractor,
    required ReceiptProductResolver resolver,
    ReceiptCameraPicker? cameraPicker,
    ReceiptFilesPicker? filesPicker,
    ReceiptReviewLauncher? reviewLauncher,
  }) : _parser = parser,
       _extractor = extractor,
       _resolver = resolver,
       _cameraPicker = cameraPicker ?? _defaultCameraPicker,
       _filesPicker = filesPicker ?? _defaultFilesPicker,
       _reviewLauncher = reviewLauncher ?? _defaultReviewLauncher;

  final ReceiptStructuredParser _parser;
  final ReceiptTextExtractor _extractor;
  final ReceiptProductResolver _resolver;
  final ReceiptCameraPicker _cameraPicker;
  final ReceiptFilesPicker _filesPicker;
  final ReceiptReviewLauncher _reviewLauncher;

  /// Starts the camera flow to take a photo of a receipt.
  ///
  /// Returns `true` if a receipt was successfully scanned and saved.
  Future<bool> startCameraFlow(BuildContext context) async {
    final path = await _cameraPicker();
    if (path == null || path.isEmpty || !context.mounted) return false;

    return processFilePaths(context, [path]);
  }

  /// Starts the file picker flow for PDF documents or images.
  ///
  /// Returns `true` if a receipt was successfully scanned and saved.
  Future<bool> startFilePickerFlow(BuildContext context) async {
    final paths = await _filesPicker();
    if (paths.isEmpty || !context.mounted) return false;

    return processFilePaths(context, paths);
  }

  /// Processes pre-selected file paths (e.g. from shared intent or picker).
  ///
  /// Returns `true` if a receipt was successfully reviewed and saved.
  Future<bool> processFilePaths(
    BuildContext context,
    List<String> filePaths,
  ) async {
    final validPaths = filePaths
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    if (validPaths.isEmpty) return false;

    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    var dialogOpen = true;

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.receiptReviewAnalyzing ?? 'Beleg wird analysiert...',
                  ),
                ],
              ),
            ),
          ),
        ),
      ).whenComplete(() => dialogOpen = false),
    );

    try {
      final receipt = await _extractAndParse(validPaths);
      final enriched = await _preResolveProducts(receipt);

      if (dialogOpen && navigator.mounted) {
        navigator.pop();
        dialogOpen = false;
      }

      if (!context.mounted) return false;

      final saved = await _reviewLauncher(context, enriched);

      return saved ?? false;
    } on Object catch (error) {
      if (dialogOpen && navigator.mounted) {
        navigator.pop();
        dialogOpen = false;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.receiptReviewProcessingFailed(error.toString()) ??
                  'Belegverarbeitung fehlgeschlagen: $error',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return false;
    }
  }

  Future<ScannedReceipt> _extractAndParse(List<String> validPaths) async {
    final isPdf = validPaths.any((p) => p.toLowerCase().endsWith('.pdf'));

    if (isPdf) {
      final pdfPath = validPaths.firstWhere(
        (p) => p.toLowerCase().endsWith('.pdf'),
      );
      return _parser.parsePdf(pdfFilePath: pdfPath);
    }

    final rawText = await _extractor.extractText(validPaths);
    return _parser.parseRawText(
      rawText: rawText,
      sourceFilePaths: validPaths,
    );
  }

  Future<ScannedReceipt> _preResolveProducts(ScannedReceipt receipt) async {
    if (receipt.items.isEmpty) return receipt;

    Map<String, List<ProductCandidate>> candidateMap;
    try {
      candidateMap = await _resolver.resolveBatch(
        items: receipt.items,
        storeName: receipt.storeName,
      );
    } on Object {
      candidateMap = const <String, List<ProductCandidate>>{};
    }

    final updatedItems = receipt.items
        .map((item) {
          final candidates =
              candidateMap[item.id] ?? const <ProductCandidate>[];
          if (candidates.isEmpty) return item;

          final bestMatch = candidates.first;
          final isExact = bestMatch.source == CandidateSource.aliasExact;
          final status = isExact
              ? ReceiptItemStatus.confirmed
              : ReceiptItemStatus.suggested;

          return item.copyWith(
            matchedProduct: bestMatch,
            candidates: candidates,
            status: status,
          );
        })
        .toList(growable: false);

    return receipt.copyWith(items: updatedItems);
  }

  static Future<String?> _defaultCameraPicker() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    return file?.path;
  }

  static Future<List<String>> _defaultFilesPicker() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    if (result == null || result.files.isEmpty) return const <String>[];
    return result.files
        .map((f) => f.path)
        .whereType<String>()
        .toList(growable: false);
  }

  static Future<bool?> _defaultReviewLauncher(
    BuildContext context,
    ScannedReceipt receipt,
  ) {
    return context.push<bool>(
      AppRoutes.homeInventoryReceiptReview,
      extra: receipt,
    );
  }
}
