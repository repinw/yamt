// ignore_for_file: experimental_member_use

import 'dart:convert';
import 'dart:developer' show log;

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/'
    'calorie_nutrition_ocr_repository_contract.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_product_lookup_models.dart';

part 'calorie_nutrition_ocr_repository.g.dart';

const _ocrLogName = 'CalorieNutritionOcrRepository';
const _ocrTemplateId = 'nutrition-template-id';
const _vertexLocation = 'global';
const _defaultMimeType = 'application/octet-stream';
const _lookupHeaderLength = 32;

/// Defines calorie nutrition ocr error codes.
abstract final class CalorieNutritionOcrErrorCodes {
  /// The camera not supported.
  static const cameraNotSupported = 'ocr_camera_not_supported';

  /// The camera pick failed.
  static const cameraPickFailed = 'ocr_camera_pick_failed';

  /// The template config failed.
  static const templateConfigFailed = 'ocr_template_config_failed';

  /// The ai request failed.
  static const aiRequestFailed = 'ocr_ai_request_failed';

  /// The parse failed.
  static const parseFailed = 'ocr_parse_failed';
}

/// Defines calorie nutrition template config client.
abstract interface class CalorieNutritionTemplateConfigClient {
  /// Load template id.
  Future<String> loadTemplateId();
}

/// Defines calorie nutrition template model client.
abstract interface class CalorieNutritionTemplateModelClient {
  /// Generate content.
  Future<String?> generateContent({
    required String templateId,
    required Map<String, Object?> inputs,
  });
}

/// Calorie nutrition ocr repository.
@riverpod
CalorieNutritionOcrRepositoryContract calorieNutritionOcrRepository(Ref ref) {
  final imagePicker = ref.watch(calorieNutritionImagePickerProvider);
  return _FirebaseCalorieNutritionOcrRepository(
    imagePicker: imagePicker,
    configClient: ref.watch(calorieNutritionTemplateConfigClientProvider),
    modelClient: ref.watch(calorieNutritionTemplateModelClientProvider),
  );
}

/// Calorie nutrition image picker.
@riverpod
ImagePicker calorieNutritionImagePicker(Ref ref) {
  return ImagePicker();
}

/// Calorie nutrition template config client.
@riverpod
CalorieNutritionTemplateConfigClient calorieNutritionTemplateConfigClient(
  Ref ref,
) {
  return const _StaticCalorieNutritionTemplateConfigClient(
    templateId: _ocrTemplateId,
  );
}

/// Calorie nutrition template model client.
@riverpod
CalorieNutritionTemplateModelClient calorieNutritionTemplateModelClient(
  Ref ref,
) {
  return _FirebaseCalorieNutritionTemplateModelClient(
    model: FirebaseAI.vertexAI(
      location: _vertexLocation,
    ).templateGenerativeModel(),
  );
}

class _StaticCalorieNutritionTemplateConfigClient
    implements CalorieNutritionTemplateConfigClient {
  const _StaticCalorieNutritionTemplateConfigClient({required this.templateId});

  final String templateId;

  @override
  Future<String> loadTemplateId() async {
    return templateId;
  }
}

class _FirebaseCalorieNutritionTemplateModelClient
    implements CalorieNutritionTemplateModelClient {
  _FirebaseCalorieNutritionTemplateModelClient({
    required TemplateGenerativeModel model,
  }) : _model = model;

  final TemplateGenerativeModel _model;

  @override
  Future<String?> generateContent({
    required String templateId,
    required Map<String, Object?> inputs,
  }) async {
    final response = await _model.generateContent(templateId, inputs: inputs);
    return response.text;
  }
}

class _FirebaseCalorieNutritionOcrRepository
    implements CalorieNutritionOcrRepositoryContract {
  _FirebaseCalorieNutritionOcrRepository({
    required ImagePicker imagePicker,
    required CalorieNutritionTemplateConfigClient configClient,
    required CalorieNutritionTemplateModelClient modelClient,
    DateTime Function()? now,
  }) : _imagePicker = imagePicker,
       _configClient = configClient,
       _modelClient = modelClient,
       _now = now ?? DateTime.now;

  final ImagePicker _imagePicker;
  final CalorieNutritionTemplateConfigClient _configClient;
  final CalorieNutritionTemplateModelClient _modelClient;
  final DateTime Function() _now;

  @override
  Future<CalorieNutritionOcrResult> scanNutritionLabel({
    required String barcode,
  }) async {
    log(
      'Starting nutrition label OCR for barcode $barcode.',
      name: _ocrLogName,
    );
    if (!_isCameraSupported()) {
      log('Nutrition label OCR not supported on platform.', name: _ocrLogName);
      return const CalorieNutritionOcrResult.failed(
        errorCode: CalorieNutritionOcrErrorCodes.cameraNotSupported,
      );
    }

    try {
      final image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image == null) {
        log(
          'Nutrition label OCR canceled before image capture.',
          name: _ocrLogName,
        );
        return const CalorieNutritionOcrResult.canceled();
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
        return const CalorieNutritionOcrResult.failed(
          errorCode: CalorieNutritionOcrErrorCodes.templateConfigFailed,
        );
      }

      log('Calling OCR model with template "$templateId".', name: _ocrLogName);
      final responseText = await _modelClient.generateContent(
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
        return const CalorieNutritionOcrResult.failed(
          errorCode: CalorieNutritionOcrErrorCodes.parseFailed,
        );
      }
      final profile = draft.toProfile(now: _now());
      if (profile == null) {
        log(
          'Nutrition label OCR returned partial values for barcode $barcode. '
          'kcal=${draft.per100Kcal}',
          name: _ocrLogName,
        );
      } else {
        log(
          'Nutrition label OCR succeeded for barcode $barcode. '
          'kcal=${profile.per100Kcal}',
          name: _ocrLogName,
        );
      }
      return CalorieNutritionOcrResult.succeeded(
        profile: profile,
        draft: draft,
      );
    } on Exception catch (error, stackTrace) {
      log(
        'OCR nutrition label failed for barcode $barcode.',
        name: _ocrLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const CalorieNutritionOcrResult.failed(
        errorCode: CalorieNutritionOcrErrorCodes.aiRequestFailed,
      );
    }
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
      final templateId = await _configClient.loadTemplateId();
      log('Resolved OCR template id: $templateId', name: _ocrLogName);
      return templateId;
    } catch (error, stackTrace) {
      log(
        'Failed to load OCR template id.',
        name: _ocrLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  CalorieNutritionOcrDraft? _parseDraft(
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

    final draft = CalorieNutritionOcrDraft(
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
    final decoded = jsonDecode(cleaned);
    if (decoded is Map<String, dynamic>) {
      return decoded;
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
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
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
      final value = payload[key];
      final parsed = _toDouble(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  double? _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is! String) {
      return null;
    }
    final normalized = value.replaceAll(',', '.').trim();
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  String _detectMimeType({required String fileName, required List<int> bytes}) {
    final length = bytes.length < _lookupHeaderLength
        ? bytes.length
        : _lookupHeaderLength;
    final header = bytes.sublist(0, length);
    final mime = lookupMimeType(fileName, headerBytes: header);
    if (mime == null || mime.isEmpty) {
      return _defaultMimeType;
    }
    return mime;
  }
}
