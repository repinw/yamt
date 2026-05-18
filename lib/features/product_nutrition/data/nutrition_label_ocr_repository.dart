// Firebase AI template APIs are still marked experimental in current package.
// ignore_for_file: experimental_member_use

import 'dart:convert';
import 'dart:developer' show log;

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/product_nutrition/domain/'
    'nutrition_label_ocr_models.dart';

part 'nutrition_label_ocr_repository.g.dart';

const _ocrLogName = 'NutritionLabelOcrRepository';
const _ocrTemplateId = 'nutrition-template-id';
const _vertexLocation = 'global';
const _defaultMimeType = 'application/octet-stream';

/// Defines nutrition label OCR error codes.
abstract final class NutritionLabelOcrErrorCodes {
  /// The camera not supported.
  static const cameraNotSupported = 'ocr_camera_not_supported';

  /// The template config failed.
  static const templateConfigFailed = 'ocr_template_config_failed';

  /// The AI request failed.
  static const aiRequestFailed = 'ocr_ai_request_failed';

  /// Firebase App Check temporarily blocked the AI request.
  static const appCheckThrottled = 'ocr_app_check_throttled';

  /// The parse failed.
  static const parseFailed = 'ocr_parse_failed';
}

/// Loads nutrition label template id.
typedef NutritionLabelTemplateConfigClient = Future<String> Function();

/// Generates nutrition label template content.
typedef NutritionLabelTemplateModelClient =
    Future<String?> Function({
      required String templateId,
      required Map<String, Object?> inputs,
    });

/// Nutrition label OCR repository.
@riverpod
NutritionLabelOcrRepository nutritionLabelOcrRepository(Ref ref) {
  final imagePicker = ref.watch(nutritionLabelImagePickerProvider);
  return NutritionLabelOcrRepository(
    imagePicker: imagePicker,
    configClient: ref.watch(nutritionLabelTemplateConfigClientProvider),
    modelClient: ref.watch(nutritionLabelTemplateModelClientProvider),
  );
}

/// Nutrition label image picker.
@riverpod
ImagePicker nutritionLabelImagePicker(Ref ref) {
  return ImagePicker();
}

/// Nutrition label template config client.
@riverpod
NutritionLabelTemplateConfigClient nutritionLabelTemplateConfigClient(Ref ref) {
  return () async => _ocrTemplateId;
}

/// Nutrition label template model client.
@riverpod
NutritionLabelTemplateModelClient nutritionLabelTemplateModelClient(Ref ref) {
  final model = FirebaseAI.vertexAI(
    location: _vertexLocation,
  ).templateGenerativeModel();
  return ({
    required String templateId,
    required Map<String, Object?> inputs,
  }) async {
    final response = await model.generateContent(templateId, inputs: inputs);
    return response.text;
  };
}

/// Scans nutrition labels with Firebase AI.
class NutritionLabelOcrRepository {
  /// Creates nutrition label OCR repository.
  NutritionLabelOcrRepository({
    required ImagePicker imagePicker,
    required NutritionLabelTemplateConfigClient configClient,
    required NutritionLabelTemplateModelClient modelClient,
  }) : _imagePicker = imagePicker,
       _configClient = configClient,
       _modelClient = modelClient;

  final ImagePicker _imagePicker;
  final NutritionLabelTemplateConfigClient _configClient;
  final NutritionLabelTemplateModelClient _modelClient;

  /// Scan nutrition label.
  Future<NutritionLabelOcrResult> scanNutritionLabel({
    required String barcode,
  }) async {
    log(
      'Starting nutrition label OCR for barcode $barcode.',
      name: _ocrLogName,
    );
    if (!_isCameraSupported()) {
      log('Nutrition label OCR not supported on platform.', name: _ocrLogName);
      return const NutritionLabelOcrResult.failed(
        errorCode: NutritionLabelOcrErrorCodes.cameraNotSupported,
      );
    }

    try {
      final image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image == null) {
        log(
          'Nutrition label OCR canceled before image capture.',
          name: _ocrLogName,
        );
        return const NutritionLabelOcrResult.canceled();
      }

      final bytes = await image.readAsBytes();
      final mimeType = _detectMimeType(fileName: image.name, bytes: bytes);
      log(
        'Captured nutrition label image. '
        'mimeType=$mimeType bytes=${bytes.length}',
        name: _ocrLogName,
      );
      final templateId = await _loadTemplateId();
      if (templateId == null) {
        log('Nutrition label OCR missing template id.', name: _ocrLogName);
        return const NutritionLabelOcrResult.failed(
          errorCode: NutritionLabelOcrErrorCodes.templateConfigFailed,
        );
      }

      log('Calling OCR model with template "$templateId".', name: _ocrLogName);
      final responseText = await _modelClient(
        templateId: templateId,
        inputs: <String, Object?>{
          'mimeType': mimeType,
          'imageData': base64Encode(bytes),
        },
      );
      final draft = _parseDraft(responseText, barcode: barcode);
      if (draft == null) {
        log(
          'Nutrition label OCR response could not be parsed.',
          name: _ocrLogName,
        );
        return const NutritionLabelOcrResult.failed(
          errorCode: NutritionLabelOcrErrorCodes.parseFailed,
        );
      }
      log(
        'Nutrition label OCR succeeded for barcode $barcode. '
        'kcal=${draft.per100Kcal}',
        name: _ocrLogName,
      );
      return NutritionLabelOcrResult.succeeded(draft: draft);
    } on Exception catch (error, stackTrace) {
      final errorCode = _resolveScanErrorCode(error);
      log(
        'OCR nutrition label failed for barcode $barcode.',
        name: _ocrLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return NutritionLabelOcrResult.failed(errorCode: errorCode);
    }
  }

