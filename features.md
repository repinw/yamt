# Features

Current feature map, derived from `lib/features`, app routes, localization keys,
and feature description docs. This is product-facing; architecture rules stay in
`architecture.md`.

## App Shell

- Auth-gated startup flow with splash, welcome, guest setup, and calorie-goal
  onboarding redirects.
- Home shell with bottom tabs for Inventory, Diary, Cookbook, and Settings.
- Responsive page layouts for mobile and wider screens.
- English and German localization.

## Authentication And Account

- Email/password login and registration.
- Google login and registration.
- Guest account login.
- Guest display-name setup with theme color and theme mode choice.
- Guest account linking with Google or email/password.
- Credential conflict handling when a sign-in method is already used.
- Account details, sign out, and account deletion.
- Persisted user profile data for profile-aware UI and household membership.

## Onboarding

- First-run calorie-goal wizard.
- Personal info, activity level, goal weight, goal pace, and start-date steps.
- Goal mode support for losing, maintaining, or gaining weight.
- Start-today and start-later handling, including catch-up placeholder logic.
- Completion gate before the main app opens.

## Diary

- Daily diary page for meals, calorie balance, activity, and weight.
- Date selection and calendar strip navigation.
- Meal sections for breakfast, lunch, dinner, and snacks.
- Quick-eat flow from inventory, prepared meals, or AI/manual product entry.
- Nutrition bars and macro summaries.
- Burn Week balance cards with daily and weekly progress.
- Weekly check-in prompts and success/hint cards.
- Intro flow explaining goal, activity, and learning week behavior.

## Calories And Burn Week

- Manual calorie entry create, edit, details, and delete flows.
- Barcode-based calorie entry lookup.
- Nutrition label scan handoff when barcode products are missing nutrition.
- Calorie goal setup, manual goal edits, and goal-start shifting.
- Calorie calculator using sex, weight, height, age, activity level, goal mode,
  and goal speed.
- Learned TDEE recalculation from tracked data.
- Weekly check-in with weight trend, learned TDEE, target refresh, and blocking
  reasons for missing intake or weight data.
- Burn Week budget model with daily goal, activity credit, carryover, skipped
  days, remaining calories, and details sheet.
- Macro tracking for protein, carbs, fat, and extended nutrient fields.
- Inventory-backed delete/restore behavior for entries created from stock.

## Activity And Weight

- Activity and weight section used by the diary.
- Steps, workouts, burned calories, and manual/imported weight data.
- Weight prompt when useful data is missing.
- Health connection actions from diary-owned surfaces.
- Activity aggregation for calorie and diary calculations.

## Health Integration

- Health Connect and Apple Health connection/disconnection flows.
- Health access status, permission, history, install, and unsupported states.
- Imported steps, workouts, burned calories, and weight data.
- Manual weight repository with per-day overrides.
- Platform stubs for unsupported targets.

## Inventory

- Inventory item list with empty, loading, search, and filter states.
- Add items from receipts, barcode search, manual search, or AI suggestion.
- Inventory item edit, consumption, discard, and delete flows.
- Amount parsing and unit handling for grams, milliliters, pieces, and custom
  serving data.
- Receipt grouping and by-receipt inventory mode.
- Household inventory activity timeline for stock changes.
- Add-to-shopping-list and buy-again actions.
- Prepared meal cards and inventory-backed prepared meal mutation workflows.
- Global food item matching and serving suggestions for future adds.

## Receipt Scanner And Review

- Receipt capture from camera.
- Receipt upload from image or PDF.
- Shared receipt intake from platform share intents.
- Batch receipt processing with queued, processing, done, failed, and reviewed
  states.
- AI receipt analysis and parser pipeline.
- Receipt review page with detected items, prices, receipt date, store, and
  original receipt preview.
- Item review editing for name, brand, category, quantity, unit price, weight,
  unit, deposit/discount state, and discount rows.
- Candidate selection and manual product search from receipt items.
- Receipt price summary for total, savable items, and excluded lines.
- Save reviewed receipt items into inventory.

## Product Search And Manual Add

