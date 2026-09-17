import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/features/scanner/data/google_ai_receipt_schema.dart';
import 'package:yamt/features/scanner/domain/contracts/receipt_structured_parser.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';

const String _defaultModelName = 'gemini-3.8-flash';
const Duration _defaultTimeout = Duration(seconds: 30);
const Uuid _uuid = Uuid();

/// Function signature for generating AI content (used for test fakes/mocks).
typedef GenerateContentHandler = Future<String?> Function(
  Iterable<Content> content,
);

/// Implementation of [ReceiptStructuredParser] using the Google AI API
/// (Gemini Flash).
class GoogleAiReceiptParser implements ReceiptStructuredParser {
  /// Creates a [GoogleAiReceiptParser].
  ///
  /// If [apiKey] is not provided, falls back to the `GEMINI_API_KEY`
  /// environment definition.
  /// For tests, [contentHandler] can be provided to bypass network requests.
  new({
    String? apiKey,
    String modelName = _defaultModelName,
    this._requestTimeout = _defaultTimeout,
    GenerateContentHandler? contentHandler,
  }) : _contentHandler = contentHandler,
       _model = contentHandler == null
           ? _createModel(
               apiKey ?? const String.fromEnvironment('GEMINI_API_KEY'),
               modelName,
             )
           : null;

  final Duration _requestTimeout;
  final GenerativeModel? _model;
  final GenerateContentHandler? _contentHandler;

  static GenerativeModel _createModel(String apiKey, String modelName) {
    if (apiKey.isEmpty) {
      throw ArgumentError(
        'GEMINI_API_KEY must be provided via constructor or '
        '--dart-define=GEMINI_API_KEY=...',
      );
    }
    return GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(googleAiReceiptSystemInstruction),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: googleAiReceiptSchema,
      ),
    );
  }

  @override
  Future<ScannedReceipt> parseRawText({
    required String rawText,
    List<String> sourceFilePaths = const <String>[],
  }) async {
    final prompt = Content.text(
      'Analyze this raw receipt text and extract all items:\n\n$rawText',
    );

    final responseText = await _generate([prompt]);
    return _parseJsonResponse(
      responseText,
      sourceFilePaths: sourceFilePaths,
      rawText: rawText,
    );
  }

  @override
  Future<ScannedReceipt> parsePdf({required String pdfFilePath}) async {
    final file = File(pdfFilePath);
    if (!file.existsSync()) {
      throw FileSystemException('PDF file does not exist', pdfFilePath);
    }

    final bytes = await file.readAsBytes();
    final prompt = Content.multi([
      TextPart(
        'Analyze this digital PDF receipt document and extract all items.',
      ),
      DataPart('application/pdf', bytes),
    ]);

    final responseText = await _generate([prompt]);
    return _parseJsonResponse(
      responseText,
      sourceFilePaths: <String>[pdfFilePath],
    );
  }

  Future<String> _generate(Iterable<Content> content) async {
    if (_contentHandler != null) {
      final result = await _contentHandler(content);
      if (result == null || result.trim().isEmpty) {
        throw const FormatException('Empty AI response received');
      }
      return result;
    }

    final response = await _model!
        .generateContent(content)
        .timeout(_requestTimeout);
    final text = response.text;
    if (text == null || text.trim().isEmpty) {
      throw const FormatException('Empty AI response from Gemini');
    }
    return text;
  }

  ScannedReceipt _parseJsonResponse(
    String jsonString, {
    required List<String> sourceFilePaths,
    String? rawText,
  }) {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Root of AI response must be a JSON object');
    }

    final rawItems = decoded['items'];
    if (rawItems is! List<dynamic>) {
      throw const FormatException('Missing items array in AI response');
    }

    return ScannedReceipt(
      id: _uuid.v4(),
      storeName: decoded['storeName']?.toString(),
      dateTime: _parseDateTime(decoded['dateTime']),
      printedTotal: (decoded['printedTotal'] as num?)?.toDouble(),
      currency: decoded['currency']?.toString() ?? 'EUR',
      sourceFilePaths: sourceFilePaths,
      rawText: rawText,
      items: _parseLineItems(rawItems),
    );
  }

  List<ReceiptLineItem> _parseLineItems(List<dynamic> rawItems) {
    final items = <ReceiptLineItem>[];
    for (final rawItem in rawItems) {
      if (rawItem is Map<String, dynamic>) {
        final item = _parseSingleLineItem(rawItem);
        if (item != null) {
          items.add(item);
        }
      }
    }
    return items;
  }

  ReceiptLineItem? _parseSingleLineItem(Map<String, dynamic> rawItem) {
    final rawName = rawItem['rawName']?.toString() ?? '';
    if (rawName.isEmpty) return null;

    final isDeposit = rawItem['isDeposit'] as bool? ?? false;
    final isDiscount = rawItem['isDiscount'] as bool? ?? false;

    return ReceiptLineItem(
      id: _uuid.v4(),
      rawName: rawName,
      totalPrice: (rawItem['totalPrice'] as num?)?.toDouble() ?? 0.0,
      discount: (rawItem['discount'] as num?)?.toDouble() ?? 0.0,
      quantity: (rawItem['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (rawItem['unitPrice'] as num?)?.toDouble(),
      unit: rawItem['unit']?.toString(),
      rawCategory: rawItem['rawCategory']?.toString(),
      rawBrand: rawItem['rawBrand']?.toString(),
      packageWeight: rawItem['packageWeight']?.toString(),
      isDeposit: isDeposit,
      isDiscount: isDiscount,
      status: (isDeposit || isDiscount)
          ? ReceiptItemStatus.confirmed
          : ReceiptItemStatus.unmatched,
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    final str = value?.toString().trim();
    if (str == null || str.isEmpty) return null;

    final iso = DateTime.tryParse(str);
    if (iso != null) return iso;

    final match = RegExp(
      r'^(\d{1,2})\.(\d{1,2})\.(\d{2,4})(?:[,\s]+(\d{1,2}):(\d{2})(?::(\d{2}))?)?$',
    ).firstMatch(str);
    if (match != null) {
      var year = int.parse(match.group(3)!);
      if (year < 100) year += 2000;
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(1)!);
      final hour = match.group(4) != null ? int.parse(match.group(4)!) : 0;
      final minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
      final second = match.group(6) != null ? int.parse(match.group(6)!) : 0;
      return DateTime(year, month, day, hour, minute, second);
    }
    return null;
  }
}