  String _resolveScanErrorCode(Exception error) {
    if (_isAppCheckTooManyAttemptsError(error)) {
      return NutritionLabelOcrErrorCodes.appCheckThrottled;
    }
    return NutritionLabelOcrErrorCodes.aiRequestFailed;
  }

  bool _isAppCheckTooManyAttemptsError(Exception error) {
    if (error is! FirebaseException) {
      return false;
    }
    final message = (error.message ?? error.toString()).toLowerCase();
    return error.plugin == 'firebase_app_check' &&
        message.contains('too many attempts');
  }

  bool _isCameraSupported() {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<String?> _loadTemplateId() async {
    try {
      final templateId = await _configClient();
      log('Resolved OCR template id: $templateId', name: _ocrLogName);
      return templateId;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to load OCR template id.',
        name: _ocrLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  NutritionLabelOcrDraft? _parseDraft(
    String? responseText, {
    required String barcode,
  }) {
    if (responseText == null || responseText.trim().isEmpty) {
      return null;
    }
    final payload = _decodeJsonPayload(responseText);
    if (payload == null) {
      return null;
    }

    final flat = _flatten(payload);
    final name = _extractString(flat, const <String>[
      'n',
      'name',
      'product_name',
      'title',
    ]);
    final brand = _extractString(flat, const <String>['b', 'brand']);
    final quantityLabel = _extractString(flat, const <String>[
      'q',
      'quantity',
      'quantity_label',
      'package_size',
      'package_weight',
    ]);
    final servingSizeLabel = _extractString(flat, const <String>[
      'ss',
      'serving_size',
      'serving_size_label',
    ]);
    final kcal = _extractDouble(flat, const <String>[
      'kcal',
      'calories',
      'per100_kcal',
      'energy_kcal_100g',
    ]);
    final protein = _extractDouble(flat, const <String>[
      'protein',
      'proteins',
      'per100_protein',
    ]);
    final carbs = _extractDouble(flat, const <String>[
      'carbs',
      'carbohydrates',
      'per100_carbs',
    ]);
    final fat = _extractDouble(flat, const <String>['fat', 'per100_fat']);
    final salt = _extractDouble(flat, const <String>['salt', 'per100_salt']);
    final saturatedFat = _extractDouble(flat, const <String>[
      'saturated_fat',
      'saturates',
      'saturated',
    ]);
    final polyunsaturatedFat = _extractDouble(flat, const <String>[
      'polyunsaturated_fat',
    ]);
    final sugar = _extractDouble(flat, const <String>['sugar', 'sugars']);
    final fiber = _extractDouble(flat, const <String>['fiber', 'fibre']);

    final draft = NutritionLabelOcrDraft(
      barcode: barcode,
      name: name,
      brand: brand,
      quantityLabel: quantityLabel,
      servingSizeLabel: servingSizeLabel,
      per100Kcal: kcal,
      per100Protein: protein,
      per100Carbs: carbs,
      per100Fat: fat,
      per100Salt: salt,
      per100SaturatedFat: saturatedFat,
      per100PolyunsaturatedFat: polyunsaturatedFat,
      per100Sugar: sugar,
      per100Fiber: fiber,
    );
    if (!draft.hasAnyDetectedValue) {
      return null;
    }
    return draft;
  }

  Map<String, dynamic>? _decodeJsonPayload(String responseText) {
    final cleaned = responseText
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  Map<String, Object?> _flatten(Map<String, dynamic> payload) {
    final result = <String, Object?>{};

    void collect(Map<String, dynamic> value) {
      for (final entry in value.entries) {
        final key = _normalizeKey(entry.key);
        final rawValue = entry.value;
        if (rawValue is Map<String, dynamic>) {
          collect(rawValue);
          continue;
        }
        result[key] = rawValue;
      }
    }

    collect(payload);
    return result;
  }

  String _normalizeKey(String rawKey) {
    final trimmed = rawKey.trim().toLowerCase();
    return trimmed
        .replaceAll(RegExp('[^a-z0-9]+'), '_')
        .replaceAll(RegExp('_+'), '_');
  }

  String? _extractString(Map<String, Object?> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  double? _extractDouble(Map<String, Object?> payload, List<String> keys) {
    for (final key in keys) {
      final rawValue = payload[key];
      final parsed = _parseDouble(rawValue);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  double? _parseDouble(Object? rawValue) {
    if (rawValue is num) {
      return rawValue.toDouble();
    }
    if (rawValue is! String) {
      return null;
    }
    final normalized = rawValue.replaceAll(',', '.').trim();
    return double.tryParse(normalized);
  }

  String _detectMimeType({
    required String fileName,
    required Uint8List bytes,
  }) {
    return lookupMimeType(fileName, headerBytes: bytes) ?? _defaultMimeType;
  }
}
