import 'dart:io';

/// A rule violation in one line of one file.
typedef Finding = ({String path, int line, String text});

/// An `import` or `export` directive. `target` is the project-relative path
/// of a local file, or `null` for `dart:` and other packages.
typedef Directive = ({String uri, String? target, int line});

/// A hand-written Dart file under `lib/`.
class SourceFile {
  /// Creates a source file from its project-relative [path] and [lines].
  new(this.path, this.lines);

  /// Path relative to the project root, with `/` separators.
  final String path;

  /// The lines of the file.
  final List<String> lines;

  /// The `import` and `export` directives of the file.
  late final List<Directive> directives = _parseDirectives(path, lines);
}

/// The hand-written Dart files of a project and its feature order.
class Project {
  /// Creates a project from its [files], [features], and [featureOrder].
  const new({
    required this.files,
    required this.features,
    required this.featureOrder,
  });

  /// Loads the project below [root] with the given [featureOrder].
  factory load(String root, List<String> featureOrder) {
    final lib = Directory('$root/lib');
    final files =
        lib
            .listSync(recursive: true)
            .whereType<File>()
            .map((file) => (file, _relativePath(root, file.path)))
            .where((entry) => _isHandWritten(entry.$2))
            .map((entry) => SourceFile(entry.$2, entry.$1.readAsLinesSync()))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final features = Directory('$root/lib/features')
        .listSync()
        .whereType<Directory>()
        .map((directory) => directory.path.split('/').last)
        .toSet();
    return Project(
      files: files,
      features: features,
      featureOrder: featureOrder,
    );
  }

  /// The hand-written Dart files under `lib/`, sorted by path.
  final List<SourceFile> files;

  /// The folder names under `lib/features/`.
  final Set<String> features;

  /// The feature order from `architecture.md`, earliest first.
  final List<String> featureOrder;

  /// The position of [feature] in the feature order, or `null`.
  int? orderOf(String feature) {
    final index = featureOrder.indexOf(feature);
    return index < 0 ? null : index;
  }
}

/// A rule from `architecture.md` that the architecture test checks.
class ArchitectureRule {
  /// Creates a rule with a stable [id], its [rule] text, and its [check].
  const new({required this.id, required this.rule, required this.check});

  /// The stable id. The baseline uses it as key.
  final String id;

  /// The rule in `architecture.md`, with the section that states it.
  final String rule;

  /// Returns every violation of the rule in a project.
  final Iterable<Finding> Function(Project project) check;
}

/// Reads the feature order from the `### Feature Order` code block of
/// `architecture.md` below [root].
List<String> readFeatureOrder(String root) {
  final text = File('$root/architecture.md').readAsStringSync();
  final block = RegExp(r'### Feature Order[\s\S]*?```text\n([\s\S]*?)```')
      .firstMatch(text);
  if (block == null) {
    throw StateError('architecture.md has no Feature Order code block.');
  }
  return block
      .group(1)!
      .replaceAll('(legacy)', '')
      .split(',')
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .toList();
}

/// Returns the feature of a `lib/features/<feature>/...` path, or `null`.
String? featureOf(String path) {
  final segments = path.split('/');
  final isFeature =
      segments.length > 3 && segments[0] == 'lib' && segments[1] == 'features';
  return isFeature ? segments[2] : null;
}

/// Returns the path inside the feature folder, or `null` outside features.
String? featurePathOf(String path) {
  if (featureOf(path) == null) return null;
  return path.split('/').skip(3).join('/');
}

