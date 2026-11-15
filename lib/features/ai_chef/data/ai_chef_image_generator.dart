import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ai_chef_image_generator.g.dart';

const _imageLogName = 'AiChefImageGenerator';
const _imageTimeout = Duration(seconds: 60);

/// Generates image bytes from a text prompt.
typedef AiChefImageBytesClient = Future<Uint8List?> Function(String prompt);

/// The image generator. It depends on nothing that changes, so a picture
/// that is being made is never asked for a second time.
@riverpod
AiChefImageGenerator aiChefImageGenerator(Ref ref) => AiChefImageGenerator();

/// Generates the picture of a recipe idea with the Firebase AI image model.
class AiChefImageGenerator {
  /// Creates image generator.
  new({this._imageBytesClient});

  final AiChefImageBytesClient? _imageBytesClient;

  /// Generates the picture for [imagePrompt]. Throws when the image model
  /// gives none, fails, or takes too long.
  Future<Uint8List> generate(String imagePrompt) async {
    log(
      'Requesting image generation for prompt: "$imagePrompt"...',
      name: _imageLogName,
    );
    final imageBytes = await _generateImageBytes(imagePrompt);
    if (imageBytes == null) {
      throw StateError('The image model returned no picture.');
    }
    return imageBytes;
  }

  Future<Uint8List?> _generateImageBytes(String imagePrompt) async {
    final imageBytesClient = _imageBytesClient;
    if (imageBytesClient != null) {
      return await imageBytesClient(imagePrompt).timeout(_imageTimeout);
    }

    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-nano-banana-2.1',
      generationConfig: GenerationConfig(
        responseModalities: [ResponseModalities.text, ResponseModalities.image],
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
}
