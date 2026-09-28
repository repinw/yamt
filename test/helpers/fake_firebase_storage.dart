import 'package:firebase_storage/firebase_storage.dart';
import 'package:mocktail/mocktail.dart';

/// In-memory Firebase Storage that lists and deletes files by full path.
class FakeFirebaseStorage extends Fake implements FirebaseStorage {
  /// Creates the fake with the file paths in [files].
  new([Iterable<String> files = const <String>[]]) : files = <String>{...files};

  /// The stored file paths.
  final Set<String> files;

  @override
  Reference ref([String? path]) => _FakeReference(this, path ?? '');
}

class _FakeReference extends Fake implements Reference {
  new(this._storage, this.fullPath);

  final FakeFirebaseStorage _storage;

  @override
  final String fullPath;

  @override
  Future<void> delete() async => _storage.files.remove(fullPath);

  @override
  Future<ListResult> listAll() async {
    final prefix = '$fullPath/';
    final children = _storage.files
        .where((file) => file.startsWith(prefix))
        .map((file) => file.substring(prefix.length));
    return _FakeListResult(
      items: <Reference>[
        for (final child in children.where((child) => !child.contains('/')))
          _FakeReference(_storage, '$prefix$child'),
      ],
      prefixes: <Reference>[
        for (final folder
            in children
                .where((child) => child.contains('/'))
                .map((child) => child.split('/').first)
                .toSet())
          _FakeReference(_storage, '$prefix$folder'),
      ],
    );
  }
}

class _FakeListResult extends Fake implements ListResult {
  new({required this.items, required this.prefixes});

  @override
  final List<Reference> items;

  @override
  final List<Reference> prefixes;
}
