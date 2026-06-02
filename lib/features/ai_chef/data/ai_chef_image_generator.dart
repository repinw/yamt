import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

const _imageLogName = 'AiChefImageGenerator';
const _location = 'global';
const _imageTimeout = Duration(seconds: 60);

/// Generates AI Chef cover images and stores them in Firebase Storage.
class AiChefImageGenerator {
  /// Creates image generator.
  AiChefImageGenerator({
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  }) : _storage = storage,
       _auth = auth;

  final FirebaseStorage? _storage;
  final FirebaseAuth? _auth;

  /// Generates and uploads cover image for a meal.
  Future<String?> generateCoverImageUrl({
    required String mealId,
    required String imagePrompt,
  }) async {
    final storage = _storage;
    if (storage == null) {
      return null;
    }

    try {
      log(
        'Requesting image generation for prompt: "$imagePrompt"...',
        name: _imageLogName,
      );
      final imageBytes = await _generateImageBytes(imagePrompt);
      if (imageBytes == null) {
        return null;
      }

      return _uploadImageBytes(
        storage: storage,
        mealId: mealId,
        imageBytes: imageBytes,
      );
    } on Object catch (error, stackTrace) {
      log(
        'Image generation/upload failed, returning recipe text only.',
        name: _imageLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<Uint8List?> _generateImageBytes(String imagePrompt) async {
    final model = FirebaseAI.vertexAI(location: _location).generativeModel(
      model: 'gemini-3.1-flash-image',
      generationConfig: GenerationConfig(
        responseModalities: [
          ResponseModalities.text,
          ResponseModalities.image,
        ],
      ),
    );

    final imageResponse = await model
        .generateContent(
          [Content.text(imagePrompt)],
          generationConfig: GenerationConfig(
            responseModalities: [
              ResponseModalities.text,
              ResponseModalities.image,
            ],
            imageConfig: const ImageConfig(
              aspectRatio: ImageAspectRatio.square1x1,
            ),
          ),
        )
        .timeout(_imageTimeout);

    if (imageResponse.inlineDataParts.isEmpty) {
      log('Gemini image model returned no inline data.', name: _imageLogName);
      return null;
    }
    return imageResponse.inlineDataParts.first.bytes;
  }

  Future<String?> _uploadImageBytes({
    required FirebaseStorage storage,
    required String mealId,
    required Uint8List imageBytes,
  }) async {
    final userId = _auth?.currentUser?.uid;
    if (userId == null) {
      log(
        'Skipping image upload: user is not authenticated.',
        name: _imageLogName,
      );
      return null;
    }

    final storagePath = 'users/$userId/recipes/$mealId/images/cover.jpg';
    log(
      'Uploading generated image to storage: $storagePath...',
      name: _imageLogName,
    );
    final uploadResult = await storage
        .ref(storagePath)
        .putData(
          imageBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );

    final imageUrl = await uploadResult.ref.getDownloadURL();
    log('Image uploaded successfully: $imageUrl', name: _imageLogName);
    return imageUrl;
  }
}
