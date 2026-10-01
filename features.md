# Features

Current feature map, derived from `lib/features`, app routes, localization keys,
and feature description docs. This is product-facing; architecture rules stay in
`architecture.md`.

## App Shell

- Startup flow with splash, welcome, and calorie-goal onboarding redirects.
  Without an account the app opens the onboarding intro: at startup, after a
  sign-out or account deletion, and when the session ends. The intro's login
  button opens the welcome page.
- Home shell with bottom tabs for Inventory, Diary, Cookbook, and Settings.
  The tab header and the bottom navigation stay in place while a tab
  scrolls. In the middle of the bar a round lime button opens the actions of
  the current tab, with a haptic pulse; its word changes per tab
  ("Hinzufügen", "Essen"). The Cookbook and Fortschritt have no button yet.
  The actions open like the side menu, but mirrored: the page slides to the
  left and shrinks, and the actions stand at the bottom right, where the
  thumb is. The app counts on the device how often each action is tapped;
  the most used action of the panel gets a lime icon tile. The order stays
  fixed.
- Vorrat actions: barcode, search, AI, an own product, and a receipt as photo
  or upload (the photo only where a camera is available).
- Responsive page layouts for mobile and wider screens.
- English and German localization.

## Authentication And Account

- Email/password login and registration.
- Google login and registration.
- Guest account, created only when the user finishes onboarding. Opening the
  app without finishing creates no Firebase user.
  Without a connection the last page says so and keeps every answer for
  another try.
- The app asks for a display name only when the user joins a household
  without one.
- Guest account linking with Google or email/password.
- Credential conflict handling when a sign-in method is already used.
- Account details, sign out, and account deletion.
- When a Firebase account is deleted (account deletion, or an account dropped
  in a sign-in conflict), a Cloud Function removes its data: the profile with
  all private data (diary, weight, goals, keys), its Storage files, its member
  and key entries in every household, and each household it was the last
  member of, with that household's images and invites. A shared household
  stays for the others; when the admin leaves, the member who joined first
  becomes admin. Contributions to the global food catalog (foods, votes,
  serving sizes, product photos) stay.
- Persisted user profile data for profile-aware UI and household membership.
- End-to-end encryption of private health data (diary entries, weight, calorie
  goals and body data, Burn Week state, own product corrections) with a
  per-user key. The server stores only ciphertext.
- Recovery key: a real account gets one after creation or after linking a
  guest. It is shown under Account, with a hint until the user saves it in the
  password manager (Android) or marks it as saved. It never blocks the app.
- A new device of the same platform account restores the key without asking:
  Google Block Store on Android, iCloud Keychain on iPhone. Only when that
  fails (platform switch, no backup) the app asks for the recovery key before
  anything else; without it the user can start fresh, which deletes the old
  private data. It also drops the user's household keys: a household where
  the user is alone loses its data and images and gets a new key; in a
  household with other members the data stays and one of them unlocks it
  again (see Household).

## Onboarding

- First-run intro with a welcome page offering start or login.
- Explaining pages for calories in against calories out, the first estimate, the
  weekly correction, why the correction reads the weekly trend, how the goal
  shifts the target, and what the kitchen features do.
- Input pages for gender and birthday, height and weight, target weight, goal
  pace, weekly activity level, and training days, with scroll wheels instead of
  keyboards.
- Weekly activity in four steps that count everyday movement and training
  together, like the activity levels in the calorie settings. Training days only
  spread the weekly budget: they get more, rest days less.
- Goal mode derived from target weight. Leaving the target wheel untouched keeps
  the current weight, and the pace page is skipped for maintain.
- Estimated day the target weight is reached, plus ambitious-pace and
  minimum-goal warnings.
- Summary with the calculated daily expenditure, the resulting intake target, and
  the targets of training and rest days.
- Start day choice on the summary: today, tomorrow, or another day up to two
  weeks ahead. Before noon today is proposed, from noon on tomorrow. The start
  day counts fully for learning. Days before a later start are practice days in
  the diary: the normal daily card with kcal and macros runs against the goal
  that starts later, marked with a "Practice day · counts from …" badge. Nothing
  counts yet, and Burn Week starts on the start day.
- Completion gate before the main app opens.

## Diary

