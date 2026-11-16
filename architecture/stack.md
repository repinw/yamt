# Stack

Read this when you pick an SDK API, a package, or a language feature. Index:
[architecture.md](../architecture.md).

Exact versions are in `pubspec.yaml`. These points differ from older Flutter
code that you may know:

- **Dart 3.13 constructors:** write `const new({super.key})`, not
  `const MyWidget({super.key})`. *Enforced by:
  `unnecessary_type_name_in_constructor`.*
- **New SDK APIs:** `sdk-news.md` lists what Flutter 3.50, Dart 3.14,
  material_ui 1.11 and Riverpod 3.5 added. Read it before you reach for an
  older pattern, and renew it with every SDK upgrade.
- **Riverpod 3** with code generation. Functional providers take a plain
  `Ref ref`. There are no generated `FooRef` types.
- **Material:** import `package:material_ui/material_ui.dart`. NEVER import
  `package:flutter/material.dart`. *Enforced by: architecture test.*
- **go_router** with hand-written routes. `go_router_builder` is not used.
- **Backend:** Firebase (Auth, Firestore, Storage, App Check, Firebase AI).
- **Models:** `json_serializable` for JSON. `freezed` is optional.
- **Lints:** `very_good_analysis`, `riverpod_lint`.
- **Tests:** `flutter_test`, `mocktail`, `fake_cloud_firestore`.
- **Localization:** ARB files, English and German.

NEVER add a package without asking the user. NEVER add an alternative to the
stack (for example `flutter_hooks`, `get_it`, `bloc`, `go_router_builder`, or a
second AI SDK such as `google_generative_ai`).

## Enforced By

- Architecture test (`test/architecture/architecture_test.dart`): rules
  `material-import`, `second-ai-sdk`.
- Lint: `unnecessary_type_name_in_constructor`.
