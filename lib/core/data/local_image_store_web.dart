import 'dart:convert';
import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import 'local_image_store.dart';

const _localImageStoreLogName = 'LocalImageStore';
const _localImagePreferencePrefix = 'local_image_store:';

LocalImageStore createPlatformLocalImageStore() {
  return _WebLocalImageStore();
}

class _WebLocalImageStore implements LocalImageStore {
  @override
  Future<void> copyImage({
    required LocalImageRef sourceRef,
    required LocalImageRef targetRef,
  }) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final sourceValue = preferences.getString(_storageKey(sourceRef));
      if (sourceValue == null || sourceValue.trim().isEmpty) {
        await preferences.remove(_storageKey(targetRef));
        return;
      }
      await preferences.setString(_storageKey(targetRef), sourceValue);
    } catch (error, stackTrace) {
      log(
        'Failed to copy local web image '
        'from ${sourceRef.storageKey} to ${targetRef.storageKey}.',
        name: _localImageStoreLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteImage(LocalImageRef imageRef) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_storageKey(imageRef));
    } catch (error, stackTrace) {
      log(
        'Failed to delete local web image ${imageRef.storageKey}.',
        name: _localImageStoreLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Uint8List?> readBytes(LocalImageRef imageRef) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final storedValue = preferences.getString(_storageKey(imageRef));
      if (storedValue == null || storedValue.trim().isEmpty) {
        return null;
      }
      return Uint8List.fromList(base64Decode(storedValue));
    } catch (error, stackTrace) {
      log(
        'Failed to read local web image ${imageRef.storageKey}.',
        name: _localImageStoreLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> saveBytes({
    required LocalImageRef imageRef,
    required Uint8List bytes,
  }) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_storageKey(imageRef), base64Encode(bytes));
    } catch (error, stackTrace) {
      log(
        'Failed to save local web image ${imageRef.storageKey}.',
        name: _localImageStoreLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  String _storageKey(LocalImageRef imageRef) {
    return '$_localImagePreferencePrefix${imageRef.storageKey}';
  }
}
