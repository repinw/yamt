import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_image_generator.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_repository.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'recipe_idea_controller.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

import '../../../../helpers/fake_ai_chef.dart';
import '../../../../helpers/fake_inventory_item_repository.dart';
import '../../../../helpers/fake_prepared_meal_template_repository.dart';

final _now = DateTime.utc(2026, 11, 13, 10);

class _Setup {
  new({
    required this.chef,
    required this.templates,
    required this.container,
    required this.idea,
  });

  static Future<_Setup> create({
    List<InventoryItem> stock = const [],
    FakeAiChef? chef,
  }) async {
    final fake = chef ?? FakeAiChef();
    final templates = FakePreparedMealTemplateRepository();
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => _now),
        aiChefRepositoryProvider.overrideWithValue(fake.repository),
        aiChefImageGeneratorProvider.overrideWithValue(fake.imageGenerator),
        preparedMealTemplateRepositoryProvider.overrideWithValue(templates),
        inventoryItemRepositoryProvider.overrideWithValue(
          FakeInventoryItemRepository(stock),
        ),
      ],
    );
    addTearDown(container.dispose);
    final idea = await fake.repository.loadRecipeIdea(
      languageCode: 'de',
      seed: 'x',
      now: _now,
    );
    return _Setup(
      chef: fake,
      templates: templates,
      container: container,
      idea: idea,
    );
  }

  final FakeAiChef chef;
  final FakePreparedMealTemplateRepository templates;
  final ProviderContainer container;
  final AiChefRecipeIdea idea;

  /// Keeps the picture provider alive, as the open window does.
  ProviderSubscription<AsyncValue<Uint8List>> open() =>
      container.listen(recipeIdeaControllerProvider(idea), (_, _) {});

  RecipeIdeaController get controller =>
      container.read(recipeIdeaControllerProvider(idea).notifier);
}

Future<void> _until(bool Function() condition) async {
  for (var i = 0; i < 400 && !condition(); i += 1) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue);
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 80));

InventoryItem _pasta() => InventoryItem.create(
  id: 'pasta-1',
  name: 'Pasta',
  entryDate: DateTime.utc(2026, 11),
  storeName: 'Store',
  quantity: 1,
  initialAmount: 500,
  currentAmount: 500,
  amountUnit: InventoryAmountUnit.gram,
);

