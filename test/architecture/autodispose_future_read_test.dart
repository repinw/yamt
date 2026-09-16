import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Architecture - AutoDispose Future Read Guard', () {
    test(
      'production code must not call ref.read or container.read on .future',
      () {
        final libDir = Directory('lib');
        expect(
          libDir.existsSync(),
          isTrue,
          reason: 'lib/ directory must exist',
        );

        final violations = <String>[];
        final dartFiles = libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where(_isSubjectToCheck);

        final forbiddenPattern = RegExp(
          r'(?:container|ref)\.read\s*\([^)]*Provider(?:\([^)]*\))?\.future\s*\)',
        );

        for (final file in dartFiles) {
          final relativePath = file.path.replaceAll(r'\', '/');
          final lines = file.readAsLinesSync();

          for (var index = 0; index < lines.length; index++) {
            final line = lines[index];
            if (forbiddenPattern.hasMatch(line)) {
              violations.add(
                '$relativePath:${index + 1}: ${line.trim()}',
              );
            }
          }
        }

        final failureMessage = StringBuffer()
          ..writeln(
            'Forbidden .read(provider.future) calls found in production code:',
          )
          ..writeln(violations.join('\n'))
          ..writeln(
            '\nPer architecture.md, calling .read(provider.future) on '
            'unlistened auto-disposed providers causes disposal during '
            'loading (StateError). Query repository directly or pass data '
            'from the caller.',
          );

        expect(violations, isEmpty, reason: failureMessage.toString());
      },
    );
  });
}

bool _isSubjectToCheck(File file) {
  final path = file.path.replaceAll(r'\', '/');
  if (!path.endsWith('.dart')) return false;
  if (path.endsWith('.g.dart')) return false;
  if (path.endsWith('.freezed.dart')) return false;
  if (path.contains('/l10n/')) return false;
  return true;
}
