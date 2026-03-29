import 'dart:async';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

import 'shopping_list_item_store.dart';
import 'shopping_list_repository_contract.dart';
import 'shopping_list_user_session.dart';

const String _repositoryLogName = 'FirestoreShoppingListRepository';

class FirestoreShoppingListRepository implements ShoppingListRepository {
  FirestoreShoppingListRepository({
    required ShoppingListUserSession session,
    required ShoppingListItemStore store,
  }) : _session = session,
       _store = store;

  final ShoppingListUserSession _session;
  final ShoppingListItemStore _store;
  Future<void> _writeBarrier = Future<void>.value();

  @override
  Stream<List<ShoppingListItem>> watchAll() {
    final userId = _currentUserId();
    if (userId == null) {
      return Stream<List<ShoppingListItem>>.value(const <ShoppingListItem>[]);
    }
    return _watchAllForUser(userId);
  }

  @override
  Future<List<ShoppingListItem>> readAll() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const <ShoppingListItem>[];
    }
    return _readAllForUser(userId);
  }

  @override
  Future<bool> saveAll(List<ShoppingListItem> items) {
    final userId = _currentUserId();
    if (userId == null) {
      return Future<bool>.value(false);
    }
    return _runExclusiveWrite(() => _saveAllForUser(userId, items));
  }

  String? _currentUserId() {
    final userId = _session.currentUserId;
    if (userId != null && userId.isNotEmpty) {
      return userId;
    }
    log(
      'No signed-in user for shopping list repository.',
      name: _repositoryLogName,
    );
    return null;
  }

  Stream<List<ShoppingListItem>> _watchAllForUser(String userId) async* {
    try {
      await for (final documents in _store.watchAll(userId: userId)) {
        yield _decodeDocuments(documents);
      }
    } on FirebaseException catch (error, stackTrace) {
      if (_isPermissionDenied(error)) {
        log(
          'Skipping shopping list watch for user $userId: '
          'permission denied by Firestore rules.',
          name: _repositoryLogName,
          error: error,
          stackTrace: stackTrace,
        );
        yield const <ShoppingListItem>[];
        return;
      }
      log(
        'Failed to watch shopping list items for user $userId',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      log(
        'Failed to watch shopping list items for user $userId',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<ShoppingListItem>> _readAllForUser(String userId) async {
    try {
      final documents = await _store.readAll(userId: userId);
      return _decodeDocuments(documents);
    } catch (error, stackTrace) {
      log(
        'Failed to read shopping list items for user $userId',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <ShoppingListItem>[];
    }
  }

  Future<bool> _saveAllForUser(String userId, List<ShoppingListItem> items) {
    final documentsById = <String, Map<String, dynamic>>{
      for (final item in items) item.id: item.toJson(),
    };
    return _store.replaceAll(userId: userId, documentsById: documentsById);
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
      } catch (error, stackTrace) {
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
