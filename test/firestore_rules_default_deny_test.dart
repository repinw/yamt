import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Collection names that the client reads or writes, from the
/// `_...Collection = '...'` constants and literal paths in lib/.
Set<String> _clientCollections() {
  final names = <String>{};
  final constant = RegExp(r"_\w+Collection(?:Name)? = '([a-z_]+)'");
  final literalPath = RegExp(r"(?:doc|collection)\('([a-z_$/{}]+)'");
  for (final file in Directory('lib').listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) {
      continue;
    }
    final source = file.readAsStringSync();
    names.addAll(constant.allMatches(source).map((match) => match.group(1)!));
    for (final match in literalPath.allMatches(source)) {
      final segments = match.group(1)!.split('/');
      // Collection names sit at the even positions of a path.
      for (var index = 0; index < segments.length; index += 2) {
        names.add(segments[index]);
      }
    }
  }
  return names;
}

void main() {
  late String rules;

  setUpAll(() {
    rules = File('firestore.rules').readAsStringSync();
  });

  test('no recursive wildcard opens paths without their own rule', () {
    // Firestore ORs the rules, so one generic match would open every
    // path, also stricter ones (#512). Paths without a match stay closed.
    expect(RegExp(r'\{\w+=\*\*\}').allMatches(rules), isEmpty);
  });

  test('every collection that the client uses has its own rule', () {
    final collections = _clientCollections();
    expect(collections, contains('users'));
    final missing = collections
        .where((name) => !RegExp('/$name/').hasMatch(rules))
        .toList();
    expect(missing, isEmpty, reason: 'Add a match block for: $missing');
  });
}
