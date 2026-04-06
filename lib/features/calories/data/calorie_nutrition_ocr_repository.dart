// ignore_for_file: experimental_member_use

import 'dart:convert';
import 'dart:developer' show log;

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
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
const _ocrTemplateConfigKey = 'nutrition_label_template_id';
const _ocrTemplateIdFallback = 'testtemplate';
const _vertexLocation = 'global';
const _defaultMimeType = 'application/octet-stream';
const _lookupHeaderLength = 32;

abstract final class CalorieNutritionOcrErrorCodes {
  static const cameraNotSupported = 'ocr_camera_not_supported';
  static const cameraPickFailed = 'ocr_camera_pick_failed';
  static const templateConfigFailed = 'ocr_template_config_failed';
  static const aiRequestFailed = 'ocr_ai_request_failed';
  static const parseFailed = 'ocr_parse_failed';
}

@riverpod
ImagePicker calorieNutritionImagePicker(Ref ref) {
  return ImagePicker();
}

@riverpod
FirebaseRemoteConfig calorieNutritionRemoteConfig(Ref ref) {
  return FirebaseRemoteConfig.instance;
}

@riverpod
TemplateGenerativeModel calorieNutritionTemplateModel(Ref ref) {
  return FirebaseAI.vertexAI(
    location: _vertexLocation,
  ).templateGenerativeModel();
}

@riverpod
CalorieNutritionOcrRepositoryContract calorieNutritionOcrRepository(Ref ref) {
  return _FirebaseCalorieNutritionOcrRepository(
    imagePicker: ref.watch(calorieNutritionImagePickerProvider),
    remoteConfig: ref.watch(calorieNutritionRemoteConfigProvider),
    model: ref.watch(calorieNutritionTemplateModelProvider),
  );
}

class _FirebaseCalorieNutritionOcrRepository
    implements CalorieNutritionOcrRepositoryContract {
  _FirebaseCalorieNutritionOcrRepository({
    required ImagePicker imagePicker,
    required FirebaseRemoteConfig remoteConfig,
    required TemplateGenerativeModel model,
    DateTime Function()? now,
  }) : _imagePicker = imagePicker,
       _remoteConfig = remoteConfig,
       _model = model,
       _now = now ?? DateTime.now;

  final ImagePicker _imagePicker;
  final FirebaseRemoteConfig _remoteConfig;
  final TemplateGenerativeModel _model;
  final DateTime Function() _now;
  Future<void>? _remoteConfigInitialization;

  @override
  Future<CalorieNutritionOcrResult> scanNutritionLabel({
    required String barcode,
  }) async {
    if (!_isCameraSupported()) {
      return const CalorieNutritionOcrResult.failed(
        errorCode: CalorieNutritionOcrErrorCodes.cameraNotSupported,
      );
    }

    try {
      final image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image == null) {
        return const CalorieNutritionOcrResult.canceled();
      }

      final bytes = await image.readAsBytes();
      final mimeType = _detectMimeType(fileName: image.name, bytes: bytes);
      final templateId = await _loadTemplateId();
      if (templateId == null) {
        return const CalorieNutritionOcrResult.failed(
          errorCode: CalorieNutritionOcrErrorCodes.templateConfigFailed,
        );
      }

      final response = await _model.generateContent(
        templateId,
        inputs: <String, Object?>{
          'mimeType': mimeType,
          'imageData': base64Encode(bytes),
        },
      );
      final profile = _parseProfile(response.text, barcode: barcode);
      if (profile == null) {
        return const CalorieNutritionOcrResult.failed(
          errorCode: CalorieNutritionOcrErrorCodes.parseFailed,
        );
      }
      return CalorieNutritionOcrResult.succeeded(profile: profile);
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
      await _ensureRemoteConfigInitialized();
      final templateId = _remoteConfig.getString(_ocrTemplateConfigKey).trim();
      if (templateId.isEmpty) {
        return _ocrTemplateIdFallback;
      }
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

  Future<void> _ensureRemoteConfigInitialized() {
    final current = _remoteConfigInitialization;
    if (current != null) {
      return current;
    }

    final initialized = _initializeRemoteConfig();
    _remoteConfigInitialization = initialized;
    return initialized;
  }

  Future<void> _initializeRemoteConfig() async {
    await _remoteConfig.setDefaults(const <String, Object>{
      _ocrTemplateConfigKey: _ocrTemplateIdFallback,
    });
    await _remoteConfig.fetchAndActivate();
  }

  CalorieProductProfile? _parseProfile(
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

    if ((name == null || name.isEmpty) && kcal <= 0) {
      return null;
    }

    final now = _now();
    return CalorieProductProfile(
      barcode: barcode,
      name: name?.trim().isNotEmpty == true ? name!.trim() : barcode,
      brand: brand?.trim().isNotEmpty == true ? brand!.trim() : null,
      per100Kcal: kcal,
      per100Protein: protein,
      per100Carbs: carbs,
      per100Fat: fat,
      source: CalorieProductSource.ocr,
      offProductId: null,
      createdAt: now,
      updatedAt: now,
    );
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

  double _extractDouble(Map<String, Object?> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      final parsed = _toDouble(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return 0;
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
