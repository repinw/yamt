import 'dart:async';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_item_store.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_repository_contract.dart';
import 'package:yamt/features/shoppinglist/data/shopping_list_user_session.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

const String _repositoryLogName = 'FirestoreShoppingListRepository';

/// Defines firestore shopping list repository.
class FirestoreShoppingListRepository implements ShoppingListRepository {
  /// Creates an instance.
  new({required this._session, required this._store});

  final ShoppingListUserSession _session;
  final ShoppingListItemStore _store;
  Future<void> _writeBarrier = Future<void>.value();

  @override
  Stream<List<ShoppingListItem>> watchAll() {
    final householdId = _currentHouseholdId();
    if (householdId == null) {
      return Stream<List<ShoppingListItem>>.value(const <ShoppingListItem>[]);
    }
    return _watchAllForHousehold(householdId);
  }

  @override
  Future<List<ShoppingListItem>> readAll() async {
    final householdId = _currentHouseholdId();
    if (householdId == null) {
      return const <ShoppingListItem>[];
    }
    return await _readAllForHousehold(householdId);
  }

  @override
  Future<bool> saveAll(List<ShoppingListItem> items) {
    final householdId = _currentHouseholdId();
    if (householdId == null) {
      return Future<bool>.value(false);
    }
    return _runExclusiveWrite(() => _saveAllForHousehold(householdId, items));
  }

  String? _currentHouseholdId() {
    final householdId = _session.householdId;
    if (householdId != null && householdId.isNotEmpty) {
      return householdId;
    }
    log(
      'No active household for shopping list repository.',
      name: _repositoryLogName,
    );
    return null;
  }

  Stream<List<ShoppingListItem>> _watchAllForHousehold(
    String householdId,
  ) async* {
    try {
      await for (final documents in _store.watchAll(householdId: householdId)) {
        yield _decodeDocuments(documents);
      }
    } on FirebaseException catch (error, stackTrace) {
      if (_isPermissionDenied(error)) {
        log(
          'Skipping shopping list watch for household $householdId: '
          'permission denied by Firestore rules.',
          name: _repositoryLogName,
          error: error,
          stackTrace: stackTrace,
        );
        yield const <ShoppingListItem>[];
        return;
      }
      log(
        'Failed to watch shopping list items for household $householdId',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to watch shopping list items for household $householdId',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<ShoppingListItem>> _readAllForHousehold(
    String householdId,
  ) async {
    try {
      final documents = await _store.readAll(householdId: householdId);
      return _decodeDocuments(documents);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read shopping list items for household $householdId',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <ShoppingListItem>[];
    }
  }

  Future<bool> _saveAllForHousehold(
    String householdId,
    List<ShoppingListItem> items,
  ) {
    final documentsById = <String, Map<String, dynamic>>{
      for (final item in items) item.id: item.toJson(),
    };
    return _store.replaceAll(
      householdId: householdId,
      documentsById: documentsById,
    );
  }

  List<ShoppingListItem> _decodeDocuments(List<ShoppingListItemDocument> docs) {
    final items = <ShoppingListItem>[];
    for (var index = 0; index < docs.length; index++) {
      try {
        items.add(
          ShoppingListItem.fromJson(
            Map<String, dynamic>.from(docs[index].data),
          ),
        );
      } on Object catch (error, stackTrace) {
        log(
          'Skipping corrupted shopping list item at index $index',
          name: _repositoryLogName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return items;
  }

  Future<T> _runExclusiveWrite<T>(Future<T> Function() operation) {
    final queuedOperation = _writeBarrier.then((_) => operation());
    _writeBarrier = queuedOperation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return queuedOperation;
  }

  bool _isPermissionDenied(FirebaseException error) {
    return error.code == 'permission-denied';
  }
}