- Daily diary page for meals, calorie balance, activity, and weight.
- Date selection and calendar strip navigation. Swiping the diary slides to
  the previous or next day. The top bar shows today, yesterday, or the weekday
  in small capitals over the date, and the day type as a framed chip.
- A day without logged food shows a short hint that points to the "Essen"
  button.
- Meal sections for breakfast, lunch, dinner, and snacks.
- Tapping a logged entry opens its item details in the food label look of
  the eat page: image, brand and name, the nutrition label per 100 g or ml
  and for the eaten amount, and the amount on the ruler. "Save" stores a
  changed amount, with totals from the entry's per-100 values, and closes
  the page. The day and meal menu top right moves the entry at once. The
  "Entry" card logs the food again or removes the entry; an entry from the
  Vorrat asks whether its stock goes back. A changed amount moves the stock
  of a Vorrat entry too, and every change offers an undo. Prepared meals and
  combined entries list their foods instead of the ruler.
- Quick-eat flow from inventory, prepared meals, or AI/manual product entry.
  Its actions open from the "Essen" button in the middle of the bar: barcode
  first, then Vorrat, quick entry, AI, and search.
- Quick entry ("Schnell" in the actions) logs calories typed in by hand, without
  a food or a Vorrat item, on a page in the food label look with day and meal
  top right. Only the calories are required; the name defaults to "Quick
  entry", and protein, carbs, and fat are optional and count as 0 g when left
  empty. While a macro is empty, a quiet hint points to the more precise AI
  estimate and opens it for the same day and meal. The entry shows no amount
  in the diary, moves between days and meals like any entry, and its amount
  cannot be edited.
- Daily head in the food label look, without a card frame: the kcal left as a
  big number over a ruler, whose bar has four equal quarters of the target
  that fill in order. It is quiet by default; a tap shows eaten and target,
  base and carryover, and the eaten grams per macro.
- Nutrition bars and macro summaries: each macro shows its label, a bar of four
  segments, and the grams left. A macro above its target shows `+X g over` and
  stripes the overage share at the end of its bar.
- Burn Week balance cards with daily and weekly progress.
- Weekly check-in prompts and success/hint cards.
- Side menu from the diary top bar. The page slides to the right as a
  shrunken card and the menu shows behind it: the user, then Profile, goal
  archive, household (You), kitchen utensils, shopping list (Kitchen),
  settings, about (App), and "Link account" for guests at the bottom.
  Tapping the card or back closes it.
- Profile page from the side menu:
  - who the user is (name or email, guest mode);
  - the trend weight as the main number, a 14-day chart with weigh-ins as
    dots and the trend as a line, the last weigh-in with its day ("today",
    "yesterday", "3 days ago"), the start weight of the goal, the weekly
    trend, and a button to weigh in;
  - tiles for height, age with birthday, sex, training days with the extra
    kcal, the macro weight with the day since it applies, and the daily
    expenditure (learned or estimated);
  - tapping height, birthday, or sex, or the start weight while no TDEE is
    learned, opens an editor. It shows what changes before it saves: with a
    learned TDEE the calorie goal stays and only the macros follow; without
    one the edit corrects the goal from its start and the calorie goal is
    calculated again.
  - the training tile shows the training days of the current 7-day run.
    Tapping it picks them for this run only, like a day type in the diary;
    the editor shows each changed day's calorie goal, the other days that
    give or take calories, and the run total, which stays the same, before it
    saves.

## Calories And Burn Week

- Manual calorie entry create, edit, details, and delete flows.
- Amount changes on a logged entry, with undo. An entry logged from the
  inventory moves the stock with it when the item is measured in grams or
  milliliters.
- Barcode-based calorie entry lookup.
- Nutrition label scan handoff when barcode products are missing nutrition.
- Calorie goal setup, manual goal edits, and goal-start shifting.
- Calorie calculator using sex, weight, height, age, activity level, goal mode,
  and goal speed. Once the body data is known, setting a new goal lists sex,
  height, and age as a plain list with "Edit in profile" instead of asking
  them again; the link closes the goal sheet and opens the profile page. The
  learned TDEE goal sheet shows the same list.
- Learned TDEE recalculation from tracked data.
- Weekly check-in with weight trend, learned TDEE, target refresh, and blocking
  reasons for missing intake or weight data.
- Burn Week budget model with daily goal, activity credit, carryover, skipped
  days, remaining calories, and details sheet.
