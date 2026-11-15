import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/cookbook_new/application/recipe_estimate_service.dart';
import 'package:yamt/features/cookbook_new/data/'
    'ingredient_list_scan_repository.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_editor_draft.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_lines.dart';
import 'package:yamt/features/cookbook_new/domain/scanned_ingredient_list.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'recipe_editor_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'recipe_editor_state.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';

import '../../../../helpers/fake_prepared_meal_template_repository.dart';

final _now = DateTime.utc(2026, 11, 7, 12);

PreparedMeal _recipe({
  List<String> ingredients = const ['1 Zwiebel', '200 g Mehl'],
  Map<String, RecipeLineWeight> weights = const {},
}) => PreparedMeal(
  id: 'recipe-1',
  name: 'Brot',
  totalPortions: 2,
  remainingPortions: 2,
  totalKcal: 0,
  totalProtein: 0,
  totalCarbs: 0,
  totalFat: 0,
  createdAt: DateTime.utc(2026, 11),
  updatedAt: DateTime.utc(2026, 11),
  components: const [],
  recipeIngredients: ingredients,
  recipeInstructions: const ['Kneten'],
  recipeLineWeights: weights,
);

const _aiWeight = RecipeLineWeight(
  amount: 150,
  unit: RecipeLineWeightUnit.gram,
  source: RecipeLineWeightSource.ai,
);

class _FakeScanRepository implements IngredientListScanRepository {
  new({
    this.pages = const ['page.jpg'],
    this.scanned,
    this.failure,
    this.textAnswer,
  });

  /// What [loadRecipeText] answers; it throws when `null`.
  ScannedIngredientList? textAnswer;
  final readTexts = <String>[];

  /// What the scanner returns; `null` is a canceled scan.
  List<String>? pages;
  ScannedIngredientList? scanned;

  /// Thrown by [loadPagePhotos] when set.
  Exception? failure;

  /// Thrown by [loadIngredientList] when set.
  Exception? readFailure;
  List<String>? readPages;

  @override
  Future<List<String>?> loadPagePhotos() async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    if (failure != null) throw failure!;
    return pages;
  }

  @override
  Future<ScannedIngredientList> loadIngredientList(
    List<String> pagePaths,
  ) async {
    readPages = pagePaths;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    if (readFailure != null) throw readFailure!;
    return scanned!;
  }

  @override
  Future<ScannedIngredientList> loadRecipeText(String text) async {
    readTexts.add(text);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return textAnswer ?? (throw const FormatException('offline'));
  }
}

class _FakePicker implements PreparedMealImagePicker {
  new({this.bytes, this.camera = true});

  Uint8List? bytes;
  bool fails = false;
  bool camera;
  final picks = <String>[];

  @override
  bool get supportsCamera => camera;

  @override
  Future<Uint8List?> pickFromCamera() async {
    picks.add('camera');
    if (fails) throw StateError('no camera');
    return bytes;
  }

  @override
  Future<Uint8List?> pickFromFile() async {
    picks.add('file');
    if (fails) throw StateError('no file');
    return bytes;
  }
}

class _FakeImageStore implements LocalImageStore {
  final saved = <LocalImageRef, Uint8List>{};

  /// When set, [saveBytes] waits for it.
  Completer<void>? hold;

  @override
  Future<void> saveBytes({
    required LocalImageRef imageRef,
    required Uint8List bytes,
  }) async {
    await hold?.future;
    saved[imageRef] = bytes;
  }

  @override
  Future<Uint8List?> readBytes(LocalImageRef imageRef) async => saved[imageRef];

  @override
  Future<void> deleteImage(LocalImageRef imageRef) async =>
      saved.remove(imageRef);

  @override
  Future<void> copyImage({
    required LocalImageRef sourceRef,
    required LocalImageRef targetRef,
  }) async {}
}

class _RecordingEstimates implements RecipeEstimateService {
  final started = <String>[];