void main() {
  group('the picture', () {
    test('goes loading, then holds the bytes', () async {
      final s = await _Setup.create();
      final states = <AsyncValue<Uint8List>>[];
      s.container.listen(
        recipeIdeaControllerProvider(s.idea),
        (_, next) => states.add(next),
        fireImmediately: true,
      );

      await _until(() => states.any((state) => state.hasValue));

      expect(states.first, isA<AsyncLoading<Uint8List>>());
      expect(states.last.value, fakePictureBytes);
      expect(s.chef.pictureCalls, 1);
    });

    test('is an error when the image model fails', () async {
      final s = await _Setup.create(chef: FakeAiChef()..pictureFails = true);
      final subscription = s.open();
      addTearDown(subscription.close);

      await _until(() => subscription.read().hasError);
    });

    test('asks for a picture that fails once, with no retry', () async {
      final chef = FakeAiChef()..pictureFails = true;
      final s = await _Setup.create(chef: chef);
      final subscription = s.open();
      addTearDown(subscription.close);

      await _until(() => subscription.read().hasError);
      await Future<void>.delayed(const Duration(seconds: 3));

      expect(chef.pictureCalls, 1);
      expect(subscription.read().hasError, isTrue);
    });

    test('does not ask again when only the repository changes', () async {
      final s = await _Setup.create();
      final subscription = s.open();
      addTearDown(subscription.close);
      await _until(() => subscription.read().hasValue);

      s.container.invalidate(aiChefRepositoryProvider);
      await _settle();

      expect(s.chef.pictureCalls, 1);
      expect(subscription.read().value, fakePictureBytes);
    });

    test('is an error for a timeout, asked for once', () async {
      final calls = <int>[];
      final fake = FakeAiChef();
      final container = ProviderContainer(
        overrides: [
          aiChefImageGeneratorProvider.overrideWithValue(
            AiChefImageGenerator(
              imageBytesClient: (_) {
                calls.add(1);
                return Future<Uint8List?>.error(TimeoutException('slow'));
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final idea = await fake.repository.loadRecipeIdea(
        languageCode: 'de',
        seed: 'x',
        now: _now,
      );
      final subscription = container.listen(
        recipeIdeaControllerProvider(idea),
        (_, _) {},
      );
      addTearDown(subscription.close);

      await _until(() => subscription.read().hasError);
      await Future<void>.delayed(const Duration(seconds: 3));

      expect(subscription.read().error, isA<TimeoutException>());
      expect(calls, hasLength(1));
    });
  });

  group('save', () {
    test(
      'adds the idea to the Kochbuch as a new recipe and returns it',
      () async {
        final s = await _Setup.create();
        final subscription = s.open();
        addTearDown(subscription.close);

        final saved = await s.controller.save();

        expect(saved, isNotNull);
        expect(saved!.id, isNotEmpty);
        expect(s.templates.templates.map((meal) => meal.id), [saved.id]);
        final stored = s.templates.templates.single;
        expect(stored.name, 'Tomatenpasta');
        expect(stored.recipeIngredients, ['200 g Pasta', '100 g Tomaten']);
        expect(stored.recipeInstructions, [
          'Pasta kochen.',
          'Sauce dazugeben.',
        ]);
        expect(stored.recipeEstimate, s.idea.recipe.recipeEstimate);
        expect(stored.recipeEstimate!.lines, hasLength(2));
      },
    );

    test('uploads the picture and puts it on the saved recipe', () async {
      final s = await _Setup.create();
      final subscription = s.open();
      addTearDown(subscription.close);

      final saved = await s.controller.save();
      await _until(() => s.templates.templates.single.imageUrl != null);

      expect(s.chef.uploads, [FakeAiChef.coverPath(saved!.id)]);
      expect(
        s.templates.templates.single.imageUrl,
        'https://example.test/${FakeAiChef.coverPath(saved.id)}',
      );
    });

    test(
      'uploads the picture of a recipe that shows a moment after the save',
      () async {
        final s = await _Setup.create();
        final subscription = s.open();
        await _until(() => subscription.read().hasValue);
        final show = s.templates.showHold = Completer();

        final saved = await s.controller.save();
        subscription.close();
        await _settle();
        // The save returned, but the recipe is not in the list yet.
        expect(await s.templates.readAll(), isEmpty);
        expect(s.chef.uploads, isEmpty);

        show.complete();
        await _until(() => s.templates.templates.firstOrNull?.imageUrl != null);

        expect(s.chef.uploads, [FakeAiChef.coverPath(saved!.id)]);
      },
    );

    test('uploads nothing for a recipe that never showed', () async {
      final s = await _Setup.create();
      final subscription = s.open();
      await _until(() => subscription.read().hasValue);
      s.templates.showHold = Completer();

      final saved = await s.controller.save();
      // "Rückgängig" before the recipe showed.
      await s.templates.delete(saved!.id);
      subscription.close();
      await _settle();

      expect(s.chef.uploads, isEmpty);
      expect(s.templates.templates, isEmpty);
    });

    testWidgets(
      'stops waiting for a recipe that does not show, with no error',
      (tester) async {
        final s = (await tester.runAsync(_Setup.create))!;
        final subscription = s.open();
        addTearDown(subscription.close);
        await tester.pump(const Duration(seconds: 1));
        final show = s.templates.showHold = Completer();

        final saved = await s.controller.save();
        await tester.pump(const Duration(seconds: 29));
        expect(s.chef.uploads, isEmpty);
        await tester.pump(const Duration(seconds: 2));

        // It gave up: a recipe that shows now gets no picture.
        show.complete();
        await tester.pump(const Duration(seconds: 1));
        expect(saved, isNotNull);
        expect(s.templates.templates, hasLength(1));
        expect(s.chef.uploads, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );

    test('stops waiting at once when the Kochbuch stream ends without the '
        'recipe, with no picture and no error', () async {
      final s = await _Setup.create();
      final subscription = s.open();
      await _until(() => subscription.read().hasValue);
      s.templates.showHold = Completer();
      final watching = s.templates.watcherCount;

      final saved = await s.controller.save();
      subscription.close();
      await _until(() => s.templates.watcherCount > watching - 1);
      await s.templates.endWatchers();

      // The wait is over: nothing keeps the controller alive any more.
      await _until(
        () => !s.container.read(recipeIdeaControllerProvider(s.idea).exists),
      );
      expect(saved, isNotNull);
      expect(s.templates.watcherCount, 0);
      expect(s.chef.uploads, isEmpty);
      expect(s.templates.templates, isEmpty);
    });

    testWidgets(
      'gives up after 30 seconds in total, also while the Kochbuch keeps '
      'changing without the recipe',
      (tester) async {
        final s = (await tester.runAsync(_Setup.create))!;
        final subscription = s.open();
        addTearDown(subscription.close);
        await tester.pump(const Duration(seconds: 1));
        final watching = s.templates.watcherCount;
        final show = s.templates.showHold = Completer();

        final saved = await s.controller.save();
        // Only the recipe's own write stays hidden; others show at once.
        s.templates.showHold = null;
        await tester.pump();
        expect(s.templates.watcherCount, watching + 1);

        // A stream that emits every 10 seconds never idles for 30 of them.
        for (var i = 0; i < 4; i += 1) {
          await s.templates.save(
            s.idea.recipe.copyWith(id: 'other-$i', name: 'Other $i'),
          );
          await tester.pump(const Duration(seconds: 10));
        }

        // 40 seconds after the save: the listener is gone, no picture.
        expect(s.templates.watcherCount, watching);
        show.complete();
        await tester.pump(const Duration(seconds: 1));
        expect(saved, isNotNull);
        expect(s.chef.uploads, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );

    test('does not wait for the picture', () async {
      final s = await _Setup.create(
        chef: FakeAiChef()..pictureHold = Completer(),
      );
      final subscription = s.open();
      addTearDown(subscription.close);

      final saved = await s.controller.save();

      expect(saved, isNotNull);
      expect(s.chef.uploads, isEmpty);
      expect(s.templates.templates.single.imageUrl, isNull);
    });

    test('uploads a picture that arrives after the save', () async {
      final hold = Completer<void>();
      final s = await _Setup.create(chef: FakeAiChef()..pictureHold = hold);
      final subscription = s.open();
      final saved = await s.controller.save();
      // The window closed with the idea saved; the picture is still coming.
      subscription.close();
      await _settle();
      expect(s.chef.uploads, isEmpty);

      hold.complete();
      await _until(() => s.templates.templates.single.imageUrl != null);

      expect(s.chef.uploads, [FakeAiChef.coverPath(saved!.id)]);
    });

    test(
      'puts the picture on the recipe as it is then, not as saved',
      () async {
        final hold = Completer<void>();
        final s = await _Setup.create(chef: FakeAiChef()..pictureHold = hold);
        final subscription = s.open();
        addTearDown(subscription.close);
        final saved = await s.controller.save();
        await s.templates.update(
          saved!.id,
          (latest) => latest.copyWith(name: 'Umbenannt'),
        );

        hold.complete();
        await _until(() => s.templates.templates.single.imageUrl != null);

        expect(s.templates.templates.single.name, 'Umbenannt');
      },
    );

    test(
      'uploads nothing when the recipe is gone before the picture',
      () async {
        final hold = Completer<void>();
        final s = await _Setup.create(chef: FakeAiChef()..pictureHold = hold);
        final subscription = s.open();
        final saved = await s.controller.save();
        // "Rückgängig" removes the recipe.
        await s.templates.delete(saved!.id);
        subscription.close();

        hold.complete();
        await _settle();

        expect(s.chef.uploads, isEmpty);
        expect(s.templates.templates, isEmpty);
      },
    );

    test(
      'leaves the recipe without a picture when the image model fails',
      () async {
        final s = await _Setup.create(chef: FakeAiChef()..pictureFails = true);
        final subscription = s.open();
        addTearDown(subscription.close);

        final saved = await s.controller.save();
        await _settle();

        expect(saved, isNotNull);
        expect(s.chef.uploads, isEmpty);
        expect(s.templates.templates.single.imageUrl, isNull);
      },
    );

    test('keeps the recipe when the upload fails', () async {
      final s = await _Setup.create(chef: FakeAiChef()..uploadFails = true);
      final subscription = s.open();
      addTearDown(subscription.close);

      final saved = await s.controller.save();
      await _settle();

      expect(saved, isNotNull);
      expect(s.templates.templates, hasLength(1));
      expect(s.templates.templates.single.imageUrl, isNull);
    });

    test('returns null when the Kochbuch cannot be written', () async {
      final s = await _Setup.create();
      final subscription = s.open();
      addTearDown(subscription.close);
      s.templates.failWrites = true;

      final saved = await s.controller.save();
      await _settle();

      expect(saved, isNull);
      expect(s.templates.templates, isEmpty);
      expect(s.chef.uploads, isEmpty);
    });

    test('a second save while the first runs gives the same recipe', () async {
      final s = await _Setup.create();
      final subscription = s.open();
      addTearDown(subscription.close);
      final hold = s.templates.writeHold = Completer();

      final first = s.controller.save();
      final second = s.controller.save();
      hold.complete();
      final saved = await Future.wait([first, second]);

      expect(saved.first, isNotNull);
      expect(saved.last!.id, saved.first!.id);
      expect(s.templates.templates, hasLength(1));
      expect(s.templates.writeCount, 1);
    });

    test('can save again after a failure', () async {
      final s = await _Setup.create();
      final subscription = s.open();
      addTearDown(subscription.close);
      s.templates.failWrites = true;
      expect(await s.controller.save(), isNull);

      s.templates.failWrites = false;
      final saved = await s.controller.save();

      expect(saved, isNotNull);
      expect(s.templates.templates, hasLength(1));
    });
  });

  group('without saving', () {
    test('uploads nothing when the cook closes the window', () async {
      final s = await _Setup.create();
      final subscription = s.open();
      await _until(() => subscription.read().hasValue);

      subscription.close();
      await _settle();

      expect(s.chef.uploads, isEmpty);
      expect(s.templates.templates, isEmpty);
    });

    test('uploads nothing when the picture arrives after the close', () async {
      final hold = Completer<void>();
      final s = await _Setup.create(chef: FakeAiChef()..pictureHold = hold);
      final subscription = s.open();
      await _settle();

      subscription.close();
      hold.complete();
      await _settle();

      expect(s.chef.uploads, isEmpty);
      expect(s.templates.templates, isEmpty);
    });
  });

  group('recipeIdeaViewProvider', () {
    test('shows the idea as a recipe for its own portions', () async {
      final s = await _Setup.create();

      final view = s.container.read(recipeIdeaViewProvider(s.idea, 'de'));

      expect(view.recipe.name, 'Tomatenpasta');
      expect(view.portions, 2);
      expect(view.lines.map((line) => line.ingredient), [
        '200 g Pasta',
        '100 g Tomaten',
      ]);
      expect(view.estimate, isNotNull);
      expect(view.estimate!.kcal, 300);
      expect(view.lineNutrition, hasLength(2));
    });

    test('has no Vorrat items before the Vorrat is there', () async {
      final s = await _Setup.create(stock: [_pasta()]);

      final view = s.container.read(recipeIdeaViewProvider(s.idea, 'de'));

      expect(view.lines.every((line) => line.items.isEmpty), isTrue);
    });

    test(
      'adds the Vorrat items of an ingredient once the Vorrat comes',
      () async {
        final s = await _Setup.create(stock: [_pasta()]);
        final views = <int>[];
        s.container.listen(
          recipeIdeaViewProvider(s.idea, 'de'),
          (_, next) => views.add(next.lines.first.items.length),
          fireImmediately: true,
        );

        await _until(() => views.last == 1);

        final view = s.container.read(recipeIdeaViewProvider(s.idea, 'de'));
        expect(view.lines.first.items.single.id, 'pasta-1');
        expect(view.lines.last.items, isEmpty);
      },
    );

    test('recipe id of an unsaved idea is empty and still found', () async {
      final s = await _Setup.create();

      expect(s.idea.recipe.id, '');
      expect(
        s.container.read(recipeIdeaViewProvider(s.idea, 'en')).recipe.id,
        '',
      );
    });
  });
}
