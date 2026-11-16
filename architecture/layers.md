# Layers

Read this when you decide which layer code belongs to, or write a model, a
domain rule, or a controller. Index: [architecture.md](../architecture.md).

The project uses feature-first folders, a few layers inside each feature, and
MVVM with Riverpod.

- **View** (pages, flows, widgets) renders state and forwards input to
  controllers. It MUST NOT contain business rules, persistence, or mapping.
- **Controller** (`Notifier`, `AsyncNotifier`) holds UI state and coordinates
  actions. It is the ViewModel of MVVM.
- **Domain** holds pure Dart models and business rules.
- **Data** talks to Firebase, HTTP, and local storage.
- **Application** (optional) holds services that coordinate several
  repositories or features.

Dependencies point one way: view, then controller, then application, then
domain and data. Data depends on domain. Domain depends on nothing.

- A view MUST NOT call a repository, a service, or Firebase.
- A controller may call a repository directly. NEVER create a service that
  only forwards to one repository method.
- Domain MUST NOT import Flutter, Riverpod, or Firebase. Use `package:meta`
  and `package:collection`, not `package:flutter/foundation.dart`. *Enforced
  by: architecture test.*
- Models map themselves with `@JsonSerializable` (`fromJson`, `toJson`).
  Parse strictly: one type per field, no fallback values.
- Repositories pass Firestore data through `normalizeFirestoreJson`
  (`lib/core/data/firestore_json_normalizer.dart`), which turns `Timestamp`
  into `DateTime`. Date fields read it with one strict `JsonConverter` in
  `lib/core/domain/`. Create it if it does not exist.
- NEVER call `DateTime.now()` in domain, application, or controller code. Pure
  functions take `now` or `today` as a parameter. Providers and controllers
  read the time from `clockProvider` (`lib/core/provider/clock_provider.dart`).
  *Enforced by: architecture test.*
- Domain types and UI state MUST be immutable: `final` fields with
  `copyWith`, or `@freezed`. NEVER mutate a collection in state.
- Prefer `sealed class` and `switch` for closed sets of results, states, and
  exceptions.

## Enforced By

- Architecture test (`test/architecture/architecture_test.dart`): rules
  `clock`, `domain-imports`.