  @override
  void estimateInBackground(String recipeId) => started.add(recipeId);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Setup {
  new({
    List<PreparedMeal> recipes = const [],
    _FakeScanRepository? scans,
    _FakePicker? picker,
  }) : templates = FakePreparedMealTemplateRepository(templates: recipes),
       scans = scans ?? _FakeScanRepository(),
       picker = picker ?? _FakePicker(),
       images = _FakeImageStore(),
       estimates = _RecordingEstimates() {
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => _now),
        preparedMealTemplateRepositoryProvider.overrideWithValue(templates),
        ingredientListScanRepositoryProvider.overrideWithValue(this.scans),
        preparedMealImagePickerProvider.overrideWithValue(this.picker),
        localImageStoreProvider.overrideWithValue(images),
        recipeEstimateServiceProvider.overrideWithValue(estimates),
      ],
    );
    addTearDown(container.dispose);
  }

  final FakePreparedMealTemplateRepository templates;
  final _FakeScanRepository scans;
  final _FakePicker picker;
  final _FakeImageStore images;
  final _RecordingEstimates estimates;
  late final ProviderContainer container;

  final _states = <String?, List<AsyncValue<RecipeEditorState?>>>{};

  /// Listens to the editor of [recipeId] once, so its state survives, and
  /// returns every state it had.
  List<AsyncValue<RecipeEditorState?>> open([String? recipeId]) =>
      _states.putIfAbsent(recipeId, () {
        final states = <AsyncValue<RecipeEditorState?>>[];
        container.listen(
          recipeEditorControllerProvider(recipeId ?? 'new', recipeId),
          (_, next) => states.add(next),
          fireImmediately: true,
        );
        return states;
      });

  RecipeEditorController controller([String? recipeId]) {
    open(recipeId);
    return container.read(
      recipeEditorControllerProvider(recipeId ?? 'new', recipeId).notifier,
    );
  }

  RecipeEditorState? editor([String? recipeId]) {
    open(recipeId);
    return container
        .read(recipeEditorControllerProvider(recipeId ?? 'new', recipeId))
        .value;
  }

  RecipeEditorDraft? draft([String? recipeId]) => editor(recipeId)?.draft;

  /// Waits until the editor of [recipeId] has loaded.
  Future<void> loaded(String recipeId) {
    open(recipeId);
    return container.read(
      recipeEditorControllerProvider(recipeId, recipeId).future,
    );
  }
}

