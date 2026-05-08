import 'dart:async';
import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository.dart';
import 'package:yamt/features/kitchen_utensils/data/'
    'kitchen_utensil_repository_contract.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil_rules.dart';
import 'package:yamt/features/kitchen_utensils/domain/'
    'kitchen_utensil_save_result.dart';

const _mutationServiceLogName = 'KitchenUtensilMutationService';

/// Generates ids for kitchen utensil documents and images.
typedef KitchenUtensilIdGenerator = String Function();

/// Reports whether the owning controller can still write state.
typedef KitchenUtensilMountedReader = bool Function();

/// Writes a sorted kitchen utensil list into controller state.
typedef KitchenUtensilListWriter = void Function(List<KitchenUtensil>);

/// Performs kitchen utensil mutations and related image cleanup.
final kitchenUtensilMutationServiceProvider =
    Provider<KitchenUtensilMutationService>((ref) {
      const uuid = Uuid();
      return KitchenUtensilMutationService(
        repository: ref.watch(kitchenUtensilRepositoryProvider),
        createId: uuid.v4,
      );
    });

/// Saves, updates, and deletes kitchen utensils.
class KitchenUtensilMutationService {
  /// Creates mutation service.
  const KitchenUtensilMutationService({
    required KitchenUtensilRepository repository,
    required KitchenUtensilIdGenerator createId,
  }) : _repository = repository,
       _createId = createId;

  final KitchenUtensilRepository _repository;
  final KitchenUtensilIdGenerator _createId;

  /// Adds a kitchen utensil.
  Future<KitchenUtensilSaveResult> addUtensil({
    required List<KitchenUtensil> previousUtensils,
    required KitchenUtensilMountedReader canWrite,
    required KitchenUtensilListWriter writeUtensils,
    required int weightGrams,
    String name = '',
    Uint8List? imageBytes,
  }) async {
    final normalizedName = normalizeKitchenUtensilName(name);
    if (!isValidKitchenUtensilInput(
      name: normalizedName,
      imageBytes: imageBytes,
      imageStoragePath: null,
      weightGrams: weightGrams,
    )) {
      return const KitchenUtensilSaveResult.failure(
        KitchenUtensilSaveFailureReason.invalidInput,
      );
    }

    final utensilId = _createId();
    final imageStoragePath = await _uploadNewImage(
      utensilId: utensilId,
      imageBytes: imageBytes,
    );
    if (imageBytes != null && imageStoragePath == null) {
      return const KitchenUtensilSaveResult.failure(
        KitchenUtensilSaveFailureReason.imageUploadFailed,
      );
    }
    if (!canWrite()) {
      await _deleteUploadedImage(imageStoragePath);
      return const KitchenUtensilSaveResult.failure(
        KitchenUtensilSaveFailureReason.saveFailed,
      );
    }

    final now = DateTime.now();
    final utensil = KitchenUtensil(
      id: utensilId,
      name: normalizedName,
      imageStoragePath: imageStoragePath,
      weightGrams: weightGrams,
      createdAt: now,
      updatedAt: now,
    );
    final nextUtensils = List<KitchenUtensil>.from(previousUtensils)
      ..add(utensil);

    final saved = await _saveUtensilMutation(
      previousUtensils: previousUtensils,
      nextUtensils: nextUtensils,
      utensil: utensil,
      canWrite: canWrite,
      writeUtensils: writeUtensils,
    );
    if (!saved) {
      await _deleteUploadedImage(imageStoragePath);
      return const KitchenUtensilSaveResult.failure(
        KitchenUtensilSaveFailureReason.saveFailed,
      );
    }
    return KitchenUtensilSaveResult.success(utensilId);
  }

