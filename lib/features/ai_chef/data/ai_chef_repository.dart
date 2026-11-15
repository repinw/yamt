import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/firebase_storage_provider.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_recipe_response_parser.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'ai_chef_repository.g.dart';

const _logName = 'AiChefRepository';
const _templateId = 'recipe-idea-template';
// The template runs on a medium-thinking model: about 19 s, up to 27 s seen.
const _timeout = Duration(seconds: 60);

/// Calls the Firebase AI Chef template model.
typedef AiChefTemplateModelClient = Future<String?> Function({
  required String templateId,
  required Map<String, Object?> inputs,
});

/// A recipe idea: the unsaved recipe with its estimate and line weights,
/// and the prompt for its picture, which comes later
/// (`aiChefImageGeneratorProvider`).
typedef AiChefRecipeIdea = ({PreparedMeal recipe, String imagePrompt});

/// Firebase AI Chef repository provider.
@riverpod
FirebaseAiChefRepository aiChefRepository(Ref ref) {
  final storage = ref.watch(firebaseStorageProvider);
  final householdId = ref.watch(householdCipherProvider)?.householdId;
  return FirebaseAiChefRepository(storage: storage, householdId: householdId);
}

/// Repository managing recipe generation using a Firebase AI server prompt
/// template.
class FirebaseAiChefRepository {
  /// Creates an instance.
  new({
    this._storage,
    this._householdId,
    this._parser = const AiChefRecipeResponseParser(),
    AiChefTemplateModelClient? templateModelClient,
  }) : _templateModelClient =
           templateModelClient ?? _firebaseAiChefTemplateClient;

  final FirebaseStorage? _storage;
  final String? _householdId;
  final AiChefRecipeResponseParser _parser;
  final AiChefTemplateModelClient _templateModelClient;

  /// Asks the template `recipe-idea-template` for a recipe in
  /// [languageCode] with the topic and wishes [seed], from the formatted
  /// Vorrat [inventoryIngredients], made at [now]. The recipe contains each
  /// of [mustUseIngredients] (Vorrat entries in the same form) and never one
  /// of [excludedIngredients]. The picture is not waited for: the image
  /// generator makes it from the idea's prompt.
  /// Throws when the request fails or takes longer than 60 seconds; a
  /// [FormatException] says the answer cannot be used.
  Future<AiChefRecipeIdea> loadRecipeIdea({
    required String languageCode,
    required String seed,
    required DateTime now,
    List<String> inventoryIngredients = const [],
    List<String> excludedIngredients = const [],
    List<String> mustUseIngredients = const [],
  }) async {
    log(
      'Requesting recipe from Firebase AI '
      'with lang: $languageCode, seed: $seed, '
      'inventoryItems: ${inventoryIngredients.length}, '
      'excluded: ${excludedIngredients.length}, '
      'mustUse: ${mustUseIngredients.length}...',
      name: _logName,
    );
    final rawText = await _templateModelClient(
      templateId: _templateId,
      inputs: <String, Object?>{
        'language': languageCode,
        'seed': seed,
        'inventory': inventoryIngredients.join('\n'),
        if (excludedIngredients.isNotEmpty)
          'excluded_ingredients': excludedIngredients.join('\n'),
        if (mustUseIngredients.isNotEmpty)
          'must_use_ingredients': mustUseIngredients.join('\n'),
      },
    ).timeout(_timeout);
    log('Raw AI Response received: $rawText', name: _logName);
    if (rawText == null || rawText.trim().isEmpty) {
      throw const FormatException('Empty recipe idea response');
    }
    return _parser.parse(rawText, now: now);
  }

  /// Stores the picture [bytes] as the cover of the saved recipe [recipeId]
  /// and returns its link. Throws a [StateError] when signed out or without
  /// a household key, and the upload's error when it fails.
  Future<String> saveCover({
    required String recipeId,
    required Uint8List bytes,
  }) async {
    final storage = _storage;
    final householdId = _householdId;
    if (storage == null || householdId == null) {
      throw StateError('No household key or storage for the cover image.');
    }
    final cover = storage.ref(
      'households/$householdId/recipes/$recipeId/images/cover.jpg',
    );
    await cover.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await cover.getDownloadURL();
    log('Cover of $recipeId uploaded: $url', name: _logName);
    return url;
  }
}

Future<String?> _firebaseAiChefTemplateClient({
  required String templateId,
  required Map<String, Object?> inputs,
}) async {
  final model = FirebaseAI.googleAI().templateGenerativeModel();
  final response = await model.generateContent(templateId, inputs: inputs);
  return response.text;
}
