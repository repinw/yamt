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
const _ocrTemplateIdFallback = 'nutritionlabelocr';
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

abstract interface class CalorieNutritionTemplateConfigClient {
  Future<String> loadTemplateId();
}

abstract interface class CalorieNutritionTemplateModelClient {
  Future<String?> generateContent({
    required String templateId,
    required Map<String, Object?> inputs,
  });
}

@riverpod
CalorieNutritionOcrRepositoryContract calorieNutritionOcrRepository(Ref ref) {
  final imagePicker = ref.watch(calorieNutritionImagePickerProvider);
  return FirebaseCalorieNutritionOcrRepository(
    imagePicker: imagePicker,
    configClient: ref.watch(calorieNutritionTemplateConfigClientProvider),
    modelClient: ref.watch(calorieNutritionTemplateModelClientProvider),
  );
}

@riverpod
ImagePicker calorieNutritionImagePicker(Ref ref) {
  return ImagePicker();
}

@riverpod
CalorieNutritionTemplateConfigClient calorieNutritionTemplateConfigClient(
  Ref ref,
) {
  return FirebaseCalorieNutritionTemplateConfigClient(
    remoteConfig: FirebaseRemoteConfig.instance,
  );
}

@riverpod
CalorieNutritionTemplateModelClient calorieNutritionTemplateModelClient(
  Ref ref,
) {
  return FirebaseCalorieNutritionTemplateModelClient(
    model: FirebaseAI.vertexAI(
      location: _vertexLocation,
    ).templateGenerativeModel(),
  );
}

class FirebaseCalorieNutritionTemplateConfigClient
    implements CalorieNutritionTemplateConfigClient {
  FirebaseCalorieNutritionTemplateConfigClient({
    required FirebaseRemoteConfig remoteConfig,
  }) : _remoteConfig = remoteConfig;

  final FirebaseRemoteConfig _remoteConfig;
  Future<void>? _initialization;

  @override
  Future<String> loadTemplateId() async {
    await _ensureInitialized();
    final templateId = _remoteConfig.getString(_ocrTemplateConfigKey);
    if (templateId.trim().isEmpty) {
      return _ocrTemplateIdFallback;
    }
    return templateId;
  }

  Future<void> _ensureInitialized() {
    final current = _initialization;
    if (current != null) {
      return current;
    }
    final initialized = _initializeRemoteConfig();
    _initialization = initialized;
    return initialized;
  }

  Future<void> _initializeRemoteConfig() async {
    await _remoteConfig.setDefaults(const <String, Object>{
      _ocrTemplateConfigKey: _ocrTemplateIdFallback,
    });
    await _remoteConfig.fetchAndActivate();
  }
}

class FirebaseCalorieNutritionTemplateModelClient
    implements CalorieNutritionTemplateModelClient {
  FirebaseCalorieNutritionTemplateModelClient({
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

class FirebaseCalorieNutritionOcrRepository
    implements CalorieNutritionOcrRepositoryContract {
  FirebaseCalorieNutritionOcrRepository({
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

      final responseText = await _modelClient.generateContent(
        templateId: templateId,
        inputs: <String, Object?>{
          'mimeType': mimeType,
          'imageData': base64Encode(bytes),
        },
      );
      final profile = _parseProfile(responseText, barcode: barcode);
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
      return await _configClient.loadTemplateId();
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
      'name',
      'product_name',
      'title',
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

    if ((name == null || name.isEmpty) && kcal <= 0) {
      return null;
    }

    final now = _now();
    return CalorieProductProfile(
      barcode: barcode,
      name: name?.trim().isNotEmpty == true ? name!.trim() : barcode,
      brand: null,
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
