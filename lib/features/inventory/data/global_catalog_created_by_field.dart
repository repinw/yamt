/// Field that records which user created a global catalog document.
///
/// Firestore rules require it to be the uid of the creating user and keep it
/// unchanged on updates, so junk entries can be traced back to their author.
const globalCatalogCreatedByField = 'created_by_uid';

/// The author field with [uid], or no field when [uid] is not a user id.
///
/// Documents created before the field existed have no author, and an update
/// must keep it that way.
Map<String, Object> globalCatalogCreatedBy(Object? uid) {
  return uid is String && uid.isNotEmpty
      ? <String, Object>{globalCatalogCreatedByField: uid}
      : const <String, Object>{};
}
