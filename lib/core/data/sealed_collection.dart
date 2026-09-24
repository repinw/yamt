import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/plaintext_document_encryption.dart';
import 'package:yamt/core/data/sealed_document.dart';

/// A document of a [SealedCollection] after decryption.
typedef OpenedDocument = ({String id, Map<String, dynamic> data});

/// A Firestore collection whose documents are stored encrypted.
///
/// Every document holds an encrypted payload plus the [plaintextFields] that
/// queries need. See [sealDocument].
class SealedCollection {
  /// Creates the collection.
  const new(
    this.reference, {
    required this.cipher,
    this.plaintextFields = const <String>[],
  });

  /// The Firestore collection.
  final CollectionReference<Map<String, dynamic>> reference;

  /// The cipher of the documents.
  final PayloadCipher cipher;

  /// The fields that stay readable for queries.
  final List<String> plaintextFields;

  /// Encrypts [data] for the document [id].
  Future<Map<String, dynamic>> seal(String id, Map<String, dynamic> data) {
    return sealDocument(
      data,
      path: reference.doc(id).path,
      cipher: cipher,
      plaintextFields: plaintextFields,
    );
  }

  /// Encrypts every document of [documentsById].
  Future<Map<String, Map<String, dynamic>>> sealAll(
    Map<String, Map<String, dynamic>> documentsById,
  ) async {
    final sealed = await Future.wait(
      documentsById.entries.map((entry) => seal(entry.key, entry.value)),
    );
    return <String, Map<String, dynamic>>{
      for (final (index, id) in documentsById.keys.indexed) id: sealed[index],
    };
  }

  /// Decrypts [snapshot], or returns `null` for a missing document.
  Future<Map<String, dynamic>?> open(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return await openDocument(
      data,
      path: snapshot.reference.path,
      cipher: cipher,
    );
  }

  /// Decrypts every document of [snapshot].
  ///
  /// Throws if one document does not open. Leaving it out would make a later
  /// replace-all treat it as stale and delete it.
  Future<List<OpenedDocument>> openAll(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return Future.wait(
      snapshot.docs.map((document) async {
        final data = await openDocument(
          document.data(),
          path: document.reference.path,
          cipher: cipher,
        );
        return (id: document.id, data: data);
      }),
    );
  }

  /// Throws a [StateError] if a stored document is not sealed.
  ///
  /// A replace-all deletes every document it does not know. Callers run this
  /// first, so a plaintext document that the app could not read is never
  /// deleted as stale.
  Future<void> ensureAllSealed() async {
    final snapshot = await reference.get();
    for (final document in snapshot.docs) {
      if (document.data()[encryptedPayloadField] is! String) {
        throw StateError('${document.reference.path} is not encrypted.');
      }
    }
  }
}