- Macro tracking for protein, carbs, fat, and extended nutrient fields.
- Protein and fat targets in g/kg: 1.6 g protein, 2.0 g while losing weight
  with training; 0.8 g fat for men, 0.9 g for women. The training days decide
  until the user sets sport in the macro settings. Carbs get the rest of the
  kcal, but at most 40 percent. What lies above that on the weekly average
  goes to protein up to 2.0 g/kg, so protein stays the same every day; the
  rest goes to fat. A custom protein value stays as set. A positive carryover
  keeps the same cap for the day's kcal and gives the rest to fat. Above a BMI of 25 only 40 percent
  of the extra weight counts (adjusted body weight), so heavy users get
  realistic targets. Those users see the adjusted weight and a medical
  disclaimer on the onboarding summary and in the macro settings. No training
  days are preset.
- The body weight for the protein and fat targets follows the user week by
  week. Each 7-day check-in saves the trend weight of its last day, also when
  the user keeps the old calorie goal, and a new calculated goal saves its
  start weight. A day uses the latest of these on or before it, so the macros
  stay fixed within a week and past days keep their targets.
- Inventory-backed delete/restore behavior for entries created from stock.

## Fortschritt

- Fortschritt tab with two chips, "Aktuelles Ziel" and "Gesamt".
  "Aktuelles Ziel" covers the current goal from its start (at least 7 days
  for the charts); "Gesamt" covers all goals from the first start, hides the
  goal card and the run, and marks each goal start ("Ziel 2") in the weight
  and TDEE charts. From top to bottom:
  - the goal ("Lose weight to 78 kg"), a four-part bar of the way from the
    start weight to the target by trend weight, the kg to go and the pace,
    the daily calories with protein, carbs, and fat, and a button to the goal
    archive;
  - the current 7-day run, headed "Run 3 · Tag 2 von 7": the average kcal
    per day as the main number with the goal, the week budget (eaten of the
    run's total, one segment per day, kcal left), and one row per day with
    weekday, day type emoji, a bar of four quarters of the day's goal, and
    the eaten kcal. The bars fill in the
    macro colors (protein red, carbs blue, fat yellow) by kcal share; the part
    over the goal is hatched orange. Under them the average grams per macro
    against their goals;
  - the weight trend: weigh-ins as squares, the trend as a line through gaps,
    the trend per week, and the day the trend reaches the goal weight;
  - the TDEE per weekly check-in: the calculator estimate at the goal start,
    then one point per check-in the user confirmed, and a dashed line to the
    next check-in. A declined check-in keeps the old value and shows the
    calculated one as a hollow point;
  - training days against rest days up to yesterday: days of each,
    and average kcal, protein, carbs, and fat.

## Activity And Weight

- Activity and weight section used by the diary.
- Manual and imported weight data.
- Weight prompt when today has no weight, on today's diary page. Dismissing it
  hides it for that day.
- Health connection actions from diary-owned surfaces.

## Health Integration

- Health Connect and Apple Health connection/disconnection flows.
- Health access status, permission, history, install, and unsupported states.
- Imported weight data.
- Manual weight repository with per-day overrides.
- Platform stubs for unsupported targets.

## Inventory

- The Vorrat is one flat list of foods and prepared meals. The header shows
  "Vorrat" with the count of foods and meals in stock above it. Next to the
  search field sit "Sortieren" and a Liste/Kacheln button; Kacheln shows a
  grid of small tiles for a quick overview. While the list scrolls, the
  header scrolls away and the search row with both buttons stays at the top;
  in selection mode the header stays, because it holds the selection actions.
- Quick filter chips with counts: Alle, Offen (partly used), Mahlzeiten, Fast
  leer (under a quarter left). The chip starts at Alle on every visit.
- Each row shows a tilted, framed picture (photo, ingredient photos of a
  meal, or the first letter), the name, the amount left and the full amount,
  brand and kcal per 100 g (for a meal its portions or its missing
  ingredients; "Aus Rezept" or "Kombiniert" names where a meal comes from), and a stock bar with one segment per pack, or per portion for
  a meal. Under a quarter left the amount and the bar turn orange with "fast
  leer".
- The Sortieren sheet sorts by added, eaten, name or amount; tapping the
  chosen field again flips its direction. Until the user changes it, the
  list sorts by last eaten, newest first. It also holds "Verbrauchte
  ausblenden" and "Nach Beleg". Changes apply at once and survive a restart.
- Add items from receipts, barcode search, manual search, or AI suggestion.
- Inventory item edit, consumption, discard, and delete flows.
- Tapping an item row opens the item hub: the food label eat page plus an
  "Item" card with add to shopping list, edit, replace product, and remove.
  Action dialogs open over the hub, so cancelling one returns to it. A
  finished edit, replace or remove closes the hub; adding to the shopping
  list keeps it open. A used-up item shows only the card, and its main
  button adds it to the shopping list. Rows have no action buttons of their
  own.
- The item hub can log other stock items together with its item: "+ Combine
  with another food" opens the Vorrat list in selection mode (only items with
  nutrition values and stock, counted in grams or milliliters). Picked items
  join with 100 g or ml; tapping a food's row opens a ruler for its amount.
  The hub then shows all foods' images side by side in its header (the rows
  carry no images), the meal name, and one
  nutrition label for the whole meal, per 100 g and in total ("–" when one
  food lacks a value; no per-100 column when grams and milliliters mix),
  and the main button "In Vorrat" keeps the picked foods in stock as one
  prepared meal "A + B" with one portion. The grey "Mahlzeit eintragen"
  saves one combined diary entry named "A + B" instead. The entry and
  every stock change are written together. A combined entry cannot change its
  amount or be eaten again; deleting it can return the stock of every food.
  While other foods are picked, the Item card hides "Bearbeiten". A food found by search that is not
  counted in grams or milliliters still gets its amount on the eat page,
  whose button reads "Add".
