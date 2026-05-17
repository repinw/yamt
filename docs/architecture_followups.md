# Architecture Follow-Ups

Context: follow-up list from architecture check against `architecture.md`
after rebasing `master` on `origin/master`.

Verification already run:

- `rtk layerlens --path . --package yamt --only "lib/features" --only "lib/features/**"`
  - No dependency cycles found in generated `DEPS.md` files.
- `rtk flutter analyze`
  - Clean.

## Next Ticket Scope

### Replace new manual Riverpod providers with codegen

- `lib/features/calories/application/burn_week_live_sync_provider.dart`
  - Uses manual `Provider` / `Provider.autoDispose`.
  - `architecture.md` says providers/controllers should use Riverpod codegen.
- `lib/features/inventory/data/inventory_calorie_entry_commit_store.dart`
  - Uses manual `Provider<InventoryCalorieEntryCommitStore>`.
  - Move to `@riverpod` and regenerate code.
- `lib/features/shoppinglist/application/shopping_list_operations.dart`
  - Changed file still uses manual providers.
  - Decide if this stays legacy or gets migrated with this ticket.

### Move inventory action UI out of Home

- `lib/features/home/widgets/inventory_action_fab.dart`
- `lib/features/home/widgets/inventory_action_sheet_flow.dart`

Problem:

- These files are inventory/scanner-specific.
- `lib/features/home/README.md` says Home owns shell navigation/chrome only and
  does not own feature-specific actions or mutation workflows.

Likely fix:

- Move these files to `lib/features/inventory/presentation/`.
- Keep Home receiving the finished action widget from app/router/shell
  composition.

### Fix manual add ownership boundary

- `lib/features/product_search/presentation/inventory_manual_add_page.dart`

Problem:

- Product Search page imports inventory application/data/controllers.
- It persists inventory items and barcode candidates.
- `lib/features/product_search/README.md` says Product Search does not own
  inventory persistence.

Likely fix:

- Move inventory manual-add route/page orchestration back to Inventory.
- Keep Product Search owning only the reusable product lookup/edit surface:
  `InventoryReceiptManualProductPage`.
- Inventory should call Product Search public edge, then perform inventory
  persistence itself.

### Untangle product-search aliases to inventory presentation models

- `lib/features/product_search/presentation/widgets/manual_product_search_page_types.dart`
- `lib/features/product_search/presentation/controllers/manual_product_search_models.dart`

Problem:

- Product Search public result/action types alias Inventory presentation models.
- This blurs ownership and makes Product Search depend on Inventory
  presentation details.

Likely fix:

- Either move shared manual-product result/action types to Product Search, with
  Inventory adapting them at the boundary, or move the whole inventory-specific
  manual product flow to Inventory and keep Product Search result types product
  search-owned.

### Split handwritten calorie goal `part` files

- `lib/features/calories/presentation/widgets/calorie_goal_calculator_flow.dart`
- `lib/features/calories/presentation/widgets/calorie_goal_calculator_flow_layout.dart`
- `lib/features/calories/presentation/widgets/calorie_goal_calculator_flow_steps.dart`

Problem:

- Handwritten `part` files violate `architecture.md` and project rules.

Likely fix:

- Split layout and step widgets/helpers into real Dart files.
- Import concrete files directly.

### Decide app router exception

- `lib/core/router/app_router.dart`

Problem:

- `core/router` imports many feature pages/controllers.
- Existing project pattern, but strict `architecture.md` says core must not
  depend on features.

Decision needed:

- Either document `app_router.dart` as the app composition-root exception, or
  move route assembly out of `core`.

### Remove compatibility re-export if strict cleanup desired

- `lib/features/scanner/domain/receipt_review_item_draft.dart`

Problem:

- Handwritten export points to Inventory-owned draft.
- Useful compatibility edge, but strict rules say avoid hand-written barrel or
  re-export files.

Likely fix:

- Update scanner imports to use
  `lib/features/inventory/domain/receipt_review_item_draft.dart` directly, then
  delete compatibility re-export.
