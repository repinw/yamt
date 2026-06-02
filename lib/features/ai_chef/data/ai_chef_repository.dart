// Firebase AI template APIs are still marked experimental in current package.
// ignore_for_file: experimental_member_use

import 'dart:developer' show log;

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/provider/firebase_storage_provider.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_image_generator.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_recipe_draft.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_recipe_response_parser.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

part 'ai_chef_repository.g.dart';

const _logName = 'AiChefRepository';
const _templateId = 'ai-chef-template';
const _location = 'global';
const _timeout = Duration(seconds: 30);

/// Calls the Firebase AI Chef template model.
typedef AiChefTemplateModelClient =
    Future<String?> Function({
      required String templateId,
      required Map<String, Object?> inputs,
    });

/// Firebase AI Chef repository provider.
@riverpod
FirebaseAiChefRepository aiChefRepository(Ref ref) {
  final storage = ref.watch(firebaseStorageProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return FirebaseAiChefRepository(storage: storage, auth: auth);
}

/// Repository managing recipe generation using Firebase Vertex AI templates.
class FirebaseAiChefRepository {
  /// Creates an instance.
  FirebaseAiChefRepository({
    FirebaseStorage? storage,
    FirebaseAuth? auth,
    AiChefRecipeResponseParser parser = const AiChefRecipeResponseParser(),
    AiChefImageGenerator? imageGenerator,
    AiChefTemplateModelClient? templateModelClient,
  }) : _parser = parser,
       _imageGenerator =
           imageGenerator ?? AiChefImageGenerator(storage: storage, auth: auth),
       _templateModelClient =
           templateModelClient ?? _firebaseAiChefTemplateClient;

  final AiChefRecipeResponseParser _parser;
  final AiChefImageGenerator _imageGenerator;
  final AiChefTemplateModelClient _templateModelClient;
  static const _uuid = Uuid();

  /// Generates a recipe using the configured Firebase Vertex AI template.
  /// Returns null if generation, parsing, or server connection fails.
  Future<PreparedMeal?> generateAiRecipe({
    required String languageCode,
    required String seed,
    List<String> inventoryIngredients = const [],
  }) async {
    try {
      final inventoryString = inventoryIngredients.join('\n');

      log(
        'Requesting recipe from Firebase AI '
        'with lang: $languageCode, seed: $seed, '
        'inventoryItems: ${inventoryIngredients.length}...',
        name: _logName,
      );

      final rawText = await _templateModelClient(
        templateId: _templateId,
        inputs: <String, Object?>{
          'language': languageCode,
          'seed': seed,
          'inventory': inventoryString,
        },
      ).timeout(_timeout);
      log('Raw AI Response received: $rawText', name: _logName);

      if (rawText == null || rawText.trim().isEmpty) {
        return null;
      }

      final draft = _parser.parse(rawText);
      if (draft == null) {
        log('Failed to parse generated recipe JSON.', name: _logName);
        return null;
      }

      return _buildMeal(draft);
    } on Object catch (error, stackTrace) {
      log(
        'Firebase AI recipe generation failed.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<PreparedMeal> _buildMeal(AiChefRecipeDraft draft) async {
    final mealId = _uuid.v4();
    final imagePrompt = draft.imagePrompt;
    final imageUrl = imagePrompt == null
        ? null
        : await _imageGenerator.generateCoverImageUrl(
            mealId: mealId,
            imagePrompt: imagePrompt,
          );
    final now = DateTime.now();
    return PreparedMeal(
      id: mealId,
      name: draft.name,
      totalPortions: draft.portions,
      remainingPortions: draft.portions,
      totalKcal: draft.kcal,
      totalProtein: draft.protein,
      totalCarbs: draft.carbs,
      totalFat: draft.fat,
      createdAt: now,
      updatedAt: now,
      components: const [],
      recipeIngredients: draft.ingredients,
      recipeInstructions: draft.instructions,
      imageUrl: imageUrl,
    );
  }
}

Future<String?> _firebaseAiChefTemplateClient({
  required String templateId,
  required Map<String, Object?> inputs,
}) async {
  final model = FirebaseAI.vertexAI(
    location: _location,
  ).templateGenerativeModel();
  final response = await model.generateContent(templateId, inputs: inputs);
  return response.text;
}
