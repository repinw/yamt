# Data Layer

Read this when you write or change a repository, a DTO, or other code that
talks to Firebase, HTTP, or local storage. Index:
[architecture.md](../architecture.md).

- **One repository per data area:** one concrete class with its provider in
  `data/<subject>_repository.dart`. It talks to the SDK itself. NEVER add a
  store, gateway, or contract layer between a repository and the SDK.
- **SDK access:** `firebaseFirestoreProvider` and `firebaseStorageProvider`
  (`lib/core/provider/`), `firebaseAuthProvider`
  (`lib/features/auth/data/auth_service.dart`). NEVER call `.instance` in a
  feature. *Enforced by: architecture test.*
- **Data owner:** the repository watches `householdCipherProvider` for
  household data and `userDataCipherProvider` for private data. The first
  gives the active household id, the second the user uid, each with its
  cipher. Both are `null` until the key is ready. Household documents live
  under `households/{householdId}` and are written through `SealedCollection`
  (`lib/core/data/sealed_collection.dart`). NEVER declare a per-feature
  session interface. *Enforced by: architecture test.*
- **Signed out:** Firestore (`null` during sign-out) or the owner id can be
  missing. This is a normal state, not a failure: reads return empty results.
  Writes throw a `StateError`.
- **Interfaces:** only for two production implementations, for example
  `HealthWeightService` with `MobileHealthWeightService` and a stub for other
  platforms. Name the interface by role and the implementation by technology.
  Tests need no interface: a fake can `implement` the concrete class and
  replace it through a provider override.
- **Method names:** `watchX()` returns a `Stream`, `loadX()` a `Future`.
  Writes are `saveX()`, `addX()`, `updateX()`, `deleteX()`.
- **DTO:** create `data/<subject>_dto.dart` only when the stored shape differs
  a lot from the model.
- **Errors:** a repository lets exceptions propagate (see [Errors](errors.md)).

## Enforced By

- Architecture test (`test/architecture/architecture_test.dart`): rules
  `sdk-instance`, `session-interface`.
- `test/architecture/private_data_writers_test.dart`: only the listed files
  write to the private and household collections.
