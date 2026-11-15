import 'dart:async';
import 'dart:typed_data';

import 'package:yamt/features/kitchen_utensils/data/kitchen_utensil_repository_contract.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';

/// Keeps the household's kitchen utensils in memory and streams each
/// change asynchronously, like Firestore does.
class FakeKitchenUtensilRepository implements KitchenUtensilRepository {
  /// Starts with [utensils].
  new([List<KitchenUtensil> utensils = const []])
    : utensils = List.of(utensils);

  /// The stored utensils.
  List<KitchenUtensil> utensils;

  final _changes = StreamController<List<KitchenUtensil>>.broadcast();

  @override
  Stream<List<KitchenUtensil>> watchAll() async* {
    yield List.of(utensils);
    yield* _changes.stream;
  }

  @override
  Future<List<KitchenUtensil>> readAll() async => List.of(utensils);

  @override
  Future<bool> save(KitchenUtensil utensil) async {
    utensils = [
      for (final stored in utensils)
        if (stored.id != utensil.id) stored,
      utensil,
    ];
    _changes.add(List.of(utensils));
    return true;
  }

  @override
  Future<bool> delete(String utensilId) async {
    utensils = [
      for (final stored in utensils)
        if (stored.id != utensilId) stored,
    ];
    _changes.add(List.of(utensils));
    return true;
  }

  @override
  Future<String?> uploadImage({
    required String utensilId,
    required String imageId,
    required Uint8List bytes,
  }) async => null;

  @override
  Future<bool> deleteImage(String imageStoragePath) async => true;

  @override
  Future<String?> imageUrl(String imageStoragePath) async => null;
}
