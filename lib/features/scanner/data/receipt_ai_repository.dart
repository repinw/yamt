import 'dart:convert';
import 'dart:developer' show log;
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/utils/photo_jpeg.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';

part 'receipt_ai_repository.g.dart';

/// Firebase AI server prompt template that structures receipt files.
///
/// The prompt, model, and output schema live on the server, so they can
/// change without an app release.
const receiptParseTemplateId = 'receipt-parse-template';

const _requestTimeout = Duration(seconds: 60);
const _uuid = Uuid();

// A pixel cap instead of a side cap, so a long, narrow receipt page keeps
// its width and the small print stays readable.
const _maxPhotoPixels = 4000000;
const _maxPhotoSide = 6000;
const _shrinkableImageTypes = {'image/jpeg', 'image/png'};

/// Runs [receiptParseTemplateId] with template [inputs] and returns the
/// response text.
typedef ReceiptTemplateClient = Future<String?> Function(
  Map<String, Object?> inputs,
);

/// Receipt AI repository.
@riverpod
ReceiptAiRepository receiptAiRepository(Ref ref) {
  final model = FirebaseAI.googleAI().templateGenerativeModel();
  return ReceiptAiRepository(
    templateClient: (inputs) async {
      final response = await model
          .generateContent(receiptParseTemplateId, inputs: inputs)
          .timeout(_requestTimeout);
      return response.text;
    },
  );
}

/// Turns receipt photos and PDFs into a [ScannedReceipt] with Firebase AI.
class ReceiptAiRepository {
  /// Creates a receipt AI repository.
  new({required this._templateClient});

  final ReceiptTemplateClient _templateClient;

  /// Parses the files of one receipt, given in top-to-bottom order.
  ///
  /// Photos may overlap; the model merges lines that appear twice. Lines
  /// that are not food start as [ReceiptItemStatus.ignored].
  Future<ScannedReceipt> parseReceipt(List<String> filePaths) async {
    final files = <Map<String, Object?>>[
      for (final path in filePaths) await _fileInput(path),
    ];

    final text = await _templateClient({'files': files});
    if (text == null || text.trim().isEmpty) {
      throw const FormatException('Empty receipt AI response');
    }
    return _parseReceipt(
      jsonDecode(text) as Map<String, dynamic>,
      sourceFilePaths: filePaths,
    );
  }

  // Photos shrink one after another, so full-size scans of several pages
  // overflow neither the AI request nor the memory.
  Future<Map<String, Object?>> _fileInput(String path) async {
    final mimeType = _mimeTypeOf(path);
    final bytes = await File(path).readAsBytes();
    if (!_shrinkableImageTypes.contains(mimeType)) {
      return {'mimeType': mimeType, 'data': base64Encode(bytes)};
    }
    try {
      final jpeg = await compute(
        (bytes) => cleanPhotoJpeg(
          bytes,
          maxSide: _maxPhotoSide,
          maxPixels: _maxPhotoPixels,
        ),
        bytes,
      );
      return {'mimeType': 'image/jpeg', 'data': base64Encode(jpeg)};
    } on Object catch (error, stackTrace) {
      // The AI may still read what the image package cannot decode.
      log(
        'Could not shrink a receipt photo; sending it as it is.',
        name: 'ReceiptAiRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return {'mimeType': mimeType, 'data': base64Encode(bytes)};
    }
  }

  String _mimeTypeOf(String path) {
    final mimeType = lookupMimeType(path);
    if (mimeType == null ||
        !(mimeType.startsWith('image/') || mimeType == 'application/pdf')) {
      throw ArgumentError.value(path, 'filePaths', 'Unsupported receipt file');
    }
    return mimeType;
  }

  ScannedReceipt _parseReceipt(
    Map<String, dynamic> json, {
    required List<String> sourceFilePaths,
  }) {
    final dateTime = json['dt'] as String?;
    return ScannedReceipt(
      id: _uuid.v4(),
      storeName: json['s'] as String?,
      dateTime: dateTime == null ? null : DateTime.parse(dateTime),
      printedTotal: (json['t'] as num?)?.toDouble(),
      currency: json['cur'] as String? ?? 'EUR',
      sourceFilePaths: sourceFilePaths,
      items: [
        for (final item in json['i'] as List<dynamic>)
          _parseLineItem(item as Map<String, dynamic>),
      ],
    );
  }

  ReceiptLineItem _parseLineItem(Map<String, dynamic> json) {
    final isFood = json['f'] as bool;
    final isDeposit = json['dp'] as bool;
    final isDiscount = json['dc'] as bool;
    return ReceiptLineItem(
      id: _uuid.v4(),
      rawName: json['r'] as String,
      productName: json['n'] as String,
      totalPrice: (json['p'] as num).toDouble(),
      discount: (json['d'] as num?)?.toDouble() ?? 0,
      quantity: (json['q'] as num?)?.toDouble() ?? 1,
      unit: json['u'] as String?,
      unitPrice: (json['up'] as num?)?.toDouble(),
      rawBrand: json['b'] as String?,
      packageWeight: json['w'] as String?,
      isDeposit: isDeposit,
      isDiscount: isDiscount,
      status: switch ((isDeposit || isDiscount, isFood)) {
        (true, _) => ReceiptItemStatus.confirmed,
        (false, false) => ReceiptItemStatus.ignored,
        (false, true) => ReceiptItemStatus.unmatched,
      },
    );
  }
}