/// The rules that `test/architecture/architecture_test.dart` checks.
final List<ArchitectureRule> architectureRules = [
  _importRule(
    id: 'feature-order',
    rule:
        '§6 Feature Order: a feature imports only features that come '
        'earlier in the list.',
    violates: (project, from, to) {
      final fromOrder = project.orderOf(featureOf(from) ?? '');
      final toOrder = project.orderOf(featureOf(to) ?? '');
      return fromOrder != null && toOrder != null && toOrder > fromOrder;
    },
  ),
  _importRule(
    id: 'foreign-presentation',
    rule:
        '§6 Feature Order: from another feature, import only domain/, '
        'data/, application/, presentation/models/, presentation/widgets/, '
        'and presentation/*_flow.dart.',
    violates: (project, from, to) {
      final fromFeature = featureOf(from);
      final toFeature = featureOf(to);
      if (fromFeature == null || toFeature == null) return false;
      if (fromFeature == toFeature) return false;
      return !_isPublicFeaturePath(featurePathOf(to)!);
    },
  ),
  _importRule(
    id: 'core-imports-feature',
    rule:
        '§6 Cross-Feature Workflows: lib/core does not import features. '
        'Only lib/core/router/ may.',
    violates: (project, from, to) =>
        from.startsWith('lib/core/') &&
        !from.startsWith('lib/core/router/') &&
        to.startsWith('lib/features/'),
  ),
  _fileRule(
    id: 'feature-folders',
    rule:
        'Where New Code Goes: feature code lives in domain/, data/, '
        'application/, or presentation/.',
    violates: (path) {
      final inner = featurePathOf(path);
      return inner != null &&
          !_layers.any((layer) => inner.startsWith('$layer/'));
    },
  ),
  _fileRule(
    id: 'presentation-folders',
    rule:
        'Where New Code Goes: presentation/ holds *_page.dart and '
        '*_flow.dart files plus controllers/, models/, and widgets/.',
    violates: _violatesPresentationFolders,
  ),
  _fileRule(
    id: 'file-roles',
    rule: 'File Names: no vague roles such as _store or _coordinator.',
    violates: (path) {
      if (featureOf(path) == null) return false;
      final name = path.split('/').last.replaceAll('.dart', '');
      return _vagueRoles.any((role) => name == role || name.endsWith('_$role'));
    },
  ),
  _fileRule(
    id: 'flow-placement',
    rule: 'Where New Code Goes: UI flows live in presentation/.',
    violates: (path) =>
        featureOf(path) != null &&
        path.endsWith('_flow.dart') &&
        !featurePathOf(path)!.startsWith('presentation/'),
  ),
  _lineRule(
    id: 'clock',
    rule:
        '§1 Layers: no DateTime.now() in domain, application, or '
        'controllers. Read clockProvider.',
    pattern: RegExp(r'DateTime\.now\(\)'),
    appliesTo: _isClockRestricted,
  ),
  _lineRule(
    id: 'sdk-instance',
    rule: '§2 Data Layer: no .instance calls in features.',
    pattern: RegExp(
      r'\b(?:FirebaseFirestore|FirebaseAuth|FirebaseStorage|FirebaseAppCheck'
      '|FirebaseAI|FirebaseFunctions|FirebaseMessaging|GoogleSignIn)'
      r'\.instance\b',
    ),
    appliesTo: _isFeature,
  ),
  _lineRule(
    id: 'theme-values',
    rule:
        '§9 UI: no Colors.*, Color(0x...), or TextStyle(...) in features. '
        'Use the theme.',
    pattern: RegExp(
      r'\bColors\.(?!transparent\b)[a-z]\w*|\bColor\(0x'
      r'|\bColor\.from(?:ARGB|RGBO)\(|\bTextStyle\(',
    ),
    appliesTo: _isFeature,
  ),
  _lineRule(
    id: 'ignore-comment',
    rule: '§12 Hygiene: no // ignore or // ignore_for_file comments.',
    pattern: RegExp(r'//\s*ignore(?:_for_file)?\s*:'),
    appliesTo: _isAny,
  ),
  _lineRule(
    id: 'route-extra-cast',
    rule: '§8 Navigation: read extra only with requireRouteExtra.',
    pattern: RegExp(r'\.extra!?\s+as\b'),
    appliesTo: _isAny,
  ),
  _lineRule(
    id: 'bare-keep-alive',
    rule: '§3 Lifecycle: close every ref.keepAlive() link.',
    pattern: RegExp(r'^\s*ref\.keepAlive\(\);'),
    appliesTo: _isAny,
  ),
  _lineRule(
    id: 'export',
    rule: '§3 Riverpod: no export statements. Import concrete files.',
    pattern: RegExp('^export '),
    appliesTo: _isAny,
  ),
  _lineRule(
    id: 'material-import',
    rule: 'Stack: import material_ui, never flutter/material.dart.',
    pattern: RegExp(r'package:flutter/material\.dart'),
    appliesTo: _isAny,
  ),
  _lineRule(
    id: 'legacy-riverpod',
    rule: '§3 Riverpod: only generated providers, no legacy provider types.',
    pattern: RegExp(
      r'\b(?:StateProvider|StateNotifierProvider|ChangeNotifierProvider)\b'
      r'|flutter_riverpod/legacy\.dart',
    ),
    appliesTo: _isAny,
  ),
  _lineRule(
    id: 'domain-imports',
    rule: '§1 Layers: domain does not import Flutter, Riverpod, or Firebase.',
    pattern: RegExp(
      "^import 'package:(?:flutter|flutter_riverpod|riverpod"
      '|riverpod_annotation|cloud_firestore|firebase_[a-z_]+|material_ui)/',
    ),
    appliesTo: _isDomain,
  ),
  _lineRule(
    id: 'second-ai-sdk',
    rule: 'Stack: Firebase AI only, no google_generative_ai.',
    pattern: RegExp('package:google_generative_ai/'),
    appliesTo: _isAny,
  ),
  _lineRule(
    id: 'session-interface',
    rule: '§2 Data Layer: no per-feature session interfaces.',
    pattern: RegExp(r'interface\s+class\s+\w+UserSession\b'),
    appliesTo: _isAny,
  ),
];

