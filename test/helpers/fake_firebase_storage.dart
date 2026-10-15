import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:mocktail/mocktail.dart';

/// In-memory Firebase Storage that uploads, downloads, lists, and deletes
/// files by full path.
class FakeFirebaseStorage extends Fake implements FirebaseStorage {
  /// Creates the fake with the file paths in [files].
  new([Iterable<String> files = const <String>[]]) : files = <String>{...files};

  /// The stored file paths.
  final Set<String> files;

  /// The bytes of the uploaded files by path.
  final contents = <String, Uint8List>{};

  /// The content types of the uploaded files by path.
  final contentTypes = <String, String?>{};

  @override
  Reference ref([String? path]) => _FakeReference(this, path ?? '');
}

class _FakeReference extends Fake implements Reference {
  new(this._storage, this.fullPath);

  final FakeFirebaseStorage _storage;

  @override
  final String fullPath;

  @override
  Future<void> delete() async {
    if (!_storage.files.remove(fullPath)) {
      throw FirebaseException(plugin: 'storage', code: 'object-not-found');
    }
    _storage.contents.remove(fullPath);
  }

  @override
  UploadTask putData(Uint8List data, [SettableMetadata? metadata]) {
    _storage.files.add(fullPath);
    _storage.contents[fullPath] = data;
    _storage.contentTypes[fullPath] = metadata?.contentType;
    return _FakeUploadTask(Future.value(_FakeTaskSnapshot()));
  }

  @override
  Future<Uint8List?> getData([int maxSize = 10485760]) async {
    final data = _storage.contents[fullPath];
    if (data == null) {
      throw FirebaseException(plugin: 'storage', code: 'object-not-found');
    }
    return data;
  }

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

class _FakeTaskSnapshot extends Fake implements TaskSnapshot;

/// Like the SDK task, a Future of TaskSnapshot.
class _FakeUploadTask extends Fake implements UploadTask {
  new(this._result);

  final Future<TaskSnapshot> _result;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(TaskSnapshot value) onValue, {
    Function? onError,
  }) => _result.then(onValue, onError: onError);
}
