import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:yamt/features/ai_chef/data/ai_chef_image_generator.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_repository.dart';

import 'fake_firebase_storage.dart';

/// A valid 1x1 PNG, the picture the fake image model makes.
final Uint8List fakePictureBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGA'
  'hKmMIQAAAABJRU5ErkJggg==',
);

/// The answer of the recipe idea template for a pasta dish: two portions,
/// and one ingredient line per entry of [lines].
String recipeIdeaAnswer({
  String name = 'Tomatenpasta',
  List<String> lines = const ['200 g Pasta', '100 g Tomaten'],
  List<String> steps = const ['Pasta kochen.', 'Sauce dazugeben.'],
}) => jsonEncode({
  'name': name,
  'portions': 2,
  'ingredients': [
    for (final line in lines)
      {
        'text': line,
        'amount': 100,
        'unit': 'g',
        'kcal': 300,
        'protein': 10,
        'carbs': 40,
        'fat': 7,
      },
  ],
  'instructions': steps,
  'image_prompt': 'a plate of pasta',
});

/// Stands in for the AI recipe idea services: the template answers after a
/// real asynchronous gap, the picture and the cover upload can be held back
/// or failed, and every call is counted.
class FakeAiChef {
  /// Creates the fake; [answer] is what the template says.
  new({String? answer}) : answer = answer ?? recipeIdeaAnswer();

  /// What the template answers.
  String? answer;

  /// Whether the template request throws.
  bool templateFails = false;

  /// Whether the picture request throws.
  bool pictureFails = false;

  /// Whether the cover upload throws.
  bool get uploadFails => storage.uploadError != null;
  set uploadFails(bool value) =>
      storage.uploadError = value ? Exception('upload failed') : null;

  /// Holds the picture back until completed, when set.
  Completer<void>? pictureHold;

  /// How often the template was asked.
  int templateCalls = 0;

  /// How often a picture was requested.
  int pictureCalls = 0;

  /// The storage the covers are uploaded to.
  final storage = FakeFirebaseStorage();

  /// The storage path of the cover of the recipe [recipeId].
  static String coverPath(String recipeId) =>
      'households/household-1/recipes/$recipeId/images/cover.jpg';

  /// The paths of the uploaded covers.
  List<String> get uploads => storage.uploads;

  /// The repository to override `aiChefRepositoryProvider` with.
  late final repository = FirebaseAiChefRepository(
    storage: storage,
    householdId: 'household-1',
    templateModelClient: ({required templateId, required inputs}) async {
      templateCalls += 1;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      if (templateFails) throw Exception('offline');
      return answer;
    },
  );

  /// The generator to override `aiChefImageGeneratorProvider` with.
  late final imageGenerator = AiChefImageGenerator(
    imageBytesClient: (_) async {
      pictureCalls += 1;
      await pictureHold?.future;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      if (pictureFails) throw Exception('no picture');
      return fakePictureBytes;
    },
  );
}