void main() {
  group('build', () {
    test('a new recipe starts at once with an empty draft', () {
      final setup = _Setup();

      final states = setup.open();

      expect(states, hasLength(1));
      expect(states.single.value, isA<RecipeEditorState>());
      expect(setup.draft()!.original, isNull);
      expect(setup.draft()!.isEmpty, isTrue);
    });

    test('a saved recipe loads into a draft of its lines', () async {
      final setup = _Setup(
        recipes: [
          _recipe(weights: {'1 Zwiebel': _aiWeight}),
        ],
      );

      final states = setup.open('recipe-1');
      await setup.loaded('recipe-1');

      expect(states.first.isLoading, isTrue);
      final draft = states.last.value!.draft;
      expect(draft.original?.id, 'recipe-1');
      expect(draft.name, 'Brot');
      expect(draft.ingredients.map((line) => line.text), [
        '1 Zwiebel',
        '200 g Mehl',
      ]);
      expect(draft.ingredients.first.weight, _aiWeight);
      expect(draft.steps.map((line) => line.text), ['Kneten']);
    });

    test('a recipe that is gone gives no draft', () async {
      final setup = _Setup(recipes: [_recipe()]);

      final states = setup.open('other');
      await setup.loaded('other');

      expect(states.last.hasValue, isTrue);
      expect(states.last.value, isNull);
    });

    test(
      'a later change of the saved recipe does not reset the edits',
      () async {
        final setup = _Setup(recipes: [_recipe()]);
        await setup.loaded('recipe-1');
        setup.controller('recipe-1').setName('Bauernbrot');

        await setup.templates.save(_recipe().copyWith(name: 'Anderes Brot'));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(setup.draft('recipe-1')!.name, 'Bauernbrot');
      },
    );
  });

  group('edits', () {
    test('every setter changes the draft', () {
      final setup = _Setup();

      setup.controller()
        ..setName('Suppe')
        ..setPortions(4)
        ..setRecipeUrl('https://example.com/suppe')
        ..addLine(.ingredients, ' Mehl ')
        ..addLine(.ingredients, 'Salz')
        ..addLine(.steps, 'Kochen')
        ..setLine(.ingredients, 1, 'Meersalz')
        ..removeLine(.ingredients, 0)
        ..restoreLine(.ingredients, 0, const RecipeEditorLine(text: 'Mehl'));

      final draft = setup.draft()!;
      expect(draft.name, 'Suppe');
      expect(draft.portions, 4);
      expect(draft.recipeUrl, 'https://example.com/suppe');
      expect(draft.ingredients.map((line) => line.text), ['Mehl', 'Meersalz']);
      expect(draft.steps.map((line) => line.text), ['Kochen']);

      setup.controller().removeLine(.ingredients, 0);

      expect(setup.draft()!.ingredients.map((line) => line.text), ['Meersalz']);
    });

    test('paste says empty for a blank text and does not ask the AI', () async {
      final setup = _Setup();

      expect(await setup.controller().paste('  \n '), RecipePasteResult.empty);

      expect(setup.draft()!.isEmpty, isTrue);
      expect(setup.scans.readTexts, isEmpty);
    });

    test(
      'paste refuses a text over the limit: no AI, no rules, no change',
      () async {
        final setup = _Setup();
        final states = setup.open();
        setup.controller().setName('Suppe');
        final tooLong = 'Mehl\n' * (recipeTextCharacterLimit ~/ 5 + 1);

        expect(
          await setup.controller().paste(tooLong),
          RecipePasteResult.tooLong,
        );

        expect(setup.scans.readTexts, isEmpty);
        expect(setup.draft()!.name, 'Suppe');
        expect(setup.draft()!.ingredients, isEmpty);
        expect(setup.draft()!.steps, isEmpty);
        expect([
          for (final state in states) state.value!.isScanning,
        ], everyElement(isFalse));
      },
    );

    test('paste still reads a text at the limit', () async {
      final setup = _Setup(
        scans: _FakeScanRepository(
          textAnswer: const ScannedIngredientList(
            title: null,
            servings: null,
            ingredients: ['Mehl'],
            steps: [],
          ),
        ),
      );
      final atLimit = 'a' * recipeTextCharacterLimit;

      expect(await setup.controller().paste(atLimit), RecipePasteResult.read);

      expect(setup.scans.readTexts, [atLimit]);
      expect(setup.draft()!.ingredients, hasLength(1));
    });

    test('paste uses the AI answer and resets isScanning', () async {
      final scans = _FakeScanRepository(
        textAnswer: const ScannedIngredientList(
          title: 'Brot',
          servings: 6,
          ingredients: ['500 g Mehl', 'Salz'],
          steps: ['Backen'],
        ),
      );
      final setup = _Setup(scans: scans);
      final states = setup.open();

      expect(
        await setup.controller().paste('irgendein Text'),
        RecipePasteResult.read,
      );

      expect(scans.readTexts, ['irgendein Text']);
      final draft = setup.draft()!;
      expect(draft.name, 'Brot');
      expect(draft.portions, 6);
      expect(draft.ingredients.map((line) => line.text), [
        '500 g Mehl',
        'Salz',
      ]);
      expect(draft.steps.map((line) => line.text), ['Backen']);
      final scanning = [for (final state in states) state.value!.isScanning];
      expect(scanning.first, isFalse);
      expect(scanning, contains(true));
      expect(scanning.last, isFalse);
    });

    test('paste is scanning while it waits for the AI', () async {
      final setup = _Setup(
        scans: _FakeScanRepository(
          textAnswer: const ScannedIngredientList(
            title: null,
            servings: null,
            ingredients: ['Mehl'],
            steps: [],
          ),
        ),
      )..open();

      final pasting = setup.controller().paste('Mehl');
      expect(setup.editor()!.isScanning, isTrue);
      await pasting;

      expect(setup.editor()!.isScanning, isFalse);
    });

    test('paste reads the text by rules when the AI fails', () async {
      final setup = _Setup();

      expect(
        await setup.controller().paste(
          'Brot – 4 Portionen\n\nMehl\nSalz\n\n'
          '1. Kneten',
        ),
        RecipePasteResult.read,
      );

      final draft = setup.draft()!;
      expect(draft.name, 'Brot');
      expect(draft.portions, 4);
      expect(draft.ingredients.map((line) => line.text), ['Mehl', 'Salz']);
      expect(draft.steps.map((line) => line.text), ['Kneten']);
      expect(setup.editor()!.isScanning, isFalse);
    });

    test('paste reads the text by rules when the AI answer is empty', () async {
      final setup = _Setup(
        scans: _FakeScanRepository(
          textAnswer: const ScannedIngredientList(
            title: 'Leer',
            servings: null,
            ingredients: [],
            steps: [],
          ),
        ),
      );

      expect(
        await setup.controller().paste('Mehl\nSalz\n\nKneten'),
        RecipePasteResult.read,
      );

      final draft = setup.draft()!;
      expect(draft.name, isEmpty);
      expect(draft.ingredients, hasLength(2));
      expect(draft.steps, hasLength(1));
      expect(setup.editor()!.isScanning, isFalse);
    });

    test('canUseCamera follows the picker', () {
      expect(_Setup(picker: _FakePicker()).controller().canUseCamera(), isTrue);
      expect(
        _Setup(picker: _FakePicker(camera: false)).controller().canUseCamera(),
        isFalse,
      );
    });
  });

  group('scan', () {
    test('a canceled scan returns true and changes nothing', () async {
      final setup = _Setup(scans: _FakeScanRepository(pages: null));
      setup.controller().setName('Suppe');

      expect(await setup.controller().scan(), isTrue);

      expect(setup.draft()!.name, 'Suppe');
      expect(setup.draft()!.ingredients, isEmpty);
      expect(setup.editor()!.isScanning, isFalse);
      expect(setup.scans.readPages, isNull);
    });

    test('a scan merges into the draft and resets isScanning', () async {
      final scans = _FakeScanRepository(
        pages: ['a.jpg', 'b.jpg'],
        scanned: const ScannedIngredientList(
          title: 'Brot',
          servings: 8,
          ingredients: ['500 g Mehl'],
          steps: ['Backen'],
        ),
      );
      final setup = _Setup(scans: scans);
      final states = setup.open();

      expect(await setup.controller().scan(), isTrue);

      expect(scans.readPages, ['a.jpg', 'b.jpg']);
      final draft = setup.draft()!;
      expect(draft.name, 'Brot');
      expect(draft.portions, 8);
      expect(draft.ingredients.map((line) => line.text), ['500 g Mehl']);
      expect(draft.steps.map((line) => line.text), ['Backen']);
      final scanning = [for (final state in states) state.value!.isScanning];
      expect(scanning.first, isFalse);
      expect(scanning, contains(true));
      expect(scanning.last, isFalse);
    });

    test(
      'a read that shows no line returns false and changes nothing',
      () async {
        final setup = _Setup(
          scans: _FakeScanRepository(
            scanned: const ScannedIngredientList(
              title: 'X',
              servings: 8,
              ingredients: [],
              steps: [],
            ),
          ),
        );
        setup.controller()
          ..setName('Suppe')
          ..setPortions(3);

        expect(await setup.controller().scan(), isFalse);

        expect(setup.draft()!.name, 'Suppe');
        expect(setup.draft()!.portions, 3);
        expect(setup.editor()!.isScanning, isFalse);
      },
    );

    test('a failing scanner returns false and resets isScanning', () async {
      final setup = _Setup(
        scans: _FakeScanRepository(failure: Exception('no camera')),
      );
      setup.controller().setName('Suppe');

      expect(await setup.controller().scan(), isFalse);

      expect(setup.editor()!.isScanning, isFalse);
      expect(setup.draft()!.name, 'Suppe');
    });

    test('a failing read returns false and resets isScanning', () async {
      final setup = _Setup(
        scans: _FakeScanRepository()..readFailure = const FormatException(),
      );

      expect(await setup.controller().scan(), isFalse);

      expect(setup.editor()!.isScanning, isFalse);
      expect(setup.draft()!.ingredients, isEmpty);
    });
  });

  group('pickPhoto', () {
    test('takes the bytes from the camera or the files', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final setup = _Setup(picker: _FakePicker(bytes: bytes));

      expect(await setup.controller().pickPhoto(camera: true), isTrue);
      expect(setup.draft()!.photo, bytes);
      expect(await setup.controller().pickPhoto(camera: false), isTrue);
      expect(setup.picker.picks, ['camera', 'file']);
    });

    test(
      'a canceled pick changes nothing, a failing one returns false',
      () async {
        final setup = _Setup();

        expect(await setup.controller().pickPhoto(camera: false), isTrue);
        expect(setup.draft()!.photo, isNull);

        setup.picker.fails = true;
        expect(await setup.controller().pickPhoto(camera: true), isFalse);
        expect(setup.draft()!.photo, isNull);
      },
    );
  });

  group('save a new recipe', () {
    void fill(_Setup setup) => setup.controller()
      ..setName('  Suppe ')
      ..setPortions(3)
      ..addLine(.ingredients, ' 200 g Mehl ')
      ..addLine(.ingredients, 'Salz')
      ..addLine(.steps, 'Mischen');

    test('returns null while the draft cannot be saved', () async {
      final setup = _Setup();
      setup.controller().setName('Suppe');

      expect(await setup.controller().save(), isNull);

      expect(setup.templates.writeCount, 0);
      expect(setup.estimates.started, isEmpty);
      expect(setup.editor()!.isSaving, isFalse);
    });

    test(
      'saves a trimmed recipe, starts its estimate, and returns its id',
      () async {
        final setup = _Setup();
        fill(setup);

        final id = await setup.controller().save();

        expect(id, isNotNull);
        final saved = setup.templates.templates.single;
        expect(saved.id, id);
        expect(saved.name, 'Suppe');
        expect(saved.recipeIngredients, ['200 g Mehl', 'Salz']);
        expect(saved.recipeInstructions, ['Mischen']);
        expect(saved.totalPortions, 3);
        expect(saved.remainingPortions, 3);
        expect(saved.components, isEmpty);
        expect(saved.createdAt, _now);
        expect(saved.imageAssetId, isNull);
        expect(setup.estimates.started, [id]);
        // The page leaves for the recipe, so the draft stays saving.
        expect(setup.editor()!.isSaving, isTrue);
      },
    );

    test('stores the picked photo under the saved asset id', () async {
      final bytes = Uint8List.fromList([9, 8, 7]);
      final setup = _Setup(picker: _FakePicker(bytes: bytes));
      fill(setup);
      await setup.controller().pickPhoto(camera: false);

      await setup.controller().save();

      final assetId = setup.templates.templates.single.imageAssetId;
      expect(assetId, isNotNull);
      expect(setup.images.saved[localImageAssetRef(assetId!)], bytes);
    });

    test(
      'finishes when the editor goes away while the photo is stored',
      () async {
        final bytes = Uint8List.fromList([9, 8, 7]);
        final setup = _Setup(picker: _FakePicker(bytes: bytes));
        fill(setup);
        await setup.controller().pickPhoto(camera: false);
        setup.images.hold = Completer<void>();

        final saving = setup.controller().save();
        await Future<void>.delayed(Duration.zero);
        setup.container.dispose();
        setup.images.hold!.complete();

        final id = await saving;
        expect(id, isNotNull);
        expect(setup.templates.templates.single.id, id);
        expect(setup.estimates.started, [id]);
      },
    );

    test('keeps the link of the page it came from', () async {
      final setup = _Setup();
      fill(setup);
      setup.controller().setRecipeUrl('https://example.com/suppe');

      await setup.controller().save();

      expect(
        setup.templates.templates.single.recipeUrl,
        'https://example.com/suppe',
      );
    });

    test('a failing writer returns null, resets isSaving, and estimates '
        'nothing', () async {
      final setup = _Setup();
      setup.templates.failWrites = true;
      fill(setup);

      expect(await setup.controller().save(), isNull);

      expect(setup.templates.templates, isEmpty);
      expect(setup.estimates.started, isEmpty);
      expect(setup.editor()!.isSaving, isFalse);
    });
  });

  group('save a saved recipe', () {
    test('saves the changes onto the recipe as it is now and starts the '
        'estimate', () async {
      final setup = _Setup(recipes: [_recipe()]);
      await setup.loaded('recipe-1');
      setup.controller('recipe-1')
        ..setName('Bauernbrot')
        ..setLine(.ingredients, 1, '300 g Mehl');
      // What arrived after the editor opened: an estimate and a Vorrat item.
      final estimate = RecipeEstimate(
        kcal: 400,
        protein: 10,
        carbs: 50,
        fat: 5,
        portions: 2,
        linesKey: recipeLinesKey(const ['1 Zwiebel', '200 g Mehl']),
        createdAt: _now,
      );
      await setup.templates.save(
        _recipe().copyWith(
          recipeEstimate: estimate,
          recipeIngredientAssignments: const {
            '200 g Mehl': ['flour'],
          },
          recipeLineWeights: const {'1 Zwiebel': _aiWeight},
        ),
      );

      final id = await setup.controller('recipe-1').save();

      expect(id, 'recipe-1');
      final saved = setup.templates.templates.single;
      expect(saved.name, 'Bauernbrot');
      expect(saved.recipeIngredients, ['1 Zwiebel', '300 g Mehl']);
      expect(saved.updatedAt, _now);
      expect(saved.recipeEstimate, estimate);
      expect(saved.recipeIngredientAssignments, {
        '300 g Mehl': ['flour'],
      });
      expect(saved.recipeLineWeights, {'1 Zwiebel': _aiWeight});
      expect(setup.estimates.started, ['recipe-1']);
    });

    test('a recipe that is gone returns null and resets isSaving', () async {
      final setup = _Setup(recipes: [_recipe()]);
      await setup.loaded('recipe-1');
      await setup.templates.delete('recipe-1');

      expect(await setup.controller('recipe-1').save(), isNull);

      expect(setup.templates.templates, isEmpty);
      expect(setup.estimates.started, isEmpty);
      expect(setup.editor('recipe-1')!.isSaving, isFalse);
    });

    test('a failing save returns null and resets isSaving', () async {
      final setup = _Setup(recipes: [_recipe()]);
      await setup.loaded('recipe-1');
      setup.controller('recipe-1').setName('Bauernbrot');
      setup.templates.failWrites = true;

      expect(await setup.controller('recipe-1').save(), isNull);

      expect(setup.templates.templates.single.name, 'Brot');
      expect(setup.estimates.started, isEmpty);
      expect(setup.editor('recipe-1')!.isSaving, isFalse);
    });
  });
}
