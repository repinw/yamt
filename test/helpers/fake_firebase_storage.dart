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

  /// The custom metadata of the uploaded files by path.
  final customMetadata = <String, Map<String, String>?>{};

  /// The error that every upload fails with, such as a lost connection.
  Object? uploadError;

  /// Whether an upload to a stored file fails as unauthorized, like the
  /// `isNewFile` rule in `storage.rules`.
  bool refuseOverwrites = false;

  /// The paths of every upload, in order.
  final uploads = <String>[];

  /// Futures that hold the next uploads until they complete, one each.
  final uploadGates = <Future<void>>[];

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
    final error =
        _storage.uploadError ??
        (_storage.refuseOverwrites && _storage.files.contains(fullPath)
            ? FirebaseException(plugin: 'storage', code: 'unauthorized')
            : null);
    if (error != null) return _FakeUploadTask(Future.error(error));
    _storage.uploads.add(fullPath);
    _storage.files.add(fullPath);
    _storage.contents[fullPath] = data;
    _storage.contentTypes[fullPath] = metadata?.contentType;
    _storage.customMetadata[fullPath] = metadata?.customMetadata;
    final gate = _storage.uploadGates.isEmpty
        ? Future<void>.value()
        : _storage.uploadGates.removeAt(0);
    return _FakeUploadTask(gate.then((_) => _FakeTaskSnapshot()));
  }

  @override
  Future<FullMetadata> getMetadata() async {
    if (!_storage.files.contains(fullPath)) {
      throw FirebaseException(plugin: 'storage', code: 'object-not-found');
    }
    return FullMetadata({'fullPath': fullPath});
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
