# Feature Boundaries and Core

Read this when one feature uses another, you add a feature, a workflow touches
several features, or you put code into `lib/core`. Index:
[architecture.md](../architecture.md).

## Feature Boundaries

A feature owns its data access, domain, services, providers, and presentation.

### Feature Order

A feature may import only features that come earlier in this list:

```text
shared (legacy), auth, app_update, household, health, product_nutrition,
recipes, shoppinglist, calories, inventory, kitchen_utensils,
product_search_hub, scanner, ai_chef, meal_templates,
cookbook_new, cooking, activity, diary, progress, data_export, onboarding,
whats_new, home_widget, settings, home
```

- From an earlier feature, import only `domain/`, `data/`, `application/`,
  `presentation/models/`, and the widgets and flows under **Public UI** in its
  README. NEVER import its controllers or other presentation code.
  *Enforced by: architecture test (the README list is checked in review).*
- NEVER import a later feature. If you need to, stop and describe the
  dependency. Changing the order is a user decision. *Enforced by:
  architecture test.*
- A new feature enters the list in the same change, after every feature that
  it imports. *Enforced by: architecture test.*

### Cross-Feature Workflows

- A workflow that changes data of several features lives in `application/` of
  the latest of them. It calls the repositories and services of the earlier
  features directly. Its UI lives in that feature or in a later one.
- NEVER pass callbacks, contracts, or adapters into an earlier feature so that
  it can reach a later one.
- Hubs, pickers, and editors MUST NOT call their caller's controllers or
  persistence. They return the result by popping their route. When an earlier
  feature opens a later feature's hub, arguments and result use types of the
  earlier feature or of `lib/core`.
- A concept that two features need belongs to the earliest feature that owns
  its data. Use `lib/core` only if the concept has no feature dependency.
- `lib/core` MUST NOT depend on features. **Exception:** the composition roots
  `lib/core/router/`, `lib/app.dart`, and `lib/main.dart` may import feature
  pages, route arguments, and the providers that route redirects read.
  *Enforced by: architecture test.*

## Core

`lib/core` holds feature-independent code only: `config/`, `constants/`
(layout tokens, route paths), `data/` (generic storage helpers), `domain/`,
`l10n/`, `router/`, `theme/`, `widgets/`, `utils/`, and infrastructure in
`debug/`, `device/`, `preferences/`, `provider/`.

NEVER move a feature type into `lib/core` to avoid an ownership decision.

## Enforced By

- Architecture test (`test/architecture/architecture_test.dart`): rules
  `feature-order`, `foreign-presentation`, `core-imports-feature`, and the
  test that the Feature Order lists every feature folder once. The test reads
  the Feature Order from this file.
