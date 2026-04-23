# Architecture Overview

This document is a living map of the app.

Use it when you want a fast answer to:
- where the app starts
- how navigation is structured
- which features depend on which other features
- where the current architecture boundaries are

## Generated Graph

- Auto-generated graph: `docs/architecture.generated.md`
- Regenerate with:
  `dart run tool/generate_feature_dependency_diagram.dart`
- The generated graph is import-based, so it is noisier but useful for
  spotting real dependency hotspots.

## How To Read This

- An arrow means "uses" or "depends on".
- An arrow does not mean ownership.
- Example: `Product Search -> Product Nutrition` means product search
  uses nutrition OCR, not that product nutrition is a screen in the
  product search flow.

## App Shell

```mermaid
flowchart TD
  Main[main.dart] --> Scope[ProviderScope]
  Scope --> App[YAMT app.dart]
  App --> MaterialApp[MaterialApp.router]
  MaterialApp --> Router[GoRouter app_router.dart]

  Router --> Welcome[Welcome / Auth Setup]
  Router --> HomeShell[Home StatefulShellRoute]

  HomeShell --> InventoryTab[Inventory]
  HomeShell --> CaloriesTab[Calories]
  HomeShell --> StatisticsTab[Statistics]
  HomeShell --> SettingsTab[Settings]

  Router --> ShoppingList[Shopping List]
  Router --> Household[Household]
  Router --> ReceiptReview[Receipt Review]
  Router --> MealTemplates[Meal Templates]
  Router --> Account[Account]
```

## Feature Dependencies

```mermaid
flowchart LR
  Scanner[Scanner] -->|opens manual selection flow| ProductSearch[Product Search]
  Scanner -->|persists reviewed receipt items| Inventory[Inventory]
  Scanner -->|uses product cache data during resolution| Calories[Calories]

  ProductSearch -->|nutrition label OCR| ProductNutrition[Product Nutrition]
  ProductSearch -->|builds inventory-ready items| Inventory

  Calories -->|reads activity and weight data| Health[Health]
  Calories -->|consumes inventory-backed entries| Inventory

  ShoppingList[Shopping List] -->|household-scoped owner id| Household[Household]
  ShoppingList -->|current signed-in user| Auth[Auth]

  Household -->|auth state and profile| Auth

  Inventory -->|template workflows| MealTemplates[Meal Templates]
```

## Inventory Main Flow

```mermaid
flowchart TD
  Open[Open Inventory tab] --> Page[InventoryPage]
  Page --> Load[InventoryItemsController]
  Load --> Repo[inventoryItemRepository.watchAll]
  Repo --> List[InventoryList]

  List --> FAB[InventoryActionFab]
  FAB --> Sheet[InventoryActionSheetFlow]

  Sheet --> ManualAdd[Manual Add]
  Sheet --> CameraScan[Receipt Camera Scan]
  Sheet --> BatchUpload[Receipt File Upload]

  ManualAdd --> ProductSearch[InventoryReceiptManualProductPage]
  ProductSearch --> PersistManual[Create InventoryItem and persist]

  CameraScan --> Review[Receipt Review Flow]
  BatchUpload --> Review
  Review --> PersistReceipt[Persist reviewed items to inventory]

  List --> Eat[Eat item]
  Eat --> Pending[Create pending inventory consumption]
  Pending --> Direct{Direct calorie save possible?}
  Direct -->|yes| SaveCalories[Save calorie entry]
  Direct -->|no| CalorieEditor[Open calorie entry editor]

  List --> ThrowAway[Throw away item]
  ThrowAway --> PersistDiscard[Persist discard event]

  PersistManual --> Refresh[Inventory controller refreshes state]
  PersistReceipt --> Refresh
  SaveCalories --> Refresh
  CalorieEditor --> Refresh
  PersistDiscard --> Refresh
  Refresh --> List
```

## Current Boundaries

- `main.dart` wires Firebase, app preferences, and the root
  `ProviderScope`.
- `app.dart` builds `MaterialApp.router` and applies app-wide concerns
  like theme and shared receipt listening.
- `app_router.dart` is the navigation hub.
- `scanner` is an orchestration-heavy feature. It pulls together receipt
  input, analysis, candidate resolution, and inventory persistence.
- `product_search` no longer depends on `calories` for OCR.
- `product_nutrition` now owns nutrition label OCR.
- `calories` still depends on `inventory` and `health`, which makes it
  one of the main cross-feature hubs.
- `shoppinglist` is scoped through `household` and `auth`.

## Good Entry Files

- `lib/main.dart`
- `lib/app.dart`
- `lib/core/router/app_router.dart`
- `lib/features/scanner/application/receipt_review_resolution_service.dart`
- `lib/features/product_nutrition/data/nutrition_label_ocr_repository.dart`
- `lib/features/calories/provider/calorie_health_trend_provider.dart`
- `lib/features/shoppinglist/data/shopping_list_repository.dart`

## Next Useful Diagrams

- route map with actual route names
- receipt scan sequence diagram
- inventory eat-to-calorie sequence diagram
- household-scoped data ownership flow
