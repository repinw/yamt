import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:yamt/features/cookbook_new/data/ingredient_list_scan_repository.dart';

Future<String?> _unused(Map<String, Object?> inputs) =>
    throw StateError('not expected');

void main() {
  group('IngredientListScanRepository.loadIngredientList', () {
    late Directory directory;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('ingredient_list_scan');
      addTearDown(() => directory.deleteSync(recursive: true));
    });

    String page(String name) {
      final image = img.Image(width: 8, height: 8);
      final file = File('${directory.path}/$name.jpg')
        ..writeAsBytesSync(img.encodeJpg(image));
      return file.path;
    }

    test('sends one jpeg file input per page, in order', () async {
      final calls = <Map<String, Object?>>[];
      final repository = IngredientListScanRepository(
        textClient: _unused,
        templateClient: (inputs) async {
          calls.add(inputs);
          return jsonEncode({
            'title': 'Brot',
            'servings': 8,
            'ingredients': ['500 g Mehl'],
            'steps': ['Backen'],
          });
        },
      );

      final scanned = await repository.loadIngredientList([
        page('one'),
        page('two'),
      ]);

      expect(scanned.title, 'Brot');
      expect(scanned.servings, 8);
      expect(scanned.ingredients, ['500 g Mehl']);
      expect(scanned.steps, ['Backen']);
      final input = calls.single;
      expect(input.keys, ['files']);
      final files = input['files']! as List<Object?>;
      expect(files, hasLength(2));
      for (final file in files) {
        final map = file! as Map<String, Object?>;
        expect(map.keys, unorderedEquals(['mimeType', 'data']));
        expect(map['mimeType'], 'image/jpeg');
        final bytes = base64Decode(map['data']! as String);
        expect(img.decodeJpg(bytes), isNotNull);
      }
    });

    test('throws a FormatException for a null or blank answer', () async {
      for (final answer in <String?>[null, '', '  \n']) {
        final repository = IngredientListScanRepository(
          textClient: _unused,
          templateClient: (inputs) async => answer,
        );
        await expectLater(
          repository.loadIngredientList([page('p')]),
          throwsFormatException,
          reason: 'answer $answer',
        );
      }
    });

    test('throws when the answer is no JSON or has another shape', () async {
      for (final answer in ['not json', '[]']) {
        final repository = IngredientListScanRepository(
          textClient: _unused,
          templateClient: (inputs) async => answer,
        );
        await expectLater(
          repository.loadIngredientList([page('p')]),
          throwsFormatException,
          reason: 'answer $answer',
        );
      }
    });

    test('passes a failing request on', () async {
      final repository = IngredientListScanRepository(
        textClient: _unused,
        templateClient: (inputs) async => throw StateError('offline'),
      );

      await expectLater(
        repository.loadIngredientList([page('p')]),
        throwsStateError,
      );
    });
  });

  group('IngredientListScanRepository.loadRecipeText', () {
    test('sends the text and parses the answer', () async {
      final calls = <Map<String, Object?>>[];
      final repository = IngredientListScanRepository(
        templateClient: _unused,
        textClient: (inputs) async {
          calls.add(inputs);
          return jsonEncode({
            'title': 'Brot',
            'servings': 8,
            'ingredients': ['500 g Mehl'],
            'steps': ['Backen'],
          });
        },
      );

      final read = await repository.loadRecipeText('Brot\n500 g Mehl');

      expect(calls, [
        {'text': 'Brot\n500 g Mehl'},
      ]);
      expect(read.title, 'Brot');
      expect(read.servings, 8);
      expect(read.ingredients, ['500 g Mehl']);
      expect(read.steps, ['Backen']);
    });

    test(
      'throws a FormatException for an empty or unreadable answer',
      () async {
        for (final answer in <String?>[null, '', '  ', 'not json', '[]']) {
          final repository = IngredientListScanRepository(
            templateClient: _unused,
            textClient: (inputs) async => answer,
          );
          await expectLater(
            repository.loadRecipeText('Mehl'),
            throwsFormatException,
            reason: 'answer $answer',
          );
        }
      },
    );

    test('passes a failing request on', () async {
      final repository = IngredientListScanRepository(
        templateClient: _unused,
        textClient: (inputs) async => throw StateError('offline'),
      );

      await expectLater(repository.loadRecipeText('Mehl'), throwsStateError);
    });
  });
}
