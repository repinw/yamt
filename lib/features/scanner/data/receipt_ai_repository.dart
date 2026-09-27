import 'dart:convert';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:mime/mime.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
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
      for (final path in filePaths)
        {
          'mimeType': _mimeTypeOf(path),
          'data': base64Encode(await File(path).readAsBytes()),
        },
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
