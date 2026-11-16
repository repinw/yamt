# Where New Code Goes

Read this when you create, move, or name a file. Index:
[architecture.md](../architecture.md).

Paths are relative to `lib/features/<feature>/` unless they start with `lib/`.

| You add                                           | Location                                                         |
| ------------------------------------------------- | ---------------------------------------------------------------- |
| Model, value object, pure calculation             | `domain/`                                                        |
| Exception type that the UI must tell apart        | `domain/<feature>_exceptions.dart`                               |
| Repository and its provider                       | `data/<subject>_repository.dart`                                 |
| Stored shape that differs a lot from the model    | `data/<subject>_dto.dart`                                        |
| Workflow across repositories or features          | `application/<name>_service.dart`                                |
| Page                                              | `presentation/<name>_page.dart`                                  |
| UI flow (sheet, controller call, snackbar, route) | `presentation/<name>_flow.dart`                                  |
| Controller                                        | `presentation/controllers/<name>_controller.dart`                |
| Widget                                            | `presentation/widgets/<name>.dart`                               |
| Widget split into several files                   | `presentation/widgets/<name>/<name>.dart`                        |
| Route arguments, UI model without state           | `presentation/models/`                                           |
| Feature-independent widget, token, or utility     | `lib/core/<area>/`                                               |
| Route                                             | `lib/core/router/`, path in `lib/core/constants/app_routes.dart` |
| User-facing string                                | `lib/l10n/app_en.arb` and `lib/l10n/app_de.arb`                  |
| Test                                              | Same path under `test/`                                          |

- Create a layer folder only when the feature has code for it. A feature has
  no folders besides the four layers. *Enforced by: architecture test.*
- `presentation/` holds `*_page.dart` and `*_flow.dart` files, plus the
  folders `controllers/`, `models/`, and `widgets/`. *Enforced by:
  architecture test.*

## File Names

- Role suffixes: `_page`, `_flow`, `_sheet`, `_dialog`, `_controller`,
  `_state`, `_repository`, `_dto`, `_service`, `_exceptions`, `_route_args`.
- Other widgets end with a plain noun (`_card`, `_tile`, `_row`, `_section`).
  Domain files carry their concept name (`macro_budget_calculator.dart`).
- In features, NEVER use a vague role: `_helpers`, `_support`, `_utils`,
  `_manager`, `_coordinator`, `_handler`, `_logic`, `_workflows`, `_bridge`,
  `_adapter`, `_store`, `_contract`, `_codec`. Name the responsibility
  instead. *Enforced by: architecture test.*

## Enforced By

- Architecture test (`test/architecture/architecture_test.dart`): rules
  `feature-folders`, `presentation-folders`, `flow-placement`, `file-roles`.
