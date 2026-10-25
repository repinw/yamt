import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/provider/firebase_storage_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/product_search_hub/data/photo_upload_repository.dart';

import '../../../helpers/fake_firebase_storage.dart';

class _MockUser extends Mock implements User;

const _path = 'users/u1/food_photos/p1.jpg';
final _bytes = Uint8List.fromList([1, 2, 3]);

late Directory _folder;
final _now = DateTime.utc(2026, 10, 24, 12);

PhotoUploadRepository _repository(
  FakeFirebaseStorage? storage, {
  String ownerId = 'u1',
}) {
  return PhotoUploadRepository(
    storage: storage,
    ownerId: storage == null ? null : ownerId,
    folder: () async => _folder,
  );
}

Future<File> _add(
  PhotoUploadRepository repository, {
  String path = _path,
}) async {
  final photo = await repository.addPendingPhoto(
    path: path,
    bytes: _bytes,
    contentType: 'image/jpeg',
    customMetadata: {'kind': 'front'},
  );
  photo.setLastModifiedSync(_now);
  return photo;
}

List<FileSystemEntity> _keptFiles() =>
    _folder.existsSync() ? _folder.listSync(recursive: true) : const [];

void main() {
  setUp(() async {
    _folder = await Directory.systemTemp.createTemp('photo_uploads_test');
    addTearDown(() async {
      if (_folder.existsSync()) await _folder.delete(recursive: true);
    });
  });

  test('uploads a kept photo and removes it from the device', () async {
    final storage = FakeFirebaseStorage();
    final repository = _repository(storage);

    await repository.uploadPendingPhoto(await _add(repository));

    expect(storage.contents[_path], _bytes);
    expect(storage.contentTypes[_path], 'image/jpeg');
    expect(storage.customMetadata[_path], {'kind': 'front'});
    expect(_keptFiles().whereType<File>(), isEmpty);
  });

  test('a failed upload keeps the photo for a later try (#849)', () async {
    final storage = FakeFirebaseStorage()
      ..uploadError = FirebaseException(plugin: 'storage', code: 'retry');
    final repository = _repository(storage);

    await expectLater(
      repository.uploadPendingPhoto(await _add(repository)),
      throwsA(isA<FirebaseException>()),
    );
    storage.uploadError = null;
    await repository.uploadPendingPhotos(now: _now);

    expect(storage.contents[_path], _bytes);
    expect(storage.customMetadata[_path], {'kind': 'front'});
    expect(_keptFiles().whereType<File>(), isEmpty);
  });

  test('a photo that is already stored counts as uploaded', () async {
    final storage = FakeFirebaseStorage([_path])..refuseOverwrites = true;
    final repository = _repository(storage);

    await repository.uploadPendingPhoto(await _add(repository));

    expect(_keptFiles().whereType<File>(), isEmpty);
  });

  test('a refused photo that is not stored stays for a later try', () async {
    final storage = FakeFirebaseStorage()
      ..uploadError = FirebaseException(
        plugin: 'storage',
        code: 'unauthorized',
      );
    final repository = _repository(storage);

    await expectLater(
      repository.uploadPendingPhoto(await _add(repository)),
      throwsA(isA<FirebaseException>()),
    );

    expect(_keptFiles().whereType<File>(), hasLength(1));
  });

  test('a retry skips a photo whose upload still runs', () async {
    final storage = FakeFirebaseStorage();
    final repository = _repository(storage);
    final photo = await _add(repository);

    final running = repository.uploadPendingPhoto(photo);
    await repository.uploadPendingPhotos(now: _now);
    await running;

    expect(storage.contents.keys, [_path]);
    expect(_keptFiles().whereType<File>(), isEmpty);
  });

  test('a retry skips a photo whose upload starts while it runs', () async {
    final storage = FakeFirebaseStorage();
    final repository = _repository(storage);
    final photos = [
      await _add(repository),
      await _add(repository, path: 'users/u1/food_photos/p2.jpg'),
    ];
    final first = Completer<void>();
    final second = Completer<void>();
    storage.uploadGates.addAll([first.future, second.future]);

    final retry = repository.uploadPendingPhotos(now: _now);
    // The retry reads its photos from disk first, which the event queue
    // alone does not wait for.
    while (storage.uploads.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    // The retry waits on one photo; the other starts on its own.
    final waiting = storage.uploads.single;
    final other = photos.firstWhere(
      (photo) => !photo.readAsStringSync().contains(waiting),
    );
    final running = repository.uploadPendingPhoto(other);
    first.complete();
    await retry;
    second.complete();
    await running;

    expect(storage.uploads, hasLength(2));
    expect(_keptFiles().whereType<File>(), isEmpty);
  });

  test('retries only the photos of the signed-in user', () async {
    final storage = FakeFirebaseStorage();
    await _add(_repository(storage, ownerId: 'u2'));

    await _repository(storage).uploadPendingPhotos(now: _now);

    expect(storage.files, isEmpty);
    expect(_keptFiles().whereType<File>(), hasLength(1));
  });

  test('deletes a half-kept photo once it is an hour old', () async {
    final folder = Directory('${_folder.path}/u1')..createSync();
    final stale = File('${folder.path}/old.json.tmp')
      ..writeAsStringSync('{')
      ..setLastModifiedSync(_now.subtract(const Duration(minutes: 61)));
    final kept = File('${folder.path}/kept.json.tmp')
      ..writeAsStringSync('{')
      ..setLastModifiedSync(_now);

    await _repository(FakeFirebaseStorage()).uploadPendingPhotos(now: _now);

    expect(stale.existsSync(), isFalse);
    expect(kept.existsSync(), isTrue);
  });

  test('drops a photo that still fails after a week, without a try', () async {
    final storage = FakeFirebaseStorage()
      ..uploadError = FirebaseException(plugin: 'storage', code: 'retry');
    final repository = _repository(storage);
    final old = await _add(repository);
    final recent = await _add(repository, path: 'users/u1/food_photos/p2.jpg');
    old.setLastModifiedSync(_now.subtract(const Duration(days: 8)));
    recent.setLastModifiedSync(_now.subtract(const Duration(days: 6)));

    await repository.uploadPendingPhotos(now: _now);

    expect(old.existsSync(), isFalse);
    expect(recent.existsSync(), isTrue);
    expect(storage.uploads, isEmpty);
  });

  test('deletes a kept photo that does not decode', () async {
    final folder = Directory('${_folder.path}/u1')..createSync();
    final broken = File('${folder.path}/broken.json')
      ..writeAsStringSync('{')
      ..setLastModifiedSync(_now);
    final storage = FakeFirebaseStorage();

    await _repository(storage).uploadPendingPhotos(now: _now);

    expect(broken.existsSync(), isFalse);
    expect(storage.uploads, isEmpty);
  });

  test('deletes the kept photos of every user', () async {
    final storage = FakeFirebaseStorage();
    await _add(_repository(storage));
    await _add(_repository(storage, ownerId: 'u2'));

    await _repository(null).deletePendingPhotos();

    expect(_folder.existsSync(), isFalse);
  });

  test(
    'a token refresh keeps the repository and its running uploads',
    () async {
      final users = StreamController<User?>();
      addTearDown(users.close);
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => users.stream),
          firebaseStorageProvider.overrideWithValue(FakeFirebaseStorage()),
        ],
      );
      addTearDown(container.dispose);
      container.listen(photoUploadRepositoryProvider, (_, _) {});
      // A token refresh emits the same user as a new object.
      _MockUser user() {
        final user = _MockUser();
        when(() => user.uid).thenReturn('u1');
        return user;
      }

      users.add(user());
      await pumpEventQueue();
      final repository = container.read(photoUploadRepositoryProvider);
      users.add(user());
      await pumpEventQueue();

      expect(container.read(photoUploadRepositoryProvider), same(repository));
    },
  );

  test('keeping a photo needs a signed-in user', () {
    expect(() => _add(_repository(null)), throwsStateError);
  });
}
