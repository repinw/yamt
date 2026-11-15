import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/features/inventory/data/sealed_household_document_writes.dart';

const String _storeLogName = 'FirestorePreparedMealTemplateStore';
const String _householdsCollection = 'households';
const String _preparedMealTemplatesCollection = 'prepared_meal_templates';

/// Defines prepared meal template document.
class PreparedMealTemplateDocument {
  /// The prepared meal template document.
  const new({required this.id, required this.data});

  /// The id.
  final String id;

  /// The data.
  final Map<String, dynamic> data;
}

/// Defines prepared meal template store.
abstract interface class PreparedMealTemplateStore {
  /// Read all.
  Future<List<PreparedMealTemplateDocument>> readAll({
    required String householdId,
  });

  /// Watch all.
  Stream<List<PreparedMealTemplateDocument>> watchAll({
    required String householdId,
  });

  /// Writes the template [id] alone; the other templates stay untouched.
  Future<bool> save({
    required String householdId,
    required String id,
    required Map<String, dynamic> data,
  });

  /// Changes the template [id] in a transaction: [change] gets its data and
  /// returns what to write, or `null` to write nothing. Returns whether the
  /// template was written; one that is gone stays gone.
  Future<bool> update({
    required String householdId,
    required String id,
    required Map<String, dynamic>? Function(Map<String, dynamic> current)
    change,
  });

  /// Deletes the template [id] alone.
  Future<bool> delete({required String householdId, required String id});
}

/// Stores prepared meal templates encrypted with the household key [_cipher].
class FirestorePreparedMealTemplateStore
    with SealedHouseholdDocumentWrites
    implements PreparedMealTemplateStore {
  /// The firestore prepared meal template store.
  const new({required this._firestore, required this._cipher});

  final FirebaseFirestore _firestore;
  final PayloadCipher _cipher;

  @override
  Future<List<PreparedMealTemplateDocument>> readAll({
    required String householdId,
  }) async {
    final collection = householdCollection(householdId);
    return _mapDocuments(
      await collection.openAll(await collection.reference.get()),
    );
  }

  @override
  Stream<List<PreparedMealTemplateDocument>> watchAll({
    required String householdId,
  }) {
    final collection = householdCollection(householdId);
    return collection.reference.snapshots().asyncMap(
      (snapshot) async => _mapDocuments(await collection.openAll(snapshot)),
    );
  }

  @override
  Future<bool> update({
    required String householdId,
    required String id,
    required Map<String, dynamic>? Function(Map<String, dynamic> current)
    change,
  }) {
    final collection = householdCollection(householdId);
    final document = collection.reference.doc(id);
    return _firestore.runTransaction((transaction) async {
      final current = await collection.open(await transaction.get(document));
      final next = current == null ? null : change(current);
      if (next == null) {
        return false;
      }
      // Not a set, which would bring back a template deleted meanwhile.
      transaction.update(document, await collection.seal(id, next));
      return true;
    });
  }

  @override
  String get writeLogName => _storeLogName;

  @override
  SealedCollection householdCollection(String householdId) {
    return SealedCollection(
      _firestore
          .collection(_householdsCollection)
          .doc(householdId)
          .collection(_preparedMealTemplatesCollection),
      cipher: _cipher,
    );
  }

  List<PreparedMealTemplateDocument> _mapDocuments(
    List<OpenedDocument> documents,
  ) {
    return documents
        .map(
          (document) => PreparedMealTemplateDocument(
            id: document.id,
            data: document.data,
          ),
        )
        .toList(growable: false);
  }
}
