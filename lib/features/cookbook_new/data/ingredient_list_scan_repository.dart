import 'dart:convert';
import 'dart:developer' show log;
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/device/document_scanner.dart';
import 'package:yamt/core/utils/photo_jpeg.dart';
import 'package:yamt/features/cookbook_new/domain/scanned_ingredient_list.dart';

part 'ingredient_list_scan_repository.g.dart';

/// Firebase AI server prompt template that reads the title, servings,
/// ingredient lines, and preparation steps of a recipe on photos.
///
/// The prompt, model, and output schema live on the server, so they can
/// change without an app release.
const ingredientListTemplateId = 'ingredient-list-template';

/// Firebase AI server prompt template that reads the title, servings,
/// ingredient lines, and preparation steps of a recipe pasted or shared as
/// text. It answers like [ingredientListTemplateId].
const recipeTextTemplateId = 'recipe-text-template';

/// The longest text, in characters, that goes to [recipeTextTemplateId]. A
/// longer one is rather a whole page or chat than a recipe.
const recipeTextCharacterLimit = 20000;

const _requestTimeout = Duration(seconds: 60);
const _maxPages = 3;
const _logName = 'IngredientListScanRepository';

/// Runs [ingredientListTemplateId] with template [inputs] and returns the
/// response text.
typedef IngredientListTemplateClient = Future<String?> Function(
  Map<String, Object?> inputs,
);

/// Ingredient list template client.
@riverpod
IngredientListTemplateClient ingredientListTemplateClient(Ref ref) {
  final model = FirebaseAI.googleAI().templateGenerativeModel();
  return (inputs) async {
    final response = await model
        .generateContent(ingredientListTemplateId, inputs: inputs)
        .timeout(_requestTimeout);
    return response.text;
  };
}

/// Recipe text template client: runs [recipeTextTemplateId].
@riverpod
IngredientListTemplateClient recipeTextTemplateClient(Ref ref) {
  final model = FirebaseAI.googleAI().templateGenerativeModel();
  return (inputs) async {
    final response = await model
        .generateContent(recipeTextTemplateId, inputs: inputs)
        .timeout(_requestTimeout);
    return response.text;
  };
}

/// Ingredient list scan repository.
@riverpod
IngredientListScanRepository ingredientListScanRepository(Ref ref) =>
    IngredientListScanRepository(
      templateClient: ref.watch(ingredientListTemplateClientProvider),
      textClient: ref.watch(recipeTextTemplateClientProvider),
    );

/// Takes photos of a recipe with the document scanner and reads its
/// ingredient lines and preparation steps, from the photos or from text,
/// with Firebase AI.
class IngredientListScanRepository {
  /// Creates the repository.
  new({required this._templateClient, required this._textClient});

  final IngredientListTemplateClient _templateClient;
  final IngredientListTemplateClient _textClient;

  /// Takes up to three pages with the document scanner, or photos from the
  /// gallery. Returns their paths, or `null` when the user cancels.
  Future<List<String>?> loadPagePhotos() async {
    final paths = await scanDocumentPages(
      maxPages: _maxPages,
      allowGallery: true,
    );
    return paths == null || paths.isEmpty ? null : paths;
  }

  /// Reads the recipe on the photos at [pagePaths], given in page order.
  /// Throws when the request fails or the answer has another shape.
  Future<ScannedIngredientList> loadIngredientList(
    List<String> pagePaths,
  ) async {
    final files = <Map<String, Object?>>[
      for (final path in pagePaths) await _fileInput(path),
    ];
    return _read(await _templateClient({'files': files}));
  }

  /// Reads the recipe in [text], as pasted or shared. Throws when the
  /// request fails or the answer has another shape.
  Future<ScannedIngredientList> loadRecipeText(String text) async =>
      _read(await _textClient({'text': text}));

  static ScannedIngredientList _read(String? text) {
    if (kDebugMode) {
      log('Raw ingredient list response:\n${text ?? '<null>'}', name: _logName);
    }
    if (text == null || text.trim().isEmpty) {
      throw const FormatException('Empty ingredient list response');
    }
    return ScannedIngredientList.fromJson(jsonDecode(text));
  }

  // Pages shrink one after another, so several full-size scans overflow
  // neither the request nor the memory.
  Future<Map<String, Object?>> _fileInput(String path) async {
    final jpeg = await compute(cleanPhotoJpeg, await File(path).readAsBytes());
    return {'mimeType': 'image/jpeg', 'data': base64Encode(jpeg)};
  }
}