  /// Updates a kitchen utensil.
  Future<KitchenUtensilSaveResult> updateUtensil({
    required List<KitchenUtensil> previousUtensils,
    required KitchenUtensilMountedReader canWrite,
    required KitchenUtensilListWriter writeUtensils,
    required String utensilId,
    required bool imageChanged,
    required int weightGrams,
    String name = '',
    Uint8List? imageBytes,
  }) async {
    final normalizedName = normalizeKitchenUtensilName(name);
    final trimmedUtensilId = utensilId.trim();
    if (trimmedUtensilId.isEmpty || weightGrams <= 0) {
      return const KitchenUtensilSaveResult.failure(
        KitchenUtensilSaveFailureReason.invalidInput,
      );
    }

    final utensilIndex = previousUtensils.indexWhere(
      (utensil) => utensil.id == trimmedUtensilId,
    );
    if (utensilIndex < 0) {
      return const KitchenUtensilSaveResult.failure(
        KitchenUtensilSaveFailureReason.invalidInput,
      );
    }

    final currentUtensil = previousUtensils[utensilIndex];
    var nextImageStoragePath = currentUtensil.imageStoragePath;
    String? uploadedImageStoragePath;
    if (imageChanged) {
      if (imageBytes == null) {
        nextImageStoragePath = null;
      } else {
        uploadedImageStoragePath = await _uploadNewImage(
          utensilId: trimmedUtensilId,
          imageBytes: imageBytes,
        );
        if (uploadedImageStoragePath == null) {
          return const KitchenUtensilSaveResult.failure(
            KitchenUtensilSaveFailureReason.imageUploadFailed,
          );
        }
        nextImageStoragePath = uploadedImageStoragePath;
      }
    }
    if (!canWrite()) {
      await _deleteUploadedImage(uploadedImageStoragePath);
      return const KitchenUtensilSaveResult.failure(
        KitchenUtensilSaveFailureReason.saveFailed,
      );
    }

    if (!isValidKitchenUtensilInput(
      name: normalizedName,
      imageBytes: null,
      imageStoragePath: nextImageStoragePath,
      weightGrams: weightGrams,
    )) {
      await _deleteUploadedImage(uploadedImageStoragePath);
      return const KitchenUtensilSaveResult.failure(
        KitchenUtensilSaveFailureReason.invalidInput,
      );
    }

    final updatedUtensil = currentUtensil.copyWith(
      name: normalizedName,
      imageStoragePath: nextImageStoragePath,
      weightGrams: weightGrams,
      updatedAt: DateTime.now(),
    );
    final nextUtensils = List<KitchenUtensil>.from(previousUtensils);
    nextUtensils[utensilIndex] = updatedUtensil;
    final saved = await _saveUtensilMutation(
      previousUtensils: previousUtensils,
      nextUtensils: nextUtensils,
      utensil: updatedUtensil,
      canWrite: canWrite,
      writeUtensils: writeUtensils,
    );
    if (!saved) {
      await _deleteUploadedImage(uploadedImageStoragePath);
      return const KitchenUtensilSaveResult.failure(
        KitchenUtensilSaveFailureReason.saveFailed,
      );
    }

    final oldImageStoragePath = currentUtensil.imageStoragePath;
    final shouldDeleteOldImage =
        imageChanged &&
        oldImageStoragePath != null &&
        oldImageStoragePath != nextImageStoragePath;
    if (shouldDeleteOldImage) {
      unawaited(_repository.deleteImage(oldImageStoragePath));
    }
    return KitchenUtensilSaveResult.success(trimmedUtensilId);
  }

  /// Deletes a kitchen utensil.
  Future<bool> deleteUtensil({
    required List<KitchenUtensil> previousUtensils,
    required KitchenUtensilMountedReader canWrite,
    required KitchenUtensilListWriter writeUtensils,
    required String utensilId,
  }) async {
    final trimmedUtensilId = utensilId.trim();
    if (trimmedUtensilId.isEmpty) {
      return false;
    }

    final utensilIndex = previousUtensils.indexWhere(
      (utensil) => utensil.id == trimmedUtensilId,
    );
    if (utensilIndex < 0) {
      return false;
    }

    final utensil = previousUtensils[utensilIndex];
    final nextUtensils = previousUtensils
        .where((current) => current.id != trimmedUtensilId)
        .toList(growable: false);
    if (canWrite()) {
      writeUtensils(sortKitchenUtensils(nextUtensils));
    }

    final deleted = await _repository.delete(trimmedUtensilId);
    if (!deleted) {
      if (canWrite()) {
        writeUtensils(sortKitchenUtensils(previousUtensils));
      }
      return false;
    }

    final imageStoragePath = utensil.imageStoragePath;
    if (imageStoragePath != null) {
      unawaited(_repository.deleteImage(imageStoragePath));
    }
    return true;
  }

  Future<String?> _uploadNewImage({
    required String utensilId,
    required Uint8List? imageBytes,
  }) {
    if (imageBytes == null) {
      return Future<String?>.value();
    }
    return _repository.uploadImage(
      utensilId: utensilId,
      imageId: _createId(),
      bytes: imageBytes,
    );
  }

  Future<bool> _saveUtensilMutation({
    required List<KitchenUtensil> previousUtensils,
    required List<KitchenUtensil> nextUtensils,
    required KitchenUtensil utensil,
    required KitchenUtensilMountedReader canWrite,
    required KitchenUtensilListWriter writeUtensils,
  }) async {
    if (canWrite()) {
      writeUtensils(sortKitchenUtensils(nextUtensils));
    }

    try {
      final saved = await _repository.save(utensil);
      if (!saved && canWrite()) {
        writeUtensils(sortKitchenUtensils(previousUtensils));
      }
      return saved;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to persist kitchen utensil mutation.',
        name: _mutationServiceLogName,
        error: error,
        stackTrace: stackTrace,
      );
      if (canWrite()) {
        writeUtensils(sortKitchenUtensils(previousUtensils));
      }
      return false;
    }
  }

  Future<void> _deleteUploadedImage(String? imageStoragePath) async {
    if (imageStoragePath == null) {
      return;
    }
    await _repository.deleteImage(imageStoragePath);
  }
}