const _layers = ['domain', 'data', 'application', 'presentation'];

const _publicFolders = [
  'domain',
  'data',
  'application',
  'presentation/models',
  'presentation/widgets',
];

const _presentationFolders = ['controllers', 'models', 'widgets'];

const _vagueRoles = [
  'helpers',
  'support',
  'utils',
  'manager',
  'coordinator',
  'handler',
  'logic',
  'workflows',
  'bridge',
  'adapter',
  'store',
  'contract',
  'codec',
];

ArchitectureRule _lineRule({
  required String id,
  required String rule,
  required RegExp pattern,
  required bool Function(String path) appliesTo,
}) {
  return ArchitectureRule(
    id: id,
    rule: rule,
    check: (project) sync* {
      for (final file in project.files.where((f) => appliesTo(f.path))) {
        for (var index = 0; index < file.lines.length; index++) {
          final line = file.lines[index];
          if (pattern.hasMatch(line)) {
            yield (path: file.path, line: index + 1, text: line.trim());
          }
        }
      }
    },
  );
}

ArchitectureRule _fileRule({
  required String id,
  required String rule,
  required bool Function(String path) violates,
}) {
  return ArchitectureRule(
    id: id,
    rule: rule,
    check: (project) => [
      for (final file in project.files)
        if (violates(file.path)) (path: file.path, line: 1, text: file.path),
    ],
  );
}

ArchitectureRule _importRule({
  required String id,
  required String rule,
  required bool Function(Project project, String from, String to) violates,
}) {
  return ArchitectureRule(
    id: id,
    rule: rule,
    check: (project) sync* {
      for (final file in project.files) {
        for (final directive in file.directives) {
          final target = directive.target;
          if (target != null && violates(project, file.path, target)) {
            yield (path: file.path, line: directive.line, text: directive.uri);
          }
        }
      }
    },
  );
}

bool _isAny(String path) => true;

bool _isFeature(String path) => featureOf(path) != null;

bool _isDomain(String path) =>
    path.startsWith('lib/core/domain/') ||
    (featurePathOf(path)?.startsWith('domain/') ?? false);

bool _isClockRestricted(String path) {
  if (path.startsWith('lib/core/domain/')) return true;
  final inner = featurePathOf(path);
  if (inner == null) return false;
  return const [
    'domain/',
    'application/',
    'presentation/controllers/',
    'provider/',
  ].any(inner.startsWith);
}

bool _isPublicFeaturePath(String inner) {
  if (_publicFolders.any((folder) => inner.startsWith('$folder/'))) {
    return true;
  }
  const presentation = 'presentation/';
  if (!inner.startsWith(presentation)) return false;
  final rest = inner.substring(presentation.length);
  return !rest.contains('/') && rest.endsWith('_flow.dart');
}

bool _violatesPresentationFolders(String path) {
  const presentation = 'presentation/';
  final inner = featurePathOf(path);
  if (inner == null || !inner.startsWith(presentation)) return false;
  final rest = inner.substring(presentation.length);
  if (!rest.contains('/')) {
    return !rest.endsWith('_page.dart') && !rest.endsWith('_flow.dart');
  }
  return !_presentationFolders.any((folder) => rest.startsWith('$folder/'));
}

String _relativePath(String root, String path) =>
    path.substring(root.length + 1).replaceAll(r'\', '/');

bool _isHandWritten(String path) =>
    path.endsWith('.dart') &&
    !path.endsWith('.g.dart') &&
    !path.endsWith('.freezed.dart') &&
    !path.startsWith('lib/l10n/') &&
    path != 'lib/firebase_options.dart';

final _directivePattern = RegExp(
  r"^(?:import|export)\s+((?:'[^']*'\s*)+)",
  multiLine: true,
);

final _literalPattern = RegExp("'([^']*)'");

List<Directive> _parseDirectives(String path, List<String> lines) {
  final text = lines.join('\n');
  return [
    for (final match in _directivePattern.allMatches(text))
      _directive(path, text, match),
  ];
}

Directive _directive(String path, String text, RegExpMatch match) {
  final uri = _literalPattern
      .allMatches(match.group(1)!)
      .map((literal) => literal.group(1)!)
      .join();
  final line = '\n'.allMatches(text.substring(0, match.start)).length + 1;
  return (uri: uri, target: _resolve(path, uri), line: line);
}

String? _resolve(String fromPath, String uri) {
  const package = 'package:yamt/';
  if (uri.startsWith(package)) return 'lib/${uri.substring(package.length)}';
  if (uri.contains(':')) return null;
  final segments = fromPath.split('/')..removeLast();
  for (final part in uri.split('/')) {
    if (part == '..') {
      segments.removeLast();
    } else if (part != '.') {
      segments.add(part);
    }
  }
  return segments.join('/');
}
