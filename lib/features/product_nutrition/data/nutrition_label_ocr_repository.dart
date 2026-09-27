import 'dart:convert';
import 'dart:developer' show log;

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/product_nutrition/domain/'
    'nutrition_label_ocr_models.dart';

part 'nutrition_label_ocr_repository.g.dart';

const _ocrLogName = 'NutritionLabelOcrRepository';

/// Firebase AI server prompt template that reads nutrition labels.
///
/// The prompt, model, and output schema live on the server, so they can
/// change without an app release.
const nutritionLabelTemplateId = 'nutrition-label-template';

/// Defines nutrition label OCR error codes.
abstract final class NutritionLabelOcrErrorCodes {
  /// The AI request failed.
  static const aiRequestFailed = 'ocr_ai_request_failed';

  /// Firebase App Check temporarily blocked the AI request.
  static const appCheckThrottled = 'ocr_app_check_throttled';

  /// The model answer was not valid JSON.
  static const parseFailed = 'ocr_parse_failed';

  /// The photo did not show every mandatory value clearly, or the values
  /// were implausible. A new photo can fix it.
  static const retakePhoto = 'ocr_retake_photo';
}

/// Runs [nutritionLabelTemplateId] with template [inputs] and returns the
/// response text.
typedef NutritionLabelTemplateModelClient = Future<String?> Function(
  Map<String, Object?> inputs,
);

/// Nutrition label OCR repository.
@riverpod
NutritionLabelOcrRepository nutritionLabelOcrRepository(Ref ref) {
  return NutritionLabelOcrRepository(
    modelClient: ref.watch(nutritionLabelTemplateModelClientProvider),
  );
}

/// Nutrition label template model client.
@riverpod
NutritionLabelTemplateModelClient nutritionLabelTemplateModelClient(Ref ref) {
  final model = FirebaseAI.googleAI().templateGenerativeModel();
  return (inputs) async {
    final response = await model.generateContent(
      nutritionLabelTemplateId,
      inputs: inputs,
    );
    return response.text;
  };
}

/// Scans nutrition labels with Firebase AI.
class NutritionLabelOcrRepository {
  /// Creates nutrition label OCR repository.
  new({required this._modelClient});

  final NutritionLabelTemplateModelClient _modelClient;

  /// Reads the nutrition label in the photo [imageBytes] of type
  /// [mimeType].
  Future<NutritionLabelOcrResult> readNutritionLabel({
    required Uint8List imageBytes,
    required String mimeType,
    required String barcode,
  }) async {
    log(
      'Reading nutrition label for barcode $barcode. '
      'mimeType=$mimeType bytes=${imageBytes.length}',
      name: _ocrLogName,
    );
    try {
      final responseText = await _modelClient(<String, Object?>{
        'mimeType': mimeType,
        'imageData': base64Encode(imageBytes),
      });
      if (kDebugMode) {
        log(
          'Raw nutrition label OCR response:\n${responseText ?? '<null>'}',
          name: _ocrLogName,
        );
      }
      return _resultFromResponse(responseText, barcode: barcode);
    } on Exception catch (error, stackTrace) {
      log(
        'OCR nutrition label failed for barcode $barcode.',
        name: _ocrLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return NutritionLabelOcrResult.failed(
        errorCode: _resolveScanErrorCode(error),
      );
    }
  }

  NutritionLabelOcrResult _resultFromResponse(
    String? responseText, {
    required String barcode,
  }) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(responseText ?? '') as Map<String, dynamic>;
    } on FormatException {
      log('Nutrition label OCR response is not JSON.', name: _ocrLogName);
      return const NutritionLabelOcrResult.failed(
        errorCode: NutritionLabelOcrErrorCodes.parseFailed,
      );
    }

    final draft = _draftFromJson(json, barcode: barcode);
    if (draft == null || !draft.isPlausible) {
      log(
        'Nutrition label OCR rejected: status=${json['status']} '
        'complete=${draft != null}',
        name: _ocrLogName,
      );
      return const NutritionLabelOcrResult.failed(
        errorCode: NutritionLabelOcrErrorCodes.retakePhoto,
      );
    }
    log(
      'Nutrition label OCR succeeded for barcode $barcode. '
      'kcal=${draft.per100Kcal}',
      name: _ocrLogName,
    );
    return NutritionLabelOcrResult.succeeded(draft: draft);
  }

  /// Returns null unless the model reports `ok` and every mandatory value.
  NutritionLabelOcrDraft? _draftFromJson(
    Map<String, dynamic> json, {
    required String barcode,
  }) {
    final nutrition = json['nutrition'] as Map<String, dynamic>?;
    if (json['status'] != 'ok' || nutrition == null) return null;

    double? value(String key) => (nutrition[key] as num?)?.toDouble();
    final kj = value('kj');
    final kcal = value('kcal');
    final fat = value('fat');
    final saturatedFat = value('saturated_fat');
    final carbs = value('carbs');
    final sugar = value('sugar');
    final protein = value('protein');
    final salt = value('salt');
    if (kj == null ||
        kcal == null ||
        fat == null ||
        saturatedFat == null ||
        carbs == null ||
        sugar == null ||
        protein == null ||
        salt == null) {
      return null;
    }

    return NutritionLabelOcrDraft(
      barcode: barcode,
      name: json['name'] as String?,
      brand: json['brand'] as String?,
      quantityLabel: json['quantity_label'] as String?,
      servingSizeLabel: json['serving_size'] as String?,
      per100Kj: kj,
      per100Kcal: kcal,
      per100Fat: fat,
      per100SaturatedFat: saturatedFat,
      per100Carbs: carbs,
      per100Sugar: sugar,
      per100Protein: protein,
      per100Salt: salt,
      per100PolyunsaturatedFat: value('polyunsaturated_fat'),
      per100Fiber: value('fiber'),
    );
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
}
