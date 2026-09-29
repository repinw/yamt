/// Name of the field that holds the encrypted document.
const encryptedPayloadField = 'payload';

/// A map field of one document that is stored as an encrypted payload.
class EncryptedDocumentField {
  /// Creates a field description.
  const new(this.documentPath, this.field);

  /// The document path.
  final String documentPath;

  /// The field name.
  final String field;

  /// Additional authenticated data for the payload of this field.
  String get aad => '$documentPath#$field';
}
