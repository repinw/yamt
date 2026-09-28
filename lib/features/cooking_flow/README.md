# Cooking Flow Feature

## Purpose

Cooking Flow guides the user from a prepared-meal template to one or more
saved prepared-meal containers: check the Vorrat, prepare containers, cook,
review the ingredients, and weigh and portion the result.

## Owns

- The cookflow session snapshot and its local persistence (`data/`).
- The pure session model and portion distribution (`domain/`).
- Wizard state, ingredient parsing and matching, instruction building,
  inventory conflict resolution, summary and finalize logic, and the session
  service (`application/`).
- The cookflow pages and UI flows at the top of `presentation/`, their
  Riverpod controllers and the page-owned storage container state in
  `presentation/controllers/`, localized messages and view models in
  `presentation/models/`, and the step widgets in `presentation/widgets/`.

## Does Not Own

- Inventory items and prepared-meal persistence (`inventory`).
- Shopping-list persistence (`shoppinglist`).
- Saved kitchen utensils and their management page (`kitchen_utensils`).
- Recipe ingredient parsing (`recipes`).
- The product search hub (`product_search_hub`).

## Rules

- Other features open the cookflow through its route or watch the session
  snapshot. They do not assemble step widgets or controllers.
- Finalize always writes at least one assigned inventory ingredient.
