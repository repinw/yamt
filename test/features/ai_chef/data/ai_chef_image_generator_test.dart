import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_image_generator.dart';

class _RecordingImageStorageClient implements AiChefImageStorageClient {
  new({required this.canUpload});

  @override
  final bool canUpload;

  int uploadCount = 0;

  @override
  Future<String?> uploadJpeg({
    required String mealId,
    required Uint8List imageBytes,
  }) async {
    uploadCount += 1;
    return 'https://example.test/$mealId.jpg';
  }
}

class _PathRecordingStorage extends Fake implements FirebaseStorage {
  String? requestedPath;

  @override
  Reference ref([String? path]) {
    requestedPath = path;
    throw StateError('The test stops before the upload.');
  }
}

void main() {
  test(
    'generateCoverImageUrl returns null when image generation times out',
    () async {
      final storageClient = _RecordingImageStorageClient(canUpload: true);
      final generator = AiChefImageGenerator(
        imageBytesClient: (_) =>
            Future<Uint8List?>.error(TimeoutException('image timed out')),
        imageStorageClient: storageClient,
      );

      final result = await generator.generateCoverImageUrl(
        mealId: 'meal-1',
        imagePrompt: 'tomato pasta',
      );

      expect(result, isNull);
      expect(storageClient.uploadCount, 0);
    },
  );

  test(
    'generateCoverImageUrl skips generation when upload is unavailable',
    () async {
      var didGenerateBytes = false;
      final generator = AiChefImageGenerator(
        imageBytesClient: (_) async {
          didGenerateBytes = true;
          return Uint8List.fromList([1, 2, 3]);
        },
        imageStorageClient: _RecordingImageStorageClient(canUpload: false),
      );

      final result = await generator.generateCoverImageUrl(
        mealId: 'meal-1',
        imagePrompt: 'tomato pasta',
      );

      expect(result, isNull);
      expect(didGenerateBytes, isFalse);
    },
  );

  test(
    'firebase storage client skips upload without an active household',
    () async {
      const storageClient = FirebaseAiChefImageStorageClient();

      expect(storageClient.canUpload, isFalse);
      final result = await storageClient.uploadJpeg(
        mealId: 'meal-1',
        imageBytes: Uint8List.fromList([1, 2, 3]),
      );

      expect(result, isNull);
    },
  );

  test(
    'firebase storage client uploads the cover under the household',
    () async {
      final storage = _PathRecordingStorage();
      final storageClient = FirebaseAiChefImageStorageClient(
        storage: storage,
        householdId: 'household-1',
      );

      expect(storageClient.canUpload, isTrue);
      await expectLater(
        storageClient.uploadJpeg(
          mealId: 'meal-1',
          imageBytes: Uint8List.fromList([1, 2, 3]),
        ),
        throwsStateError,
      );
      expect(
        storage.requestedPath,
        'households/household-1/recipes/meal-1/images/cover.jpg',
      );
    },
  );
}