- Amount parsing and unit handling for grams, milliliters, pieces, and custom
  serving data.
- Receipt grouping ("Nach Beleg" in the Sortieren sheet).
- Household inventory activity timeline for stock changes.
- Add-to-shopping-list and buy-again actions.
- The picture of a food or meal flies from its row into the page it opens.
- A long press selects foods; "Lebensmittel kombinieren" opens the item hub of the first
  selected food with the others already combined, so the meal is logged or
  kept in the Vorrat there.
- Tapping a prepared meal opens its detail page: the meal eat page plus a
  "Zutaten" box (every ingredient with picture and its amount in the whole
  meal; missing recipe ingredients in orange with "Zutat ergänzen" and "Zutat
  ignorieren") and a "Mahlzeit" card with edit, save as recipe, unbundle and
  throw away. A meal with missing ingredients can be logged once they are
  filled or ignored.
- Editing a meal opens the meal editor, drawn like the eat page: picture
  (tap for camera, gallery or remove) and name, one row per ingredient with
  a ruler for its amount and a remove button, "+ Lebensmittel hinzufügen"
  (stock foods only, 100 g or ml each), the portions and the nutrition label
  of the edited meal. Once portions are eaten, only name and picture change.
- Global food item matching and serving suggestions for future adds.

## Receipt Scanner And Review

- Receipt capture from camera.
- Receipt upload from image or PDF.
- Shared receipt intake from platform share intents.
- Batch receipt processing with queued, processing, done, failed, and reviewed
  states.
- AI receipt analysis: photos and PDFs go straight to a Firebase AI server
  prompt template (`receipt-parse-template`), so the prompt can change
  without an app release. Overlapping photos of one long receipt are merged.
- Lines that are clearly not food (bags, drugstore and cleaning products, pet
  food) start deselected in the review; the user can select them again.
- Unmatched lines show a readable product name; the printed receipt text
  stays visible and is used to learn product matches.
- Receipt review page with detected items, prices, receipt date, store, and
  original receipt preview.
- Item review editing for name, brand, category, quantity, unit price, weight,
  unit, deposit/discount state, and discount rows.
- Candidate selection and manual product search from receipt items.
- Receipt price summary for total, savable items, and excluded lines.
- Save reviewed receipt items into inventory.

## Product Search And Manual Add

- One product search page with barcode, AI, and own-product actions, and the product editor.
- Barcode scan lookup with multiple-candidate picker and not-found handling.
- Voice search for manual product text where supported.
- AI food creation from photos and/or a description (one of both is
  enough), with quick phrases such as "large portion". The server prompt
  template `food-estimate-template` can change without an app release.
- The AI result opens on the eat page: photo, name, nutrition label, amount
  ruler with the estimated portion, the ingredients with grams and kcal, and
  lean / normal / rich chips that shift the energy. Confirm logs the food
  when opened from the diary and adds it to the Vorrat otherwise; "Analyze
  again" returns to the input.
- The product editor looks like the eat page: image, brand and name as
  inputs, package size with a unit switch, and the nutrition label with an
  input per 100 g. All seven values of the EU label (energy, fat, saturates,
  carbohydrate, sugars, protein, salt) are required; a missing one is
  framed. Polyunsaturates and fibre come from the "+" row.
- Two photo tiles fill the editor: the package front (server template
  `product-front-template` reads name, brand, and package size) and the
  nutrition table (`nutrition-label-template`). The barcode scanner looks at
  both photos first; only without a result does the barcode the AI read on
  the front count, marked "please check". Otherwise the user scans the
  barcode or marks "has none". Saving needs a barcode or that mark.
- On save both photos go to Firebase Storage under
  `product_images/{uid}/{photoId}/`, readable by every signed-in user. The
  front photo becomes the product image when the product has none. A failed
  upload saves the product without photos and says so.
- Nutrition quality handling for unverified AI/OCR/manual estimates.
- Barcode-less manual and AI-created food saving.
- "Create" opens an empty product form. Name, unit, and the seven EU label
  values are required; confirming a required field on the keyboard jumps to
  the next empty one.
- The barcode row has a scan button and a "has none" mark. Scanning an
  unknown barcode keeps the entered values.
- Going back from the eat dialog after "Create" reopens the product form.
- Eating a newly picked product has no stock limit: the stock is set to the
  eaten amount. A product with g or ml but no package size is eaten in that
  unit. The eat page always shows the per-100 column.
- Recent manual items (up to 20) shown while the search query is empty.
- Several products can be added in one visit; a counter overlay shows them.

## Product Nutrition OCR

- Nutrition label OCR draft/result models.
- Firebase AI server prompt template `nutrition-label-template`, so the
  prompt can change without an app release.
- A scan succeeds only when every mandatory EU value per 100 g or 100 ml is
  read (energy in kJ and kcal, fat, saturates, carbohydrate, sugars, protein,
  salt) and the values are plausible. Otherwise the user is asked for a new
  photo, with a "New photo" action; partial or guessed values are never
  filled in.
- Hand-off into manual product form state for review before saving.

## Prepared Meals

- Create and edit prepared meals from inventory ingredients.
- Meal name, portions, cover image, and ingredient amount editing.
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
- Firebase AI-backed structured recipe and cover-image generation. The
  recipe comes from the server prompt template `ai-chef-recipe-template`,
  which can change without an app release.
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
- Household data (inventory, shopping list, prepared meals, recipes, kitchen
  utensils, discard and activity events, and their images) belongs to the
  household, not to one person. Every user always has an own household.
- Exactly one admin per household. The admin invites and removes members and
  hands the lead to another member ("Make admin"). The members list shows the
  admin badge and marks the current user.
- Invite with a QR code or a link (`yamt://household/join`), for one person
  and valid for 24 hours. Joining uses the invite up. The link carries a secret that the server never sees. Only a
  verified admin invites; a guest admin sees a hint to link the account.
- Join by scanning the QR code, pasting the link, or opening the link, while
  alone in the own household. Joining switches to the shared household; the
  own household pauses untouched and comes back when the user leaves.
- Invite expiry and validation handling.
- Leave: the shared items stay in the household. An admin who leaves while
  others remain hands the lead on first: the dialog proposes the member who
  joined first and lets the admin pick another. An admin who leaves the own
  household gets a new, empty one. After the last member leaves, a Cloud
  Function deletes the household with all its data and images. When the household changes while
  the user leaves (another member leaves, joins, or hands over the lead at
  the same time), leaving stops with a message to check the household again.
- The admin removes members to stop sharing and keeps everything. A removed
  member's app notices it and goes back to the own household. A member
  removed from the household that was their own gets a new, empty one.
- End-to-end encryption of household data with a household key. Each member
  holds the key wrapped with their own data key.
- Unlock after a fresh start: a member who started fresh lost their key
  entry. The other members see a hint and create a one-time unlock code; the
  member enters it on the household page and gets the key back. When the
  others leave before anybody unlocked it, the household data is wiped and a
  new key follows.
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