- Manual product search launcher and product editor.
- Barcode scan lookup with multiple-candidate picker and not-found handling.
- Voice search for manual product text where supported.
- AI food creation from free text, with review draft instead of direct save.
- AI ingredient breakdown, total weight, kcal range, and kcal slider.
- Manual nutrition entry and extended nutrient fields.
- Nutrition quality handling for unverified AI/OCR/manual estimates.
- Barcode-less manual and AI-created food saving.
- Recent manual items for faster repeated entry.

## Product Nutrition OCR

- Nutrition label OCR draft/result models.
- Firebase AI-backed OCR repository.
- OCR response parsing and error mapping.
- Hand-off into manual product form state for review before saving.

## Prepared Meals

- Create and edit prepared meals from inventory ingredients.
- Meal name, portions, cover image, and ingredient amount editing.
- Nutrition display modes for per 100 g/ml, per portion, and total.
- Price display modes for per 100 g/ml, per portion, and total.
- Ready, incomplete, and fully consumed meal states.
- Pending ingredient handling for incomplete meals.
- Eat prepared meal flow with diary day and portions.
- Throw-away portions and return-to-inventory flows.
- Save prepared meal as template.

## Meal Templates And Cookbook

- Saved meal template list.
- Import recipe templates from recipe links, currently centered on Chefkoch.
- Review imported recipe before saving.
- Template detail with recipe image, source, base portions, ingredients, and
  short instructions.
- Portion scaling from base recipe portions.
- Ingredient assignment to inventory items.
- Ignored ingredient support for items like spices.
- Add one or many missing ingredients to shopping list.
- Create prepared meals from templates, including incomplete meals when
  ingredients are missing.
- Template edit, delete, and update flows.

## AI Chef

- Inventory-aware recipe generation with optional free-form preferences.
- Firebase AI-backed structured recipe and cover-image generation.
- Generated recipe review before saving as an editable meal template.

## Cooking Flow

- Prepflow route from meal template detail.
- Inventory check before cooking starts.
- Ingredient assignment, ignore, edit, and conflict resolution.
- Unit conversion prompts and weigh-later option.
- Add missing ingredients to shopping list and continue later.
- Recipe portion scaler.
- Preparation phase with tare/container setup and saved utensil picker.
- Cooking phase with instructions and voice/on-the-fly adjustments.
- Summary phase for base ingredients and unresolved adjustments.
- Finalize phase for storage containers, gross weight, net weight, portion
  split, and ingredient-to-container assignment.
- Save final meal into inventory and resume saved flow sessions.

## Kitchen Utensils

- Kitchen utensil list.
- Add, edit, and delete utensils.
- Name, empty weight, and photo fields.
- Utensil image capture/pick/upload handling.
- Saved utensils available during cooking-flow tare setup.

## Shopping List

- Shopping list page with stats for entries, total quantity, and estimated
  total.
- Quick add with name and optional brand.
- Quantity increase/decrease.
- Cross-off behavior and clear-crossed-off action.
- Firestore-backed list repository.
- Public operations used by inventory, templates, and cooking flow.

## Household

- Household page from settings.
- Join household with invite code.
- Generate, refresh, and copy invite codes.
- Invite-code expiry and validation handling.
- Household members list with leader and current-user badges.
- Remove member, leave household, and leader-only action handling.
- Shared household scope for inventory, shopping lists, utensils, prepared
  meals, and related household-owned data.

## Settings

- Profile card and account entry point.
- Household management entry point.
- Health connection entry point.
- Calorie goal-start and calorie calculator entry points.
- Theme mode selection: light, dark, and system.
- Seed color selection.
- Language display.
- Notifications and privacy placeholders.
- About/app version tile.

## Recipes Support

- Recipe ingredient requirement parsing.
- Recipe ingredient unit modeling and display codes.
- Pending ingredient label formatting.
- Public parser used by inventory, meal templates, and cooking flow.

## Shared UI Support

- Shared auth form widgets for email/password flows.
- Shared credential form constants and reusable auth components.
- Shared app/core widgets for responsive viewports, state views, cached images,
  haptics, nutrition strips, voice search bar, selection list tiles, and home
  shell chrome.
