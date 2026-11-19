# Features

Current feature map, derived from `lib/features`, app routes, localization keys,
and feature description docs. This is product-facing; architecture rules stay in
`architecture.md`.

## App Shell

- Startup flow with splash, welcome, and calorie-goal onboarding redirects.
  Without an account the app opens the onboarding intro: at startup, after a
  sign-out or account deletion, and when the session ends. The intro's login
  button opens the welcome page.
  When the app cannot tell whether a signed-in user has a goal (for example
  offline on a new device), it shows a "try again" page instead of sending the
  user into onboarding. An account can also sign out there, so settings that
  never load (for example a broken stored document) are no dead end; a guest
  gets no sign-out there, because it would lose its data.
- Home shell with bottom tabs for Inventory, Diary, Cookbook, and Settings.
  The tab header and the bottom navigation stay in place while a tab
  scrolls. In the middle of the bar a round button in the accent color opens
  the actions of the current tab, with a haptic pulse; its word changes per
  tab ("Hinzufügen", "Essen", "Kochen", "Erfassen").
  The actions open like the side menu, but mirrored: the page slides to the
  left and shrinks, and the actions stand at the bottom right, where the
  thumb is. The app counts on the device how often each action is tapped;
  the most used action of the panel gets an icon tile in the accent color.
  The order stays fixed.
- Vorrat actions: barcode, search, AI, an own product, and a receipt as photo
  or upload (the photo only where a camera is available).
- Back with the keyboard open: on Android the first back button or back
  gesture only closes the keyboard and keeps what was typed; the next back
  leaves the page, sheet, or dialog. Close buttons close at once.
- App updates: the release sets a minimum and a latest version in
  `config/app_version`. An app older than the minimum shows only an "Update
  yamt" page; while the check loads, fails, or no version is set, the app
  opens. Migrations added from now on wait for the check. An app older than the latest version
  shows a snackbar "yamt <version> is available" once per version. "Update"
  opens Google Play on Android and TestFlight on iOS.
- What's new: after an update, the app shows once per version a notice "New
  in <version>: <first new point>" at the top, once the app is on its home
  pages. "See all" opens a sheet with what is new, improved, and fixed, in
  the device language. A fresh install shows nothing; a device counts as
  updated when an account finished the onboarding on it.
- Each device saves its app version, platform, and last start (at most once a
  day) in `users/{uid}/clients/{installId}`, so a release can count the
  devices that still run an old version before it removes a migration.
- Offline hint: while the device has no network connection (flight mode
  without Wi-Fi), a thin strip "Offline – keine Verbindung" stands under the
  status bar on every page; screen readers announce it. When the connection
  returns, the strip goes and a short snackbar "Wieder online" shows. A start
  with a connection shows nothing. The app reads the connections of the
  device (`connectivity_plus`), not whether a server answers: Wi-Fi without
  internet counts as online.
- Responsive page layouts for mobile and wider screens.
- English and German localization.

## Authentication And Account

- Email/password login and Google login. The welcome page has no
  registration form; a new user starts as a guest and creates an account by
  linking the guest account. Google login with a Google account the app does
  not know yet still creates a new account.
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
- Steps from Health Connect or Apple Health, only to look at: a narrow card
  under the daily budget shows the steps of the day and one slot per day of
  the run week, which fill day by day. A tap on the card opens its menu
  with the "Schrittziel" (minus and plus in steps of 500, or 5.000, 7.500
  and 10.000 with one tap). With a goal the card names it, a line fills up
  to it, a full slot is the goal, the card shines in gold foil once the day
  reaches it, and a flame shows at twice the goal. After a week whose seven
  days met the goal on average, today's card asks whether the goal goes up
  by 100 steps a day. Off until the user turns on "Schritte im Tagebuch" in
  the settings; turning it on connects Health when needed.
- Date selection and calendar strip navigation. Swiping the diary slides to
  the previous or next day. The top bar shows yesterday, today, tomorrow, the
  day after tomorrow, or the weekday in small capitals over the date.
- The diary opens with today again (#753): after the user comes back from
  another tab, and when the app returns after at least 5 minutes in the
  background or on a new date. A shorter absence, such as a camera photo or a
  permission prompt, keeps the chosen day, and a plan saved just now still
  opens its day.
- A normal day is the baseline. The training and pause buttons at the top
  right of the daily card toggle the shown day; no pressed button is a
  normal day ("Normaler Tag", formerly "Ruhetag"). The buttons show only
  while a calorie goal exists. The day type picked here is outside the plan:
  an extra training day gets one session (250 kcal by default) more, a
  planned training day made normal one session less, and the other days of
  the week keep their goals, so the week's total moves by one session.
- A day without logged food shows a short hint that points to the "Essen"
  button. On a future day the hint says that nothing is planned yet.
- Meal sections for breakfast, lunch, dinner, and snacks.
- Tapping a logged entry opens its item details in the food label look of
  the eat page: image, brand and name, the nutrition label per 100 g or ml
  and for the eaten amount, and the amount on the ruler. The main button
  "Nochmal" logs the food again; when the Vorrat holds the food (the
  entry's own pack, a pack with its barcode, or one with its name and
  brand), it first asks "Vom Vorrat abziehen?" with the packs to pick from,
  or "Nicht abziehen". A picked pack gives at most what it has left; when
  it runs empty the message says so, and the undo gives the stock back
  (#326). Once the amount changed the button reads
  "Speichern" and stores the amount, with totals from the entry's per-100
  values, and closes the page. An icon beside it removes the entry (an entry
  from the Vorrat asks whether its stock goes back); "Planen" next to the
  day and meal at the top plans the food again for a picked day. A prepared
  meal's portions offer only removing. The day
  and meal menu top right moves the entry at once. A changed amount moves the stock
  of a Vorrat entry too, and every change offers an undo. Prepared meals and
  combined entries list their foods instead of the ruler.
- Quick-eat flow from inventory, prepared meals, or AI/manual product entry.
  Its actions open from the "Essen" button in the middle of the bar: barcode
  first, then Vorrat, quick entry, AI, and search. On a future day a food
  found by barcode, AI, or search is saved as a plan with undo, and it does
  not go into the Vorrat.
- Quick entry ("Schnell" in the actions) logs calories typed in by hand, without
  a food or a Vorrat item, on a page in the food label look with day and meal
  top right. Only the calories are required; the name defaults to "Quick
  entry", and protein, carbs, and fat are optional and count as 0 g when left
  empty. While a macro is empty, a quiet hint points to the more precise AI
  estimate and opens it for the same day and meal. The entry shows no amount
  in the diary, moves between days and meals like any entry, and its amount
  cannot be edited. On a future day it saves a plan instead, with undo, and
  the AI hint is hidden. On today or a past day, the "Planen" button next to
  the day and meal plans it for a picked day, today included; without the
  calories, the button only asks for them. Accepting the plan makes it a normal
  quick entry; no Vorrat is taken.
- Daily budget card (#907), set in Geist: the kcal left as a big number
  with "kcal übrig" and a line with a goal marker, and next to it protein,
  carbs, and fat with the grams left and a thin line each. When the day's
  eaten plus open planned kcal land within ±5 % of the kcal target (#945),
  the card becomes a gold trophy: it tilts a little with the phone (held in
  the hand or lying on the table), fine gold glitter sparkles slowly and
  faster while the phone moves, and a gold sheen follows the light. Open
  plans count here even when "Nach Plan" is off. Never on a pause day or a
  day that does not count; Reduce Motion keeps the card still. A long press on
  the card opens its menu "Tagesbudget" (#928) with the switch
  "Soll-Strich" (off by default, saved on the device). While it is on,
  today's kcal line gets a small triangle with a thin stroke where the day
  should be by now, moving on every minute, and each meal heading shows its
  counted kcal against its part of the day's goal ("420 / 500 kcal"); a
  meal set to 0 % and a pause day keep the plain heading. Below the switch,
  while it is on, the menu shows the parts of the day that set the marker:
  handles on the borders of framed blocks move the meals' shares in whole
  percent (by default Frühstück 25 %, Mittagessen 35 %, Abendessen 30 %,
  Snack 10 %; a meal pushed to 0 % shows "Aus"), and "Tagesbeginn ab 06:00"
  and a "bis" time per meal (by default 09:00, 13:00, 19:00, 21:00) open a
  time picker; a time moved past its neighbours pushes them along. Nothing
  is due before the day starts, each meal's share is due by its time, and
  the marker rises evenly in between (13:00 = 60 % by default).
  "Zurücksetzen" restores the default shares and times. Shares and times
  are saved on the device. Below them, also only while the marker is on,
  the switch "Meldung bei freien kcal" (#937, off by default, saved on the
  device; turning it on asks for the notification permission, and a
  blocked permission shows as the switch's hint) sends a notification
  once the marker lies the next meal's whole share ahead of the kcal
  eaten: "Fürs Mittagessen hast du wieder 771 kcal frei", plus "Versuch,
  mehr Eiweiß zu essen." for the macro with the largest share of its
  target left. At most one per part of the day, none on a pause day and
  none after the last meal's time. Only today is planned, after every
  diary change and when the app starts; a new entry moves or drops it.
  Last in the menu is the switch "Makros
  immer bunt" (off by default, saved on the device), the same choice as in
  the Individuell color editor. Over the goal
  the number turns red as "+N" with "kcal drüber"; a macro over its target
  shows "+N g" in normal text and only the overage part of its line is
  red. On today and later days the macro with the lowest share of its
  target takes its macro color; with "Makros immer bunt" every macro
  does. A pause day shows "Pausentag" in grey,
  "N kcal gegessen", and "Fürs Lernen ignoriert", with the eaten grams of
  the macros in grey. A practice day before the goal starts, and a day
  after a run ended before the new run starts, can be tracked but do not
  count: a note at the bottom of the card says so. The chip "Details" (not
  saved, closed after a restart) shows eaten of target per macro, a ledger
  (base, training or normal day, buffer, carryover, eaten, counted plans,
  and what is left) with the link "Alle Tage" to the budget sheet, and the
  day types of the run week, where a tap on a day switches it between
  normal and training, past days included. Pause days show there too, but a
  tap leaves them alone: only the pause button at the top of the card sets
  and removes a pause.
- The main button of the eat page says "Ins Tagebuch", and "Einplanen" on a
  future day.
- The amount on the eat page of a food in grams or milliliters reads
  "count × weight of one portion": a wheel with the count in half steps (a
  tap types any count, such as 1,3), "×", the weight field with the
  portion's name under it, and the sum on the right. The ruler shows the
  sum; with a named portion it snaps to half portions, without one it moves
  freely. Weights take one decimal (37,5 g); the Vorrat takes them rounded
  to whole grams. A typed weight keeps the count; a weight that is not the
  named portion's own drops the name. The page starts with what was eaten
  last time, else the smallest named portion, else one package or what is
  left of it.
- A food counted in pieces reads the same way, "count × weight of one
  piece": the wheel counts whole pieces (a typed count too), or half pieces
  when the Vorrat keeps parts of a piece, and ends at the pieces in stock
  (a typed count over the stock takes all of it). The weight field has the
  piece size ("M") or "Stück" under it and switches between g and ml; the
  sum is on the right. The ruler moves the pieces; the piece size chips and
  "+ als Stückgröße merken" sit under it.
- One row of chips under the ruler scrolls sideways: "Zuletzt", the
  product's serving ("Portion" when it has no name), named portions, other
  learned amounts, ¼ and ½ of the package, and "Alles".
- A diary entry eaten as a named portion reads "2× 40 g Brotscheibe"; other
  entries show the sum.
- On a future day, a Vorrat item or a cooked meal is saved as a plan, with
  undo: it takes no stock and no portions until it is eaten. An item whose
  amount needs the calorie editor cannot be planned yet.
- The eat page of a Vorrat item, a cooked meal, or a found food has a plan
  button ("Planen") at the top, next to the day and meal: it asks for today
  or one of the next 14 days and saves the food as a plan, also for today.
  The day menu at the top also offers the next 14 days; a later day turns
  the main button into "Einplanen" and hides the plan button.
  Adding a food to a meal has no plan button.
- A cooked meal with open rows cannot be eaten, but it can be planned as a
  reminder: the eat page says the plan counts only once every row is filled.
  The plan row says "kcal offen" instead of its kcal and macros, and it
  counts nowhere (head, stripes, "Nach Plan", future days), while its
  portions still count as "verplant". When the last row is filled or
  ignored on this phone, the meal's reminders get its values and count like
  any plan; when a row opens again, its plans turn back into reminders.
  Accepting a reminder eats the meal once its rows are filled (without
  portions left it logs the meal's values without stock, like any plan),
  else it says "Erst die offenen Zeilen des Gerichts füllen"; for a meal
  that is gone it says "Das Gericht ist nicht mehr im Vorrat" with "Aus
  Plan entfernen". "Alle annehmen" leaves reminders out, and the plan
  details show no kcal for them.
- Plans show in their meal below the eaten food, faded in a dashed frame.
  A plan of a cooked meal carries the tag "Meal Prep". Tapping a plan
  deletes it, with undo. Plans are stored encrypted apart from eaten food,
  so the carryover, the weekly check-in, and the progress never count them,
  and a fresh start deletes them.
- From its day on, a plan has a check button: one tap logs it as planned,
  on its own day and meal, with undo. A Vorrat food takes its stock from a
  pack of the same food, opened packs first, then the oldest; a cooked meal
  takes its portions. When the Vorrat no longer has it, the food is logged
  without stock and the snackbar says "nicht mehr im Vorrat". A meal with
  more than one plan has a button in its heading that eats all of them at
  once, with one undo; its snackbar says when not all of them came from
  the Vorrat.
- Each meal heading has a copy icon. It opens "Als Plan kopieren" with that
  meal ticked; other meals of the day can be ticked too, so a whole day can
  be copied. The two-week calendar picks the days, and the button plans every
  food of the ticked meals once per day, in its own meal, with one undo for
  all copies. Copies are always plans, also of eaten food; a combined entry
  keeps no stock source.
- Future days are shown as a plan: the card reads "kcal übrig nach Plan"
  with the day's goal less its plans, drawn in the plan color; the macros
  count the plans too. Without the carryover the goal is the plain goal; with
  "Mit Übertrag" it includes the preview of the carryover. The training and
  rest day split still applies. More
  than the goal shows in the error color like on other days. Future days
  show no weekly check-in and no budget details.
- The week balance is a setting ("Wochenzielbalance") with three modes:
  "Aus", "Anzeigen" and "Mit Übertrag". It is saved per account, and every
  account starts with "Anzeigen". Hold the week card to change it in a menu
  with a line for each mode, or tap the row "Wochenzielbalance" in the settings next to "Schritte im
  Tagebuch", which opens the same menu. Switching recomputes the whole running run.
  - "Aus" and "Anzeigen": every day has only its own goal. The budget
    card, the macro targets, and the sheet "Alle Tage" never count what past
    days were over or under, the card shows nothing about the week, and
    there is no "<Wochentag> abschließen". "Aus" also hides the week card.
  - "Mit Übertrag": what finished days of the run were over or under their
    budget moves the budget of the days left. The balance is spread over the
    days left in the run, today included, at most 20 % of the day's goal
    and 350 kcal either way, and never below 1.200 kcal. A pause day and a
    day without entries add nothing. What is left at the run's end is
    dropped. The budget, the macro targets, the widget, and the free kcal
    notices use the budget with the carryover. "Details" shows it as a chip
    ("2.200 − 125 aus der Woche") and a ledger row.
- The week card sits between the budget card and the steps card in the modes
  "Anzeigen" and "Mit Übertrag", with no title and no total: one field for
  each day of the run that holds the shown day, named "Mo" to "So", with
  "Heute" in bold and the shown day framed. A finished day's field fills like
  the kcal line against that day's budget, and only the part above the budget
  is red; a pause day is hatched, a day without entries is an empty track,
  and coming days are dashed outlines. With "Details" open, numbers stand
  under the finished days: eaten minus that day's budget (+ more, − less, from
  50 kcal off), "Pause", or "leer". A gain goal turns red when short, not
  when over. With the carryover, a day with less budget has a dark piece at
  the front of its field and a day with more has a dashed piece at the end;
  today and every coming day show a preview that assumes the days until then
  hit their budget. A tap does nothing. Without a goal run there is no card.
- "<Wochentag> abschließen" exists only with the carryover. On tomorrow's
  card the button names today's weekday and closes today: today then counts
  as a finished day for tomorrow and every later day of the run, in the
  week card and on the budget cards, also when today is under its budget.
  Tomorrow then counts like a started day: the card shows "kcal übrig" with
  the goal plus that carryover, like today; a snack bar offers undo, and
  "<Wochentag> abgeschlossen" reopens the day on a tap. The carryover stays
  live: food logged later today or edits to earlier days change it. When
  tomorrow starts a new 7-day run or is a pause day, there is no button.
  The closed day is saved on the device and counts only until midnight; a
  switch to another mode and back keeps it until then.
- A new goal starts a new 7-day run on its start day and cuts the old run
  short: the old run's balance reaches no day of the new run, the week card
  of the old run shows only its own days, and the budgets of the old run's
  past days stay as they were.
- Plans on today, or on a closed tomorrow, show in the plan color after the
  eaten share of the kcal and macro lines. The chip "Nach Plan" shows only
  when the day has such plans; on by default, it counts them: the card then
  reads "kcal übrig nach Plan", the details add "<kcal> ohne Plan" and
  "· N geplant" per macro, and the ledger a row "Geplant · eingerechnet".
  Each macro shows the grams left after the plans. The budget sheet then
  lists "Offene Pläne" under what was eaten and ends with "Übrig nach
  Plan". The kcal totals of the meal headings count them too while the
  chip is on; a reminder without kcal is no counted row. A pause day offers
  the chip too, though nothing counts there. A practice day and a
  scheduled restart count no plans. The choice is saved on the
  device. Plans of past days never count.
- Plans of the last week that were never eaten or removed stay on their
  day. Today shows a line above the meals that names those days ("Offene
  Pläne vom <day>"); a tap opens the last of them, and the close button
  hides the line until a later day has plans left, saved on the device.
  Days before the first goal are left out, since the calendar cannot open
  them.
- Weekly check-in prompts and success/hint cards.
- Side menu from the diary top bar. The page slides to the right as a
  shrunken card and the menu shows behind it: the user, then Profile,
  household (You), kitchen utensils, shopping list (Kitchen),
  settings, appearance, about (App), and "Link account" for guests at the
  bottom. Appearance opens the settings scrolled to the Darstellung section.
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
    Tapping it plans them for this run only, like the weekly check-in; the
    editor shows each changed day's calorie goal, the other days that give
    or take calories, and the run total before it saves. A plan drops the
    day types picked in the diary for that run, so the run total is the
    daily goal times seven again.

## Calories And Burn Week

- Manual calorie entry create, edit, details, and delete flows.
- Amount changes on a logged entry, with undo. An entry logged from the
  inventory moves the stock with it when the item is measured in grams or
  milliliters.
- Barcode-based calorie entry lookup.
- Nutrition label scan handoff when barcode products are missing nutrition.
- Calorie goal setup and goal-start shifting.
- Calorie calculator using sex, weight, height, age, activity level, goal mode,
  and goal speed. Once the body data is known, setting a new goal lists sex,
  height, and age as a plain list with "Edit in profile" instead of asking
  them again; the link closes the goal sheet and opens the profile page.
  Editing the running goal from the learned TDEE shows the same list.
- Setting a new goal from the learned TDEE is one short sheet: the new daily
  target on top, then one row each for the target weight, the pace, and the
  start day. Tapping the target or pace row opens its slider or wheel below
  it; the pace wheel offers the onboarding's 0.05 to 1.5 kg per week and
  shows when the target is reached at that pace. Body data is edited in the
  profile. The sheet has a drag handle, closes with a swipe down, and has
  "Abbrechen" next to "Ziel speichern".
- Learned TDEE recalculation from tracked data: a daily estimate from the
  first goal on; the weekly check-in takes its value at the end of the week,
  and the TDEE of past runs shows the daily estimate too.
- The daily calorie goal follows the daily TDEE: each day's goal moves by
  how far the estimate changed since the goal was set, using the estimate
  of the day before so a day's own food never raises its own goal. Days keep
  their goal after the week ends; the carryover still starts fresh each
  week. The check-in moves the goal at most 200 kcal from the corrected goal
  of the week's last day.
- Weekly check-in with weight trend, learned TDEE, target refresh, and blocking
  reasons for missing intake or weight data. It is a tall sheet in four
  steps: a look back since the goal start (trend, eaten, training days, weight
  chart, and the TDEE of each run) with the measured TDEE and the goal it
  gives, and a link to change the goal; the training days of
  the next run, which start empty ("Wie letzter Run" plans the last ones
  again, and the date chips and the bars of the week chart switch a day);
  the progress photos of a pose
  ("Dein Weg bisher": the first since the goal start, the one nearest
  halfway, and today's, each with day and weight), where the slot of today
  adds or replaces today's photo and "Weiter" skips it; and the new targets
  with the
  training and rest day split and the macros before and after. "Woche
  starten" applies the measured TDEE and saves the training days; there is
  no option to keep the previous TDEE, since the goal follows the daily TDEE
  anyway. A reached goal shows a
  congratulations page instead of the look back. The goal sheet that the
  check-in opens has a tonal back arrow. Leaving it without a new goal, by the
  arrow, "Abbrechen", or a swipe, opens the check-in again on the same step
  with the training days chosen so far, still undecided. A check-in swiped away or
  put off with "Später" also keeps its step and choices for "Fortsetzen"
  while the diary stays open.
- Burn Week budget model with daily goal, activity credit, the optional
  carryover, skipped days, remaining calories, and details sheet.
- Macro tracking for protein, carbs, fat, and extended nutrient fields.
- Protein and fat targets in g/kg: 1.6 g protein, 2.0 g while losing weight
  with training; 0.8 g fat for men, 0.9 g for women. The training days decide
  until the user sets sport in the macro settings. Carbs get the rest of the
  kcal, but at most 40 percent. What lies above that on the weekly average
  goes to protein up to 2.0 g/kg, so protein stays the same every day unless
  a day's budget is very small (see below); the rest goes to fat. A custom protein value stays as set. A carryover counts
  like a change of the day's kcal: the macros follow the same rules for the
  goal plus the carryover. On a small budget carbs keep 100 g first: fat
  drops to its floor (0.6 g/kg or 20 percent of the kcal); below that, carbs
  get the rest, so they can fall under 100 g. Protein never drops. When even
  protein and the fat floor need more kcal than the day has, the targets add
  up to more than the goal. Above a BMI of 25 only 40 percent
  of the extra weight counts (adjusted body weight), so heavy users get
  realistic targets. Those users see the adjusted weight and a medical
  disclaimer on the onboarding summary and in the macro settings. No training
  days are preset.
- The body weight for the protein and fat targets follows the user week by
  week. Each 7-day check-in saves the trend weight of its last day, and a
  new calculated goal saves its
  start weight. A day uses the latest of these on or before it, so the macros
  stay fixed within a week and past days keep their targets.
- Inventory-backed delete/restore behavior for entries created from stock.

## Fortschritt

- Fortschritt tab with two chips, "Aktuelles Ziel" and "Gesamt".
  "Aktuelles Ziel" covers the current goal from its start (at least 7 days
  for the charts); "Ziel" opens a menu of all goals, and a past goal shows
  only that goal, from its start to the day before the next goal, without
  forecast, TDEE change lines, or week section, and its goal card shows speed,
  start date, start and end weight, end date, and reached date; "Gesamt" covers all goals from the first start, hides the
  goal card and the run, and marks each goal start ("Ziel 2") in the weight
  and TDEE charts. From top to bottom:
  - the goal ("Lose weight to 78 kg"), a four-part bar of the way from the
    start weight to the target by trend weight, the kg to go and the pace,
    the daily calories with protein, carbs, and fat;
  - the current 7-day run, headed "Run 3 · Tag 2 von 7": the average kcal
    per day as the main number with the goal, the week budget (eaten of the
    run's total, one segment per day, kcal left), and one row per day with
    weekday, day type emoji, a bar of four quarters of the day's goal, and
    the eaten kcal. The bars fill in the
    macro colors (protein red, carbs blue, fat yellow) by kcal share; the part
    over the goal is hatched orange. Under them the average grams per macro
    against their goals;
  - progress photos, under the goal card: pose chips, "Vorher" (the first
    photo of the pose in the scope; in Gesamt also photos from before the
    first goal) next to "Nachher" (the newest), each with its day and weight,
    the weight change between them and the weeks in between. "Alle Fotos"
    opens every photo grouped by goal, newest first; a long press deletes a
    photo after a question. "Vergleichen" lays both photos on top of each
    other with a slider between them; both days can be picked. Without
    photos the section offers "Foto hinzufügen";
  - the weight trend: weigh-ins as squares, the trend as a line through gaps,
    the average change of the trend per week over the selected scope with
    the days it covers ("Ø seit 7. Sept.": the current goal from its start,
    "Gesamt" from the first goal or first weigh-in, a past goal only its own
    days; left out under 7 days of weights), and the day the trend reaches
    the goal weight.
    "Alle Gewichte" (or a tap on the section) opens the weight list;
  - the daily TDEE: a line per day from the first goal on, the value that
    the day's intake and weight trend imply as a small grey square, and a
    square on the line for each confirmed check-in; the head shows today's
    TDEE, the change since yesterday and this week, and the next check-in;
  - training days against rest days up to yesterday: days of each,
    and average kcal, protein, carbs, and fat.
- The round button of the bar ("Erfassen") opens the Fortschritt actions:
  - "Wiegen" opens the weight entry for today, filled with the newest single
    weighing (not the chart's last weigh-in). It adds a weighing; saving
    updates the weight trend and the goal right away.
  - "Foto" opens a sheet for a progress photo: a pose (vorne, seitlich,
    hinten), a day (today or any earlier day, for photos from before the
    app), an optional weight, and "Kamera" or "Aus Galerie". The photo is
    saved at once; a day holds one photo per pose, and a new one replaces
    the old. A typed weight stays on the photo and never becomes a weigh-in;
    without it the weight of the day applies.
- The weight list "Gewichte" opens from the weight section and from the
  profile's weight card. Chips "Ziel" (default), "4 Wochen", and "Alles"
  pick the range. At the top: the trend change since the start of the range
  ("Seit Zielstart 7. Sept."), the trend, the kg still to go to the goal
  weight (hidden once it is reached or while maintaining), and the average
  pace per week over the range;
  below, the weight chart with the goal weight as a dashed orange line.
  Then every weighing as its own row (day, time, kg, "Von Hand" or
  "Waage"), newest first, grouped by the 7-day runs of the goal ("Run 3 ·
  seit Mo., 21.9.") with the trend at the end of the run and its change.
  Days without a counting goal form 7-day blocks without a number. Dates of
  another year show the year. The plus button opens the weight entry for
  today. Without a Health connection, a card "Waage automatisch übernehmen"
  offers "Health verbinden"; once dismissed, a heart icon in the header does
  the same.
  A tap on a weighing opens its sheet. A weighing of your own (by hand, or
  saved from the app to Health on this device) opens the edit sheet: weight,
  day, time, and delete. Other weighings open an info sheet with "Ignorieren"
  or "Wieder zählen" and, for other apps, "In Health öffnen". A weight the app
  saved to Health on another device is view-only, with a hint. An ignored
  weighing is greyed out in the list, shown as a hollow point in the chart,
  and no longer counts for the trend, on all devices.
- Progress photos are end-to-end encrypted with a key of their own, stored
  under a random name, never shared with the household, and deleted with a
  fresh start of the data key. Their location, device, and time metadata is
  removed before the upload.

### Data Export

- "Exportieren" in the Fortschritt "Mehr" menu and "Daten exportieren" in
  Einstellungen › App open the same page. The user picks who the export is
  for and the period, then "Teilen" opens the system share sheet
  ("Speichern" for "Für mich").
- **Für wen:** "Meine KI" shares a text file (`.txt`, Markdown inside) or
  copies the text to the clipboard ("Kopieren"), with a ready question on
  top, the fields explained, the goals, an overview, and every day with its
  meals and foods. "Ernährungsberater" shares a PDF report and
  an Excel table (`.xlsx`). "Für mich" saves the PDF report on the device
  ("Speichern" opens the system save dialog).
- **Zeitraum:** the current goal (default), "Alle Daten" (every goal), one
  or more goals from a menu ("Ziele", ticking a goal adds the goals in
  between, tapping a goal inside ends the range there), the last 7 days,
  4 weeks, or 3 months, or days from a calendar. A line under the chips
  says what the export holds: days, entries, and weighings. Nothing
  before the start of the first goal is offered: longer ranges start there
  and the calendar starts on that day.
- **Content:** the goals that ran in the period (mode, dates, weights, pace,
  base kcal), the parts of the day, and per day the day type, the kcal and
  macro goals, what was eaten per meal and per food with its amount, the
  weighing, the trend weight, the TDEE, and the TDEE daily value. A food
  counted from a recipe's AI estimate is marked ("· Nährwerte geschätzt"). The
  TDEE is the one Fortschritt shows as its line, with training already in it;
  the daily value ("Tageswert") is the TDEE that the smoothed food and the
  weight trend of the day give, before the TDEE's ramp-up and daily cap, and
  only days with entries have one. The overview and the PDF tile show the
  average of both; the text for "Meine KI" explains the daily value and that
  training is part of the TDEE. Planned entries are
  not exported.
- **PDF report:** page 1 holds the key numbers, the goals, a chart of food,
  weight, and TDEE together, weight as bars, the TDEE as a line, kcal eaten
  against the goal by day type, and the average macros against their goals
  with the eaten parts of the day. The pages after it list every day with
  its foods.
- **Excel:** sheets for days, meals (with each meal's part of the kcal goal),
  foods, and goals with the parts of the day; numbers stay numbers.
- The data is end-to-end encrypted, so the files are written on the device.
  A line on the page says the file is not encrypted.

## Activity And Weight

- Activity and weight section used by the diary.
- Manual and imported weight data. The weight dialog only adds a weighing;
  changing or deleting one happens in the weight list.
- Weight prompt when today has no weight, on today's diary page. Dismissing it
  hides it for that day.
- Health connection actions from diary-owned surfaces.

## Health Integration

- Health Connect and Apple Health connection/disconnection flows.
- Health access status, permission, history, install, and unsupported states.
- Imported weight data. A device with Health access copies its weighings
  since the first goal into the cloud, so every device of the user computes
  the trend, the TDEE, and the check-in from the same weights, also one
  without Health access. A weighing deleted in Health within the last 30
  days is deleted in the cloud on the next sync, once no other device still
  has it in its Health.
- Manual weights. Every weighing is its own entry; several a day are fine.
  All weights of a day, manual and from Health, count as their median.
  Saving to Health does not remove the manual entries of the day.
- Weight, trend, and TDEE start at the first goal; earlier weighings do not
  settle the trend in advance.
- Platform stubs for unsupported targets.

## Inventory

- The Vorrat is one flat list of foods and prepared meals. The header shows
  "Vorrat" with the count of foods and meals in stock above it. Next to the
  search field sit "Sortieren" and a Liste/Kacheln button; Kacheln shows a
  grid of small tiles for a quick overview. While the list scrolls, the
  header scrolls away and the search row with both buttons stays at the top;
  in selection mode the header stays, because it holds the selection actions.
- Quick filter chips with counts: Alle, Offen (partly used), Verplant (foods
  and cooked meals that open plans or running cook runs take from),
  Mahlzeiten, Fast leer (under a quarter left). The chip starts at Alle on every visit.
- Each row shows a tilted, framed picture (photo, ingredient photos of a
  meal, or the first letter), the name, the amount left and the full amount,
  brand and kcal per 100 g (for a meal its portions or its missing
  ingredients; "Aus Rezept" or "Kombiniert" names where a meal comes from), and a stock bar with one segment per pack, or per portion for
  a meal. Under a quarter left the amount and the bar turn orange with "fast
  leer".
- A food that open plans or running cook runs (see Kochmodus) take stock
  from names that amount ("250 verplant")
  in place of the full amount, and its stock bar draws the planned part in the
  plan color; a tile draws the planned part too. When its plans need more
  than the pack has, the row names what is missing instead, in orange ("100
  fehlen"). A cooked meal does the same
  with its planned portions ("2 Port. verplant"). A meal plan that the
  meal's portions left cannot cover shows "fehlt" in the diary but stays out of
  the shopping block.
- The Sortieren sheet sorts by added, eaten, name or amount; tapping the
  chosen field again flips its direction. Until the user changes it, the
  list sorts by last eaten, newest first. It also holds "Verbrauchte
  ausblenden" and "Nach Beleg". Changes apply at once and survive a restart.
- Add items from receipts, barcode search, manual search, or AI suggestion.
- Inventory item edit, consumption, discard, and delete flows.
- Tapping an item row opens the item hub: the food label eat page plus an
  "Item" card with add to shopping list, edit, and replace product. A trash
  icon beside the main button ("Aussortieren", as on the diary entry page)
  removes the item: thrown away, eaten elsewhere, or deleted, with undo.
  The rarer eat actions sit at the top of that card instead of on the page:
  "Nicht essbaren Anteil abziehen" (foods in g or ml) opens the inedible
  field on the page, which stays there while it is open or holds a value,
  and "Mit anderem Lebensmittel kombinieren" (foods with nutrition values)
  starts a meal. A used-up item offers neither, and a started meal hides
  both. Action dialogs open over the hub, so cancelling one returns to it. A
  finished edit, replace or remove closes the hub; adding to the shopping
  list keeps it open. A used-up item shows only the card and the trash
  icon, and its main button adds it to the shopping list. Rows have no
  action buttons of their own.
- The item hub can log other foods together with its item: "Mit
  anderem Lebensmittel kombinieren" in the Item card and "+ Lebensmittel
  hinzufügen" under the meal's rows close the hub, and the Vorrat continues
  the meal in its selection mode with the hub's item and the foods picked so
  far already selected. Amounts entered on the hub are not kept. In the
  selection mode the Vorrat search field still filters the list, and a row
  below it ("„Reis“ im Katalog suchen") searches the catalog for the typed
  text; a food found there joins the selection with the amount entered on
  its eat page, as a row with an x to remove it. "Lebensmittel kombinieren"
  needs two foods, one of them from the stock, and opens the hub of the
  item the selection started from. Only stock items with nutrition values
  and stock, counted in grams or milliliters, join the meal; others stay
  out with "Dieses Lebensmittel hat keine Nährwerte zum Zusammenrechnen."
  The search text is cleared when the selection ends. Stock items
  join with 100 g or ml; tapping a food's row opens a "Menge" field and a
  ruler for its amount, which follow each other. Tapping the amount itself
  opens them with the field ready to type, such as 137 g. A picked food
  refuses a typed amount that is no number or more than its stock ("Bitte
  gültige Zahlen eingeben.") and keeps its amount; the hub item's own row
  checks its amount like its eat page when the meal is confirmed.
  The hub then shows all foods' images side by side in its header (the rows
  carry no images), the meal name, and one
  nutrition label for the whole meal, per 100 g and in total ("–" when one
  food lacks energy or a macro; another value that a food lacks adds up the
  foods that list it and shows as a minimum, "mind. 2 g"; no per-100 column
  when grams and milliliters mix),
  and the main button "In Vorrat" keeps the picked foods in stock as one
  prepared meal "A + B" and opens its "Gekocht" step (kicker "Kombiniert"):
  Portionen or Stück and the count, "Gewicht · N g aus den Zutaten" (the sum
  of the ingredients when all are in grams; "Gewicht stimmt nicht? Mit
  Behälter wiegen" shows the container and the scale instead), and the "Ins
  Kochbuch" switch. Closing that step asks "Mahlzeit verwerfen?" ("Die Zutaten gehen
  zurück in den Vorrat."); discarding returns the stock and deletes foods
  found by search again, also when the step is opened again later from
  "Offen". Until the step is saved the meal is open like a
  pot from a Vorlage. The grey "Mahlzeit ins Tagebuch"
  saves one combined diary entry named "A + B" instead. The entry keeps a
  value such as sugar only when every food lists it, since the diary cannot
  mark a minimum. The entry and every stock change are written together. A
  combined entry cannot change its amount or be eaten again; deleting it
  can return the stock of every food.
  While other foods are picked, the Item card hides "Bearbeiten". A food found by search skips the
  product editor when its label is complete and opens on its eat page
  (label, amount, button "Add"); "Bearbeiten" there opens the editor and
  comes back to the eat page.
- Amount parsing and unit handling for grams, milliliters, pieces, and custom
  serving data.
- Receipt grouping ("Nach Beleg" in the Sortieren sheet).
- Household inventory activity timeline for stock changes. A row shows the
  picture the food had at the time, framed like a Vorrat row, with the action
  (added, eaten, thrown away, ...) as a small round badge at its lower right;
  a food without a picture keeps the action icon alone. The row's sentence
  names the action for screen readers.
- Add-to-shopping-list and buy-again actions.
- The picture of a food or meal flies from its row into the page it opens.
- A long press selects foods; "Lebensmittel kombinieren" opens the item hub of the food
  the selection started from (else of the first selected food) with the
  others already combined, so the meal is logged or kept in the Vorrat
  there.
- Tapping a prepared meal opens its detail page: the meal eat page plus a
  "Zutaten" box (every ingredient with picture and its amount in the whole
  meal; missing recipe ingredients in orange with "Zutat ergänzen" and "Zutat
  ignorieren"; ignored ones greyed and struck through, "Ignoriert – zählt
  nicht mit", with "Zutat ergänzen" and "Nicht mehr ignorieren") and a
  "Mahlzeit" card with edit, save as recipe, "Gewicht ändern", unbundle and
  throw away. A meal with missing ingredients can be logged once they are
  filled or ignored; ignored rows stay on the meal and count for nothing.
- Each ingredient has an x ("Zuordnung entfernen") while no portion is gone:
  it takes the food out of the meal again, the reverse of filling its row.
  Its row is open again (the recipe row it filled, its share of the row
  when several foods filled it, else its own amount and name), the totals
  are summed from the other ingredients, and its amount goes back to the
  Vorrat item, also for a food assigned while cooking or found by search.
- "Gewicht ändern" weighs a cooked meal again at any time, for example cold
  the next morning before it is portioned. A meal weighed in its pot at
  "Gekocht" asks for the pot on the scale and takes the empty pot off
  ("− leerer Topf 1180 g = 1200 g im Topf"); any other meal asks for the
  weight of the food. The weight counts in whole grams up to 99999 g; a
  decimal comma is rounded and "1.250" is 1250 g. A pot no heavier than
  empty blocks saving. Before the first portion is gone the dialog asks for
  the whole dish, afterwards for what is left ("2 von 4 Portionen"), and the
  whole dish counts as that weight scaled to all portions. The weighing is
  stored for the household like one on the eat page: grams per portion, the
  grams of the amount ruler, the "Je 100 g" column and the grams in the Vorrat
  row follow it. A portion stays its share of the meal's nutrients, so its
  kcal and the diary entries made before do not change. Pieces, a meal in
  the pot and an eaten-up meal have no "Gewicht ändern".
- The nutrition label of a meal (eat page, detail page and meal editor)
  shows every value its ingredients' labels have, not only energy and the
  macros. Energy and the macros are the meal's own totals, which the diary
  entry logs. A value that only some ingredients list shows "–" (as on the
  combined label of the item hub), and one that no ingredient lists is left
  out. In the "Zutaten" box an ingredient whose label lacks one of the
  seven EU values says "Nährwerte unvollständig", so the user sees why the
  meal's label is short.
- "Zutat ergänzen" opens the "Zeile füllen" sheet: when the row has an
  amount, the best Vorrat match comes first with how much is left and
  "Übernehmen", which uses the row's amount. Below it: "Vorrat" (pick other
  Vorrat foods), "Suche", "Barcode", "KI", "Auf die Einkaufsliste", and
  "Zeile ignorieren". "Auf die Einkaufsliste" puts the row's text on the
  shopping list as it is written, unless that text is listed already, and
  leaves the row as it is; ignored rows offer it too. Search,
  barcode, and AI open the food pick at that tool; the found food's eat page
  asks the amount, the food is added to the Vorrat with exactly that amount
  and used up for the row. This also fills rows without an amount ("Salz").
  If the row cannot be filled, the added food is removed again.
- Editing a meal opens the meal editor, drawn like the eat page: picture
  (tap for camera, gallery or remove) and name, one row per ingredient with
  a ruler for its amount and a remove button, the open and ignored rows,
  "+ Lebensmittel hinzufügen" (stock foods only, 100 g or ml each), the
  portions and the nutrition label of the edited meal (minimums as on the
  item hub). Removing an
  ingredient only takes its food out, like its x on the detail page: the
  ingredient comes back as an open row. The x of an open or ignored row
  deletes the row from the meal; a meal keeps at least one ingredient or
  open row. "Rückgängig" after saving puts the meal back with its
  ingredients, rows and stock. Once portions are eaten, only name and
  picture change.
- Global food item matching and serving suggestions for future adds.

## Receipt Scanner And Review

- Receipt capture with the document scanner, up to 10 pages; the scanner also
  offers a gallery photo to crop (Android with Google Play services: button in
  the scanner; iOS: camera or gallery choice first, the photo shrunk to
  2048 px). The file entry keeps a photo at full size.
- Receipt upload from image or PDF.
- Shared receipt intake from platform share intents, also when the sender
  adds a text to the file.
- Batch receipt processing with queued, processing, done, failed, and reviewed
  states.
- AI receipt analysis: photos and PDFs go straight to a Firebase AI server
  prompt template (`receipt-parse-template`), so the prompt can change
  without an app release. Overlapping photos of one long receipt are merged.
  The running analysis can be canceled (button or back): the user stays in
  the Vorrat without a message, and a result or error that arrives later is
  dropped.
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
- Adding to the Vorrat takes one food per add, from the Vorrat's add button:
  one confirmation stores it, and the page closes back to the Vorrat.
  Several foods at once come from the receipt scan. The diary search works
  the same way: no "+ Mehr", one food per pick.
- Barcode scan lookup with multiple-candidate picker and not-found handling.
- Offline an empty search result, also after a barcode scan into the search,
  says "Ohne Verbindung keine Suche" instead of "Keine passenden Produkte
  gefunden". Once the device is online again, the search runs once more by
  itself.
- Text search lists the shared catalog first, then Open Food Facts. Catalog
  foods without a barcode that another user made, such as an AI meal, come
  last, so a plain product that matches ranks above them; the user's own
  stay with the catalog results. A food from before the catalog recorded
  its author counts as another user's (#655).
- Voice search for manual product text where supported.
- AI food creation from photos and/or a description (one of both is
  enough), with quick phrases such as "large portion". The server prompt
  template `food-estimate-template` can change without an app release.
- The AI result opens on the eat page: photo, name, nutrition label, amount
  ruler with the estimated portion, the ingredients with grams and kcal, and
  lean / normal / rich chips that shift the energy. Confirm logs the food
  when opened from the diary and adds it to the Vorrat otherwise, with no
  Vorrat page after it. In the Vorrat "Planen" at the top and the "Ins
  Tagebuch" icon beside the button plan or eat the food instead; in the diary "Planen" plans it, also for
  today. "Analyze again" returns to the input.
- Confirm closes the page right away. The first photo becomes the food's
  private picture (`users/{uid}/food_photos/`): the food keeps its Storage
  address, which shows from the local image cache while the photo uploads
  in the background. A failed upload waits on the device and says so, also
  after the page closed (#845, #849).
- An AI food is the user's own meal: saving it adds it to the Vorrat or
  the diary only, not to the shared catalog, so other users do not find
  it (#655). The food keeps a mark "estimated by the AI", so it also
  stays private after it is edited, reopened, picked again from the recent
  items, or used in "Produkt ersetzen", and it never records a barcode for
  other users' scans or a shared serving suggestion; its last serving is
  remembered for its user only (#701). AI foods saved before the mark existed are
  not known as such.
- A product the user types without picking a search hit goes into the
  shared catalog only with a barcode, as packaged goods; without one, such
  as a home-made dish, it stays the user's own. A picked catalog product
  records its barcode and fills fields the catalog still misses, and an
  Open Food Facts hit joins the catalog. "Produkt ersetzen" shares the same
  way as adding a new Vorrat item, so an own food picked again from the
  recent items stays private there too.
- The Vorrat eat page of an AI food shows lean / normal / rich chips under
  its name and its ingredients, collapsed, below the amount. A chip saves
  the level on the item at once: its nutrition follows the level from then
  on, also for a partly eaten food, and entries already eaten keep theirs.
  Eating waits until the level is saved (#763).
- "Neu analysieren", the first line of its item card, opens the AI page
  with the food's photos and description. "Übernehmen" on the result
  replaces the name, nutrition, portion, estimate and photos; the stock and
  the dates stay, also for a partly eaten food. Photos removed there go.
  Only photos added there are uploaded. The snackbar can undo it (#763).
- The product editor looks like the eat page: image, brand and name as
  inputs, package size with a unit switch, and the nutrition label with an
  input per 100 g. All seven values of the EU label (energy, fat, saturates,
  carbohydrate, sugars, protein, salt) are required; a missing one is
  framed. Polyunsaturates and fibre come from the "+" row.
- Editing a food that exists already (a stock item's "Bearbeiten", or
  "Bearbeiten" on the eat or Vorrat page of a picked food) opens the editor
  with "Fertig" instead of "Erstellen" (#489): it closes without saving or
  uploading anything. Once a value, the unit, the barcode or its "has none"
  mark changes, or a photo is taken, the button says "Änderungen
  speichern". A value written another way ("1,50" for 1.5, spaces around a
  text) is no change, and changing a value back shows "Fertig" again. A
  missing value does not block "Fertig"; the line above the button still
  names it. Reopening the form of a product that is not created yet keeps
  "Erstellen".
- From the Vorrat's own add sheet (not when a flow such as cooking picks an
  ingredient), the Vorrat page after a pick also has "Planen" at the
  top and an "Ins Tagebuch" icon next to "In Vorrat": "Ins Tagebuch" opens the eat page
  and eats the product instead of storing it; "Planen" asks for the day first
  (from today on, like every plan button) and opens the eat page on it, where
  the button says "Einplanen" and plans the food, also for today.
- A package size in pieces ("10 Stück") shows a "Grams per piece" input.
  The grams become the product's serving, so the eat page offers one piece
  in grams; an OFF serving such as "1 Ei (60 g)" fills it.
- Missing values hint: after a pick, a quiet line names what the product
  lacks ("Missing: Package size, Salt – add") and opens the editor on tap.
  It never blocks. Missing are the seven EU label values, and on the Vorrat
  pages also the package size: none, or pieces without grams per piece (OFF
  often has only "1 Stück"). The line shows on the Vorrat page after a pick
  and on a stock item's page; the eat page of a picked product checks only
  the nutrition. The receipt review names a missing package size and the
  nutrition values on the item card; grams per piece it cannot know.
- The OFF search keeps a serving as a serving: a product without a package
  size stays without one instead of taking the serving as its size.
- Two photo tiles fill the editor: the package front (server template
  `product-front-template` reads name, brand, and package size) and the
  nutrition table (`nutrition-label-template`). The barcode scanner looks at
  both photos first; only without a result does the barcode the AI read on
  the front count, marked "please check". Otherwise the user scans the
  barcode or marks "has none". Saving needs a barcode or that mark. Editing
  a saved food without a barcode, such as one saved with "has none" or an AI
  meal, opens with the mark set, so it is not asked again; a barcode the
  scanner or the AI finds on a new photo still replaces that mark (#828).
- The front photo is first of all the product's picture, so the AI says
  nothing about it (#659). A front without a package or a readable name, or
  one the AI cannot read at all (offline, a failed or throttled request, a
  broken answer), leaves the fields it could not fill empty for the user.
  Only the camera's own problems (no camera, a failed photo) are reported.
  The nutrition table photo still asks
  for a new photo or reports a failed read.
- On save both photos go to Firebase Storage under
  `product_images/{uid}/{photoId}/`, readable by every signed-in user. The
  front photo becomes the product image when the product has none. The
  save does not wait for the upload: the product keeps the Storage address
  (`gs://…`) of the front photo, which shows from the local image cache
  until it is uploaded. A failed upload keeps that address and says so.
  The shared catalog does not get this photo yet (#414).
- Product and food photos go up through a queue on the device: each photo
  is kept there until its upload succeeds. A failed or interrupted upload
  shows "Fotos werden später hochgeladen." and is tried again when the app
  starts or comes back to the foreground and when the device comes back
  online, so other household devices get the photo too. A photo that
  still fails after a week is dropped without a message. Signing out
  deletes the photos that still wait (#849).
- When the AI finds no package on the front photo, the photo stays the
  item's picture but is stored as the user's private food photo
  (`users/{uid}/food_photos/`, visible to the household), and no photo goes
  to `product_images` (#658). The nutrition table photo is shared as usual,
  and the product itself still goes into the shared catalog when it has a
  barcode. A new front photo with a package is shared again; closing the
  camera keeps the private one.
- The photos also give the serving (#527): the front one piece of a
  multipack ("6 x 25 g" becomes a 150 g package with 25 g per piece), the
  nutrition table its per-portion heading ("pro Riegel (25 g)"). It is saved
  as "1 Riegel (25 g)", so the eat page offers it as a chip. When the two
  read different amounts, chips under the photos let the user pick; the
  table is the default. A package counted in pieces always takes the
  front's piece, and a weight per piece the user typed stays.
- Nutrition quality handling for unverified AI/OCR/manual estimates.
- Barcode-less manual and AI-created food saving.
- "Create" opens an empty product form. Name, unit, and the seven EU label
  values are required; confirming a required field on the keyboard jumps to
  the next empty one.
- The barcode row has a scan button and a "has none" mark. Scanning an
  unknown barcode keeps the entered values.
- A barcode lookup that finds nothing while the learned candidates or Open
  Food Facts cannot be reached (no connection, timeout) does not say "not
  found": it says that the barcode cannot be looked up without a connection
  and keeps the scanned barcode in the product, so it can be finished by
  hand. When one source answers with products, they show as usual (#487).
- Going back from the eat dialog after "Create" reopens the product form,
  with any edit made from the eat page.
- In the diary, a scanned, searched, or recent food opens on the eat page.
  "Bearbeiten" there opens the product editor and comes back to the eat
  page with the edited food; only the user's own copy changes. The Vorrat
  icon next to the main button puts the food into the Vorrat instead of
  eating it: the Vorrat page opens (packages, package size), as from the
  Vorrat search, and no diary entry is made.
- Eating a newly picked product has no stock limit: the stock is set to the
  eaten amount. When the package size is known and less than the package is
  eaten, the app asks "Soll der Rest (300 g) in den Vorrat?"; "In den Vorrat"
  keeps the whole package in the Vorrat with the eaten amount taken off. A product with g or ml but no package size is eaten in that
  unit. The eat page always shows the per-100 column.
- In the diary, a scanned, searched, or recent food whose barcode is in the
  Vorrat asks "Vom Vorrat abziehen?" after "Ins Tagebuch", with a list of
  its packs, each with the amount left, opened packs first, then the
  oldest. A tapped pack gives the amount picked on the eat page at once;
  only when that amount cannot be told in the pack's unit does the pack's
  eat page open. "Nicht abziehen" eats the food as a new product as before.
  A plan for a later day asks the same: it keeps the picked pack, so
  accepting it takes the stock there; without a pack it is planned as
  before (#326).
- "Zuletzt ausgewählt" (up to 20) shows while the search query is empty:
  foods added by hand and foods eaten from the Vorrat, last eaten or added
  first.
- One product per visit, in the diary as in the Vorrat: one confirmation
  logs or stores it and the page closes (#519, #532).

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

## Cookbook

- The Kochbuch tab shows three sections: "Läuft" lists the household's cook
  runs (picture, name, status, "du" or the member's name with the start
  time, "Weiter"), and below them, under "Aus der alten Version · N offen",
  Vorrat meals that are still in the pot or have open rows, newest first;
  "Vorlagen" is a horizontal strip of templates combined from Vorrat foods,
  led by a "Neue Vorlage" tile; "Rezepte" is a two-column grid of recipe
  templates.
- A template with recipe ingredients counts as a recipe; one without is a
  Vorlage.
- Each Vorlage shows one square per food: ink when the Vorrat holds a matching
  food, the low color when it is missing, followed by "Alles da" or the missing
  count.
- A recipe card shows its AI estimate, with protein, carbohydrates and fat in
  their colours beside the kcal, and is not matched against the Vorrat.
  Once its cook run has a line assigned by hand, it also shows one square per
  line the run does not ignore: ink when assigned, the low color when open,
  followed by "Alles da" or the open count. A tap opens the recipe page; the
  card has no cook button.
- A food that names no amount, such as "Salz" or "Pfeffer", counts as there
  in plans when the Vorrat holds an item of its name. Cooking takes nothing
  from that item and leaves no open row. An amount the app cannot read ("1 cup
  Milch", "eine Dose Tomaten", "etwas Mehl", "Bund Petersilie") still stays an
  open row, and so does a row without an amount.
- The "Kochen" button offers "Frei kochen" (opens the cooking page without a
  recipe, see Kochmodus). The Kochbuch header offers the kitchen utensils and
  "Neu".
- A Kochbuch without a recipe says so and offers "Rezept hinzufügen", which
  opens the same menu as "Neu".
- "Neu" opens the menu "Neues Rezept": "Scannen" (up to 3 pages), "Liste
  einfügen" (from the clipboard), "Selbst tippen" (starts empty), "Aus Link"
  (reads a recipe page), and "Rezeptidee".
- "Rezeptidee" asks in three rows without a title: "Vorrat zuerst" (on by
  default) with "Unbedingt rein", "Wünsche" as pills, and the stored "Bloß
  nicht" list (see AI Chef), then "Rezept vorschlagen". While we put the
  recipe together, a calm wait shows; closing the sheet drops the idea. If
  it fails, the sheet says "Wir konnten gerade kein Rezept zusammenstellen."
  with "Erneut versuchen". The idea then opens in a tall window as a normal
  recipe: name, portions, ingredients with kcal and macros, steps. The values
  of each ingredient and of one portion come with it, so nothing is estimated
  later. "Im Kochbuch speichern" is the one button; it saves the recipe, and
  a message "Im Kochbuch gespeichert." offers "Rückgängig". The picture comes
  later and fades in without holding the recipe up; it goes onto the saved
  recipe when it is ready. Closing the window without saving keeps nothing,
  not even the picture.
- The recipe editor (new recipe, and "Bearbeiten" on a saved one) has the
  name, the portions, the ingredient lines, and the steps. A line is free text
  exactly as read; the app does not check it. Lines are edited where they stand:
  a tap on a line of the ingredients or the steps turns it into a field in the
  same place, with a button that removes it, and "Rückgängig" in the message
  brings a removed line back. A line whose text changed loses its estimated
  weight (in g or ml); the next estimate fills it.
  "Einfügen", and a scan, fill the editor: the name only while it is empty,
  the portions when the list names them, and the lines and steps are added to
  the typed ones. A long recipe name wraps over up to three lines. Pasted or shared text is read by the AI (title, portions,
  ingredient lines as written, steps, without headings, bullets, step numbers,
  or nutrition notes); without an answer, rules read it by its headings
  ("Zutaten", "Zubereitung", "Schritte") or else by its empty lines, and leave
  out a sub-heading among the ingredients, such as "Für den Teig:". A text of
  more than 20,000 characters is refused with a message and goes to neither.
  Saving needs a name, portions, and one ingredient line, and opens the recipe
  page. While the name or an ingredient is missing, a line above the buttons
  says what is still needed ("Noch nötig: Name und eine Zutat", "Noch nötig:
  Name", or "Noch nötig: eine Zutat"). The field that adds a line stays in view
  as the list grows. Closing the editor with changes asks first ("Rezept verwerfen?").
- Link intake: "Aus Link" reads a recipe page, shows its review, and opens the
  saved recipe. A page the app cannot read, or one without ingredient lines,
  opens the editor with the link as the recipe's source and with the name and
  portions typed in "Aus Link". Until the recipe has a line or a photo, a card
  there ("Von dieser Seite konnten wir nichts lesen") says to paste, scan, or
  type it, and "Nochmal versuchen" reads the page again.
- On Android, "Teilen" of text into the app works too: a link is read like
  "Aus Link", other text opens the editor with the text pasted. A text shared
  before the app reaches its home pages (start, data key, required update)
  waits until it gets there. A share the app cannot read shows a message ("Das
  konnten wir nicht lesen."). A household link never counts as a recipe share:
  it only opens the household page. iOS does not share text into the app yet.
- A saved recipe gets an AI estimate of its nutrition in the background: after
  saving, when a recipe without a fitting estimate opens, and, once the
  Kochbuch tab has been opened, for every recipe without one, at most 3 at once
  and each once per app run. The same lines and portions cost one AI call at a
  time, and an answer the AI cannot give is not asked again for them during
  the app run. A card shows a small spinner while its estimate runs or waits
  for its turn, then "≈ N kcal" and "P · KH · F". A failure is silent. The
  recipe page estimates each version of the lines and portions once while it
  is open.
- Only the food that matches the name best counts as the Vorrat food of an
  ingredient: when "Testreis" is kept in pieces, "100 g Testreis" is not
  supplied and no other rice stands in.
  A compound that only starts with the food, such as "Reiswaffeln" for
  "Reis", "Heringsfilet" for "Hering", or an item "Milch" for "Milchreis",
  is a weak match: it never fills the row or counts as stock, but "Aus dem
  Vorrat" offers it. The same holds for names of several words: "Fettarme
  H-Milch" for "Milchreis" and "Tomaten stückig" for "Tomatenmark" are weak,
  unless the two share a whole word ("Milch" and "Fettarme Milch" match; the
  part after a hyphen is a word of its own). "Basmatireis" for "Reis" ends in the food and fills
  the row, and so does a recipe amount word after the food, as in
  "Knoblauchzehen" or "Tomatenstücke"; so do "Buttermilch" for "Milch" and
  "Milchreis" for "Reis" (#891).
  A food that shares only a colour or kind word with the ingredient is a weak
  match too: "Schwarzer Tee" is no stock for "Schwarzer Pfeffer", on the recipe
  page, in the cookbook's check, and in the cooking. A food that shares its
  name is a match: "Zwiebeln rot" is stock for "2 Zwiebeln, fein gewürfelt",
  and "Eier Freiland" for "4 Eier (Größe M)". "Rote Beete" and "Rote Bete"
  count as the same food.
- The plan, the open ingredients of a prepared meal, and the shopping list
  read an amount like the recipe page: "½ Zitrone" is one piece, "1,250 kg
  Mehl" is 1250 g, number words ("zwei Zwiebeln") and "1 Pfund" are read.
  A product whose name starts with a number word is not that many pieces.
- The screen stays on while the "Gekocht" page is open.
- A Vorlage's "Kochen" goes straight on to the "Gekocht" page: the dish's name, which
  can still be changed and is saved with the step, the ingredients with
  their amounts and kcal, open rows with "Füllen" (opens the meal's detail
  page), and "Aufteilen": a "Portionen | Stück" switch, the count
  (stepper), the "Behälter" from the kitchen utensils, and "Auf der Waage".
  "Stück" (for wraps or burgers) hides the container and the scale and says
  that each piece is 1/N of the nutrients; the meal then counts "Stk" in
  place of "Port." in the Vorrat row, on the eat page, and in the diary's
  "Aus Vorrat essen" list. The page shows the food weight
  (pot minus empty container) and per portion grams and kcal, or only kcal
  per portion without weighing. Weighing is optional, but a weight needs a
  picked container ("Erst den Behälter wählen" blocks saving); without
  kitchen utensils, or when they fail to load, the scale row is hidden. A
  weight that is not above the empty container shows "Nicht schwerer als
  der leere Behälter" and blocks saving. "In den Vorrat" stores portions,
  the container's empty weight, and the food weight, and the meal leaves
  the pot; eating goes through the Vorrat afterwards. The "Ins Kochbuch"
  switch (off by default, also for a combined meal) also saves the cooked
  meal as a cookbook template with today's ingredients and amounts; when
  only the template fails, the meal stays in the Vorrat and a message says
  so. "Verwerfen" asks first, then gives the foods back to the Vorrat,
  deletes the items added only for this meal, and removes the meal; plans
  of a share of this pot stay and say their meal is gone. Closing the page
  keeps it in the pot. A meal that does not show up within a few seconds counts as
  gone, and the page says it could not be loaded. When another device puts
  the meal into the Vorrat while the page is open, the page closes and says
  "Diese Mahlzeit ist schon gekocht und im Vorrat."
- A meal in the pot shows "Im Topf" in the Vorrat list. Its detail page
  says "Im Topf" and keeps the meal actions, but blocks "Ins Tagebuch",
  because its portions are set at "Gekocht". The diary's "Aus Vorrat essen"
  list shows such a meal greyed out under the eatable foods, with "Im Topf"
  or "N Zeilen offen"; a tap opens the "Gekocht" page for a pot and the
  meal's detail page for open rows, as the Kochbuch's "Offen" cards do.
  Saving a diary entry for a meal in the pot fails as well. Once no row is
  open, the meal can be planned from its detail page as a share of the pot
  (the ruler counts in "Topf"; the whole pot is 1). Accepting such a plan
  after "Gekocht" eats the same share of the cooked portions; before
  "Gekocht" the check button says to mark the meal as cooked first.
- The eat page of a meal weighed in its pot at "Gekocht" has a "Topf auf der
  Waage" field. The pot on the scale minus the empty pot is what is left in
  the pot now ("− leerer Topf 1180 g = 990 g im Topf"); the amount switches
  to grams, the cook tares the scale and enters the grams taken out, and the
  share eaten is those grams of what is left. The weighing is stored on the
  meal for the household, so later eaters start from it; earlier entries do
  not change. Without a new weighing the grams left come from the last one
  (or "Gekocht"), scaled to the portions left. When the last weighing is
  older than 3 hours or someone ate since, the page reminds that water may
  have evaporated. A weight not above the empty pot blocks saving.
  With a known weight the nutrition table header names the grams
  ("1 Portion · 350 g") and a "Je 100 g" column beside the portion shows
  the meal's energy, fat, carbs and protein per 100 g of what is left, also
  after a weighing on the page. A meal not weighed after cooking has no such
  column: cooking changes the weight, so the raw ingredients' weights would
  give wrong values. For a pot meal the largest ruler mark is "Rest" (accent
  when picked): it takes everything in the pot, the header says "Rest", and
  a note says the sum is right without a scale.
- A card under "Offen" says "Im Topf seit …" (with "· N Zeilen offen" when
  rows are open) and "Weiter" opens the "Gekocht" page; the time becomes the
  day for a pot from an earlier day. A cooked meal with open rows says
  "Im Vorrat · N Zeilen offen" and "Füllen" opens its detail page, where the
  rows are filled. "Neue Vorlage" opens the Vorrat in selection mode (foods
  with a full label only); after "Übernehmen" a sheet asks for the name
  (the picked names to start with), and the foods with all of their stock
  become a Vorlage, with "Rückgängig". The Vorrat stays as it is; closing
  either step saves nothing.
  A Vorlage opens the recipe page too: one ingredient per food (packs of
  the same food together), sized for the chosen portions, then "Kochen" →
  "Gekocht". It has no steps.
  "Kochen" takes each food's own amount for the chosen portions from the
  Vorrat items it was combined from, else the best match, parts of a piece
  included where the item counts parts (a pack by weight counts as one piece,
  an item counted in whole pieces gives whole ones); what they lack stays an
  open row on the meal, in whole pieces so it can be filled from the Vorrat.
  A line shows at least one piece.
- A recipe opens its recipe page: the recipe photo with its source and name
  over it, the portions (stepper, "Original für N"), the ingredients sized
  for those portions, and the steps. Each ingredient is its amount and text,
  muted when the recipe ignores it.
- The recipe page also shows the estimate line ("≈ N kcal pro Portion ·
  geschätzt", with protein, carbs, and fat as coloured columns). While the
  estimate is being made, the line says "Wir schätzen die Nährwerte …" in
  their place and keeps their height, so nothing moves when they come. Under
  the ingredients, a food label shows one estimated portion ("1 Portion ·
  geschätzt"), in the recipe page and in the idea window, above the folded row
  "Nährwerte je Zutat" described next. The steps
  ("Zubereitung") show only when the recipe has some. When the recipe has
  values per ingredient, a folded row "Nährwerte je Zutat" under the
  ingredients opens a small table with kcal, protein, carbohydrates and fat of
  each ingredient. Its head row says "Für N Portionen", following the portion
  stepper (a recipe idea shows its own portions), and each row names the food
  alone ("Knoblauch" for "2 Zehen Knoblauch", "Zitrone" for "½ Zitrone",
  "Tomaten" for "1 Dose (400 g) Tomaten"). A recipe idea has them from the
  start; in its window an ingredient that the Vorrat holds shows a check. A
  scaled amount reads exactly ("2,5 TL", not "3 TL"). The page reads a line
  like the cooking does: "½ Zitrone", "eine halbe Zitrone", "zwei Zwiebeln",
  and "1,250 kg Mehl" (1250 g) get their amount. A line whose amount is too
  small to match ("0,1 g Safran", "1/4 Zitrone") keeps its text as written. Nothing scrolls under the
  status bar, and the photo starts below it. A pencil button beside
  "Entfernen" on the photo ("Bearbeiten") opens the recipe editor. A "Planen" button beside
  it is shown but does nothing yet. "Bearbeiten" is hidden for a Vorlage and while the
  recipe has a cook run. While a run exists, the portions are locked to the
  run. A status card shows as soon as a run exists. Its title says "Noch N
  offen" while a line is open, "N im Einkauf" while a line waits for the
  shopping, and "Alles bereit" otherwise; under it stand the counts that are
  not 0: "N bereit · N im Einkauf · N weggelassen · N offen". Each line shows
  its state: a check and what its Vorrat food holds, a cart and "im Einkauf",
  a minus and "weggelassen", or an empty circle and "offen". A ready line and
  a line in the shopping show the amount the cook chose for the run instead of
  the recipe's. A state shows
  only beside the line it was taken from, so a line changed on another device
  shows none. While a line is open, a hint says "Kochen" waits until every
  ingredient is ready or left out. Ingredients are settled on "Was hast du
  da?" (see Kochmodus), not on this page.
- The button at the foot of the recipe page of a recipe says "Vorbereiten"
  and opens "Was hast du da?" for the chosen portions. While a run exists it
  says "Weiter" and goes on with "Was hast du da?" as long as a line is open
  or waits for the shopping. Once every line is settled and cooking has not
  started, it says "Kochen" and opens the cooking page; after that it says
  "Weiter" and opens the cooking page again. It stays off for a recipe
  without a line. A Vorlage's "Kochen" puts it into the pot with the chosen
  portions and goes straight on to the "Gekocht" page: foods with a Vorrat item
  are taken from the Vorrat, the others stay open on the meal.
- A long press on a Vorlage or recipe opens a small menu with "Planen"
  and "Entfernen"; screen readers offer both as actions of the card.
- "Planen" asks for today or one of the next 14 days and plans one portion
  for the meal of the current time, with "Rückgängig". A recipe counts as
  cooked for its own portions, or those of its cook run, from the Vorrat food
  of each ingredient, counted as a full pack when the Vorrat holds less. That
  food is the one the recipe saved, else the best name match when it is kept
  in a fitting unit, never a weaker match in its place. A Vorlage keeps its
  own values for one portion.
  A recipe with an ingredient that has no Vorrat food, or whose foods give no
  kcal, uses the recipe's AI estimate when it fits (the entry is marked
  estimated, and the diary shows "≈ kcal"). Such a plan is a portion of the
  recipe, also when some ingredients have a Vorrat food: it lists no foods,
  its entry offers "Nochmal", and it takes nothing from the Vorrat. Without a
  fitting estimate, an ingredient without a Vorrat food makes it a reminder
  ("kcal offen", counts nowhere), and foods that give no kcal make it a plan
  of 0 kcal. A reminder gets a fitting estimate as soon as one comes. As soon
  as the recipe changes so that each ingredient has a Vorrat food, on this
  phone or another one of the household, a reminder or an estimated plan gets
  the recipe's values and counts like any plan; an estimated plan keeps its
  values while the recipe's foods give no kcal. Accepting a recipe plan logs it
  without taking stock ("Eingetragen – Vorrat nicht abgezogen"); a reminder
  takes the recipe's Vorrat foods then (saved, else the best match), or says
  "Erst alle Zutaten des Rezepts einem Vorrat zuordnen", or "Das Rezept ist
  nicht mehr im Kochbuch" with "Aus Plan entfernen".
  The recipe page has an "Entfernen" button on its photo, which closes the
  page. The Kochbuch then says "„Name“ entfernt", and "Rückgängig" saves it
  back as it was: the same id, photo, ingredients, steps, and saved Vorrat
  choices. Vorrat meals cooked from it stay as they are, and so does its
  photo, which such a meal may share.
- Editing a Vorlage from the Kochbuch is not available yet; a recipe is edited
  in its editor.

### Kochmodus

- A recipe's "Vorbereiten" on its recipe page opens "Was hast du da?";
  "Frei kochen" opens the cooking page. A cooking is one run for the
  household: a recipe has one run at a time, and "Weiter" on the recipe page or
  in the Kochbuch's "Läuft" section picks it up again, also on another device.
  A run with a line that is still open or waits for the shopping opens on "Was
  hast du da?" from both.
- "Was hast du da?" is a page of its own, before the cooking. It asks one
  ingredient at a time on a card: the amount very large, the food under it, and
  "Hab ich", "Kaufen", or "Weglassen". After an answer the next ingredient
  takes the card. Under the card, "Alle Zutaten" lists every ingredient with
  a picture, a badge (check, cart, or minus) and its state in a word; a tap on
  a row puts that ingredient on the card again. "+" at the top adds an
  ingredient. The portions come from the recipe page. The top of the page says
  "N von M geklärt" with a thin bar. Once every ingredient is settled the card
  says "Alles bereit", "Pro Portion · N kcal" and under it protein,
  carbohydrates and fat of one portion in grams, in their colours. The cook can close the page
  with "Später" at any time: the Vorrat stays "verplant" for the run. "Frei
  kochen" has no such page.
- Salt, pepper, water, pinches ("1 Prise Salz", "Msp.") and a recipe's own
  marked lines are not asked: they start left out and read "zählt nicht mit"
  on every page, without a strike-through, and the recipe page does not count
  them on its status card, also when the cook left one out. Any other line the
  cook left out reads "weggelassen" and is struck through.
  A kind word does not change that ("Schwarzer Pfeffer", "Grobes Meersalz",
  "Warmes Wasser"); "Schwarzer Tee" counts.
  "etwas Öl" and "Zucker nach Geschmack" are asked like any ingredient.
- "Alles bereit" shows the food label of one portion under the card; its energy
  and macros are the numbers of the card above. While an ingredient's weight is
  only estimated, the card says "Pro Portion · ≈ N kcal" and the label is
  headed "Portion · geschätzt".
- When "Was hast du da?" opens, and on "Kochen", a take that was cut for too
  little food is filled up again once more is there. A take is never cut
  there; weighed ingredients and ingredients that take nothing stay.
- The cooking page has the steps Töpfe (the kitchen utensils the cook uses, new
  ones can be added under "Topf oder Pfanne hinzufügen", with a short
  "Hinzufügen" button and a hint under the weight: "Leer, ohne Deckel. Einmal
  kurz auf die Waage stellen."; a new pot is chosen at once), Kochen, and Portion. It opens
  on Töpfe. Töpfe asks
  "Worin kochst du?" with the utensils, "Ohne Topf" for counted pieces, and
  "Danach in Dosen"; "Weiter · Kochen" stays off, with "Wähl einen Topf oder
  „Ohne Topf“.", until something is chosen, and "Ergibt:" names what comes out
  of the choice.
- The app never decides which Vorrat food an ingredient means and never says
  from a name whether the Vorrat has a food: the cook picks. The open card
  shows no hint about the Vorrat. "Hab ich" opens the Vorrat picker "Welches
  nimmst du?" whenever the Vorrat holds a food. It lists the whole Vorrat at
  once: the foods whose name matches the ingredient under "Passt vielleicht",
  then every other food under "Alles im Vorrat"; without a suggestion only the
  second group, without its title. The search above filters both. Every food
  that has nothing left says "verplant", or "für Pfannkuchen verplant" when
  another cooking with a name holds it; an ingredient without an amount
  ("Pfeffer") can take any food, also one that another cooking planned
  completely. A tap takes a food and the sheet closes once the foods cover the
  need, else it says "Es fehlen noch N" and offers "So lassen". An ingredient
  that is weighed while cooking ("1 Zwiebel" on a food kept in g) is covered by
  the one food the cook taps. "Etwas anderes suchen" stays in sight under the
  list. On an ingredient that has a food already, "Anderes nehmen" opens the
  picker with nothing tapped and the new pick replaces the old foods, also a pack found in the
  search; "Zweite Packung" opens it with the old foods tapped and keeps them.
- When the one food the cook picked holds more than the ingredient needs, and
  at most as much would be left as the ingredient takes (400 g of 500 g; not
  200 g of 1 kg, not 3 of 10 eggs), the app asks "Wie viel nimmst du?" with
  "400 g · wie im Rezept", "Alles · 500 g", and "Andere Menge" (the amount
  sheet). Closing the question keeps the amount the ingredient has. After the
  cook set an own amount, the question offers the recipe's amount again
  ("… · wie im Rezept" puts it back). The question scrolls on a small screen.
  Food and amount are stored in one step. It asks the same after "Aus dem
  Vorrat nehmen" and for a pack from the search or a scan. It never asks for a
  weighed ingredient or one with only a rough amount.
  With an empty Vorrat "Hab ich" opens the question "Welches Mehl hast
  du?": a large scan button first, "oder aussuchen" with the search (the
  ingredient's food already in it), "Aus dem Vorrat nehmen" as the first row,
  and at the foot "Egal, irgendeins", which estimates the values for the cook
  (with the line's addition in brackets, "Frischkäse (Doppelrahmstufe)");
  while it works, the page takes no other tap except the back arrow, and
  leaving then saves nothing. A food that is planned for
  something else is not offered there; a scan of it goes in as a new pack.
  The picker's "Etwas anderes suchen" opens the search too. "Kaufen" puts the
  ingredient on the shopping list, "Weglassen" cooks without it.
- A food from the Vorrat (a search hit, "Aus dem Vorrat nehmen", or a scanned
  pack that is already there) is taken from there: nothing is added or
  removed. A new food goes into the Vorrat first. The app asks no amount
  when it knows it: a food with a package size goes in as one full pack, an
  estimated food holds exactly what the ingredient needs. Only a food without
  a package size, a food in pieces without a weight of one piece on an
  ingredient in g or ml, or "Ändern" opens the amount page, with one big
  number ("Wie viel hast du davon zu Hause?", "Wie schwer ist die Packung?",
  or "Wie viele hast du?"). That amount is only what the cook has: the
  ingredient takes what it needs from the food, at most what is there, and the
  ingredient's other foods fill only what is still missing. A food without a
  package size that gets a weight of one piece there is kept in pieces. A new
  food leaves the Vorrat again if the cook cancels, the ingredient cannot
  take it, or the cooking is discarded and nobody used it. Under the card, a
  line says what "Hab ich" entered; when the ingredient cannot take from a new
  food yet (pieces without a weight on an ingredient in grams), it says
  "Eingetragen. Die Menge fehlt uns noch." and "Ändern" opens the amount page.
- Under the card, a line says what went in: the food and "1 kg eingetragen.
  Wir nehmen 250 g davon, 750 g bleiben.", "Werte geschätzt. Wir nehmen 250
  g.", "Aus dem Vorrat. Wir nehmen 400 g von 500 g.", "Aus dem Vorrat. 500 g
  da. Gewogen wird beim Kochen." (for an ingredient still to weigh), "1 kg
  eingetragen. Gewogen wird beim Kochen." (a new food, same case), or "Aus
  dem Vorrat. 350 ml da.", until the next answer; an estimated weight always
  reads "≈", never as a fact; it shows only when
  the ingredient takes something of the food. The card keeps room for two hint
  lines, so the answers do not move from one ingredient to the next. "Ändern" opens
  the amount page for a new food; for a Vorrat food it puts the ingredient
  back on the card.
- A ready ingredient on its card shows its amount, its food with what is
  there ("Mehl · 500 g da"), and calm notes: "Nur 300 ml" when the cook takes
  less than the recipe, "Rest steht auf der Einkaufsliste", and "≈ 180 g" when
  the weight is only estimated. An ingredient whose text names no amount counts
  with the recipe's rough weight for it ("≈ 20 g") until the cook sets an
  amount; with neither, it shows "Menge eintragen". A recipe that needs less
  than one piece of a food kept in pieces takes part of a piece. An ingredient
  whose food takes nothing counts as open until the cook picks another food.
- The question asks for the food's whole name: no amount, no measure ("EL",
  "Zehen"), no addition in brackets, and no small word before a capitalized one
  ("Zwiebel" for "1 mittlere Zwiebel", "Schwarzer Pfeffer" for "1/2 TL
  Schwarzer Pfeffer").
- An ingredient in EL or TL takes a standard spoon: the weight the recipe gives
  for it, else 15 g per EL and 5 g per TL. Only EL and TL are spoons: a cup,
  ladle or handful ("1 Tasse") is a measure like "1 Zehe" and stands under
  "Noch zu wiegen" on a food kept in g or ml. So "Egal, irgendeins"
  and the picker serve "2 EL Olivenöl" from any food kept in grams or
  millilitres. The weight stays with the cooking and never goes into the
  recipe. A scoop without a weight ("2 Tassen Reis") still waits.
- A spoon is never a weight: an ingredient in spoons always reads "≈", also
  when the recipe gives the weight of a spoon, and counts in "Bei N Zutaten
  haben wir das Gewicht geschätzt". When the recipe gives no weight, the
  standard spoon is only a guess: it takes what is there and never says "Zu
  wenig da" while the food has some left; the same holds for a guessed weight
  of pieces or a measure on a food kept in g or ml. When another cooking took
  stock since and less is left than the spoon took, the ingredient comes up as a
  card by itself and offers "Nur … nehmen" with what is there, never
  "Kaufen". A spoon with a part ("1/2 TL Zimt") and nothing left reads "Zu
  wenig da", not "Gewicht fehlt". An assigned ingredient that takes nothing
  and waits for a weight (such as "1 Möhre" on a food in g without a piece
  weight) says "Gewicht fehlt" as a warning, on its card "Gewicht fehlt: beim
  Kochen wiegen", not "Bereit". An ingredient that an older version
  assigned and that takes nothing keeps waiting for a weight until the cook
  acts.
- An estimated amount is said in the unit the food is kept in ("≈ 20 ml" for
  oil from a bottle in ml); a count in pieces ("3 Eier")
  is exact and never reads "≈". Amounts in that unit use the language's number
  format ("2,5 Stk.", "1.250 g"). The line under the card ("Aus dem Vorrat.
  … da.") says what is left of the food on the card.
- Whatever the app says is there for an ingredient ("350 ml da", "nur 200 g
  da") is what is left for this ingredient, in the unit the food is kept in,
  never in spoons. On "Portion", a row keeps the measure word ("5 Zehen
  Knoblauch") and shows no second line that only repeats the food's name.
- "Zu wenig da": a ready ingredient whose foods hold less than it needs says
  "Es fehlen N" and has three answers: "N kaufen" (the cook takes what is there
  and the rest goes on the shopping list as an ingredient of its own, or the
  whole ingredient goes shopping when nothing is there), "Zweite Packung" (the
  picker, to add another food), and "Nur N nehmen" (the cook takes what is
  there; it is not offered when nothing is there). Such an ingredient stays on
  the card until it is answered.
- Once nothing is left to answer, the card says: with ingredients waiting for
  the shopping, "Fast alles da" and "Erst einkaufen" alone: it puts them on
  the shopping list, pauses the cooking, and closes the page; a message with
  "Einkaufsliste" opens the list. Coming back from the shopping opens those
  ingredients again, with a note. Else "Alles bereit", "Mit Anleitung" (only
  when the recipe has steps), "Kochen", which opens the cooking page, and
  "Später".
- Assigned foods are reserved: the Vorrat marks them as "verplant", but
  nothing is taken before "Fertig".
- Tapping the amount of an assigned ingredient opens a sheet where the cook
  types the amount, or steps it with − and +. "Vorhandenes" fills what the
  assigned foods still have free for this line, "Rezept" the recipe's amount
  for the chosen portions; each shows only when it differs from the current
  amount. Applying the recipe's amount lets the line scale with the portions
  again.
- The Vorrat picker of an ingredient keeps the foods whose name matches on top
  under "Passt vielleicht", also for spoons ("1 EL Öl"), amounts it cannot
  read ("etwas Öl"), and pieces on a food kept in g or ml ("2 Zwiebeln"). Below
  them, "Alles im Vorrat" holds every other food in the Vorrat's sorting, with
  "Nach Beleg"; the sorting is shared with the Vorrat. The search field above
  filters both groups.
- An ingredient keeps the foods the cook chose for it. A food not needed now
  takes 0: it is not named, pictured, counted in the kcal, or booked, and the
  next change of portions or amount fills from it again.
- A found food comes first for its ingredient. So "Ändern" to another food for
  the same amount books that food only, and a found food also replaces one that
  left the Vorrat. A found food counted in another measure replaces the others
  when they cover the ingredient, and joins them when they fall short.
- Kochen shows the steps one by one, or the list. A timer starts from a time
  named in a step or from "Timer"; when it ends, the phone rings with a
  notification, and a tap opens the cooking. On Android the timer rings like
  an alarm clock, also on a muted phone, until it is tapped, swiped, or
  stopped, and for at most 10 minutes. The start of cooking asks for the
  notification permission once; the first timer asks only when the start did
  not. On Android the ask for exact alarms comes when cooking starts, not when
  an existing run is reopened, and it repeats at each start until the cook
  declines once.
- The guide shows a step's text and times only; it lists no ingredients under
  a step. "Zurück" on the first
  step goes to Töpfe. A tap on a single time in a step starts the timer at
  once, none while a timer of that name still counts; a span of two times asks which end. When notifications are off
  or Android may let the timer ring late, a hint with "Erlauben" stands under
  the times. Lines added while cooking sit under "Gerade dazu".
- The cook can speak or type what else goes into the pot. A said or typed
  weight ("30 g Öl", "Öl 30 Gramm", "1,5 kg Mehl") counts for the assigned
  ingredient with that name instead of adding a line; a second mention adds
  up, and "nein" undoes the last action, also after a switch between the guide
  and the list or between tabs; it does not undo a line the cook changed
  after speaking, but the one before. Parts without a weight in g, kg, ml,
  or l, or without a matching assigned ingredient, still become new lines.
- A said weight only lands on an ingredient that really is that food: its name
  or its food's name is the said word or ends with it ("Öl" on "Olivenöl"), not
  a word inside another one ("Wein" on "Schweinefilet", "Ei" on "Basmatireis").
  Accents and the umlaut of a plural do not matter ("Creme fraiche" is "Crème
  fraîche", "Apfel" is "Äpfel"). The everyday short name counts for the long
  one, also behind another word ("Hack" and "Rinderhackfleisch", "Hähnchen" and
  "Bio-Hähnchenbrust", "Knoblauch" and "Knoblauchzehen"). A bundled ingredient
  ("1 EL Öl, Salz, Pfeffer") is only its food up to the first comma, "oder", or
  "und".
- Kochen lists the assigned ingredients that are still to weigh under "Noch
  zu wiegen", one chip each; a tap opens the weighing. An ingredient in
  pieces, a measure ("Zehe") or without an amount that takes from a food kept
  in g or ml has only a guessed weight ("1 Zwiebel" is not "150 g"): it reads
  "≈ … geschätzt" and stays listed until
  the cook weighs it or sets an amount in g or ml. An ingredient in spoons, one
  from a food kept in pieces with its own piece weight (eggs), and one that
  does not count, and one whose food left the Vorrat ("Eintrag fehlt", without
  "Wiegen") are not listed. A weighed ingredient
  leaves the list. A line that takes nothing from the Vorrat and cannot follow
  a weight is not listed. For foods kept in g or ml, the Vorrat take and the
  kcal follow the weighed amount. A weight is a fact: the food is in the pot,
  so other cook runs' reservations do not limit it. If the foods hold less
  than the weight, "Fertig" waits with "nur N da" until the cook corrects the
  weight or picks another food. For foods counted in pieces or whole packs,
  the weight stays a record.
- On the cooking page g and ml count 1:1, so "100 g Milch" can take from milk
  kept in ml.
- The cooking page reads a line the way it is said: number words ("zwei
  Eier"), "halb", "eine halbe", "anderthalb", ½ ¼ ¾, "kilo", "liter",
  "milliliter", "pfund" (500 g), and a scale's "1,250 kg". The stored text
  stays as written. "Öl, 30 g" and "Öl, 30" are one line with that weight;
  a bare number there means grams.
- Only recipe lines scale with the portions. A line typed in or said counts
  as written, also after the portions change.
- Parts of a piece count exactly: "1/2 Zitrone" shows that and takes half of
  a lemon kept in pieces, "1 Zwiebel" at 1 of 4 portions shows "1/4 Zwiebel"
  and takes a quarter; a food kept in g or ml with a piece weight takes that
  part of the weight. A food only counted in whole packs takes at least 1, and
  the row says the whole number it takes.
- The amount sheet's number field holds whole numbers, so a part stays out of
  it: "1/4 Zwiebel" opens with an empty field and "1/4" as its hint. "Übernehmen"
  without typing changes nothing, and typing 1 means a whole onion.
- "2 Dosen Tomaten (à 400 g)" and "je 400 g" mean count times size: the row
  shows "800 g Tomaten", scaled with the portions. A bare "(800 g)" stays the
  total. So do a count and a size said in a row: "eine 400 g Dose Tomaten" is
  400 g, "zwei 200 g Becher Schmand" 400 g. In digits this needs a pack word
  behind the size, because "1 400 g Mehl" is 1400 g.
- The shopping list gets the same text as the row.
- A line without an amount on a food kept in pieces counts the cook's amount
  in pieces: 3 means 3 pieces. The sheet's unit and "Vorhandenes" follow the
  first assigned food. The unit stays with the amount: "3 Eier" still reads
  so on the shopping list, when the food is gone, and on another food; on a
  food kept in grams it then waits instead of taking 3 g.
- Every line reaches the meal or waits. "Fertig" waits while an assigned line
  takes nothing from the Vorrat: "{line}: erst wiegen oder entfernen" when
  weighing can help, "{line}: anderes Lebensmittel wählen oder entfernen" when
  the food is counted in pieces or packs that cannot supply the line. With
  several pots, an empty pot reads "{pot}: ohne Zutaten". A line that starts
  with a count nobody can read as a need ("2 cups Mehl") waits too, and so
  does a scoop out of a pack ("2 Tassen Reis", "ein Löffel Öl", "eine Handvoll
  Nüsse"): like "1 EL Senf" it takes no whole pack. A line in EL or TL does
  not wait on a food kept in grams or millilitres: it takes a standard spoon. A count of what stock is
  counted in ("1 Becher Sahne", "1 Dose Tomaten") takes that from a food kept
  in pieces. A pinch ("1 Prise Salz", "Messerspitze", "Spritzer", "Schuss",
  "Tropfen", also "ein guter Schuss Öl") and a line without a number ("Salz",
  "etwas Öl", "nach Geschmack") do not wait.
- On "Was hast du da?", a line that follows a weight shows the weighed amount
  on its amount link, and a tap opens the weighing keypad instead of the amount
  sheet.
- The Vorrat picker counts a food kept in the other of g and ml as a match
  when its name fits.
- A step of the instructions shows under its text the ingredients it names
  with their amounts ("2 EL Zucker"), as the cooking list says them: one that
  the cook left out is skipped, one that does not count (a pinch of salt) stays.
  A word of the ingredient has to stand in the step as a whole word:
  "Milchreis" does not name "Milch".
- While a pot waits for its weight on "Fertig gekocht", the main button says
  "Topf wiegen" ("Töpfe wiegen") and opens the weighing instead of staying off.
  Any other reason why "In den Vorrat legen" waits stands as a line above it;
  the button keeps its label. Counting without a pot says "Noch keine Zutat aus
  dem Vorrat". A meal in pieces never waits for the pot's weight: the field
  says "· freiwillig". With two pots a meal's label carries the name the meal
  has now.
- Portion ("Fertig gekocht") splits the meal into portions or pieces per pot,
  with the empty weight of the container and an optional weighing. The count
  question says "Wie viele Portionen sind es?", "Wie viele Stück sind es?", or
  "Wie viele Dosen sind es?". The count of a
  run's only meal follows a change of the portions while it still equals them;
  a count the cook set differently stays. Each ingredient is a row with its
  picture, what the cooking used (the weighed grams, or its amount, with "≈"
  when only the recipe's rough weight, and the name), and under it the food it
  takes from the Vorrat, or what is wrong ("Nimmt nichts aus dem Vorrat" when
  nothing). With several pots, a chip under the row names its pot; a tap moves
  the row to the next pot. The edit button opens the weighing, or "Was hast du
  da?" for a row that is not assigned or that weighing cannot help, such as a
  food without nutrition values; that sheet never offers "Kaufen". The remove
  button shows "Rückgängig", which puts the row back as it was; an ignored row
  has a "Zuordnen" button. When weights are only estimated, a line says "Bei N
  Zutaten haben wir das Gewicht geschätzt" with "Ansehen", which lists first the lines
  without a weight under "Noch zu wiegen", then the estimated ones; the line
  stands under the nutrition, not beside the button. N counts only estimated
  weights, not a line that does not count, and with none estimated the line
  says "Noch zu wiegen". The list says "Zeilen
  ohne Gewicht musst du wiegen" while a listed line takes nothing from the
  Vorrat.
- "In den Vorrat legen" puts the meals into the Vorrat in one step and takes
  the stock. A meal in cans or pieces has left the pot, so eating it never asks
  to weigh the pot; pieces store no weight either. Free cooking with "Ins
  Kochbuch" also saves a Kochbuch recipe whose lines carry the amounts this
  cooking used. "Verwerfen" in the menu gives everything back and offers an
  undo; a food that was added to the Vorrat for this cooking and that nobody
  uses is deleted again.
- "Guten Appetit!" follows: one sentence per meal ("8 Stück Pfannkuchen liegen
  jetzt im Vorrat.", with portions or cans, "Dose" and "Dosen" for cans), and
  "Das Rezept steht jetzt auch im Kochbuch." for free cooking saved as a
  recipe. "Jetzt essen" opens the page of the first meal in the Vorrat, and
  "Zum Kochbuch" goes back to the Kochbuch. It shows the macros of each meal in
  their colours: per portion, piece, or container.

## Meal Templates

- Import recipe templates from recipe links, currently centered on Chefkoch.
- Review imported recipe before saving.
- Portion scaling from base recipe portions.
- Ingredient assignment to inventory items.
- Ignored ingredient support for items like spices.
- Add one or many missing ingredients to shopping list.
- Create prepared meals from templates, including incomplete meals when
  ingredients are missing.

## AI Chef

- "Rezeptidee" in the "Neues Rezept" sheet (see Cookbook), set up in three
  rows without a title: "Vorrat zuerst" (switch), "Wünsche" (pills such as
  "Lachs" or "schnell", only for this idea), and "Bloß nicht"; the main
  action says "Rezept vorschlagen". A comma or semicolon ends a pill at
  once, so "Lachs, schnell" gives two pills.
- The Vorrat sent with an idea, and the "Unbedingt rein" list, leave out what
  open plans and running cook runs keep: a pack kept in full is missing, a
  pack kept in part goes with the rest. When the plans cannot be read, the
  Vorrat is handled like one that cannot be read.
- "Unbedingt rein": while "Vorrat zuerst" is on, the cook picks Vorrat items
  that must go into the recipe from a sheet with search, sorted by "Am
  längsten da" with each item's age in days (red from 7 days). The picks
  show as filled chips and go only with the Vorrat on; a pick eaten since
  then is left out of the request.
- A stored "Bloß nicht" list: ingredients the cook types once never appear
  in a suggested recipe. The list belongs to the user and follows them to
  every device; each entry can be removed with its chip. "Rezept
  vorschlagen" waits until the list is loaded.
- The recipe, with kcal, protein, carbohydrates and fat of each ingredient,
  comes from the server prompt template `recipe-idea-template`, which can
  change without an app release. The values of one portion are the sum of the
  ingredients divided by the portions. An answer that is not complete is a
  failed idea, with "Erneut versuchen".
- The cover picture is generated apart from the recipe and arrives later.
- The idea opens as a recipe in the Cookbook and is saved from there.

## Kitchen Utensils

- Kitchen utensil list.
- Add, edit, and delete utensils.
- Name, empty weight, and photo fields.
- Utensil image capture/pick/upload handling.
- Saved utensils available for the pot weight on "Gekocht".

## Shopping List

- Shopping list page with a switch "Haushalt · 5", "Privat · 2", "Beide · 7"
  at the top and a line under it that says who sees the list shown. The
  household list is shared with the household; the private list is the
  user's own, encrypted with the user's key. "Beide" shows both for one trip
  through the shop, with a lock on the private tiles. The choice is
  remembered on the phone. The add button says where an entry goes ("Zum
  Haushalt hinzufügen", "Privat hinzufügen"); in "Beide" it goes to the
  household.
- The entries show as tiles grouped by shelf in the order of a way through
  the supermarket (Obst & Gemüse first, Haushalt last), under a heading per
  shelf, with a line "3 von 9 im Wagen" and a bar over them. A tile shows
  the product's icon, the name, the brand, a note ("500 g", "Für Do ·
  Frühstück"), and the quantity when it is more than one. A product the app
  does not know sits under "Sonstiges" with a dashed outline. The order
  button switches between "Nach Regal" and "A–Z".
- The app knows common products in German and English with their shelf and
  icon, also as part of a longer name ("Vollkornnudeln" counts as pasta).
- A tap on a tile puts the entry into the cart; it keeps its quantity. The
  tile shows a tick for a moment before it moves, and a second tap in that
  moment takes the tick back. The cart sits under the tiles as chips; a tap
  on a chip puts the entry back on the list.
- A long press on a tile opens its details: quantity, shelf, Dauerauftrag,
  Favorit, "In den Wagen" and "Von der Liste nehmen". The shelf row asks
  "Wo steht X?" with all shelves; the choice is remembered for that product
  in the household.
- "Artikel hinzufügen" opens a sheet that stays open until "Fertig", so
  several entries go in one after another. Typing "2 Milch" adds two; a
  number in front of a unit ("500 g Hack") stays part of the name. While
  typing, the sheet offers favorites, products the Vorrat suggests (used up,
  almost empty, bought often) and products the app knows, each with its
  shelf, plus the typed text as a new entry with the shelf it will get, and
  "Mehr aus <Regal>" chips. With an empty field it offers the favorites as
  chips. What the sheet added shows as chips; a tap takes one back. Adding a
  product that is in the cart brings it back onto the list with the new
  quantity.
- Suggestions sit in a strip over the tiles that scrolls sideways. What the
  planned meals need and the Vorrat cannot cover comes first, with the meal
  it is for ("Für Do · Frühstück"); then what the Vorrat suggests. A tap puts
  one on the list, a planned one with its day and meal, which the tile shows
  in the language of each member; a day outside the coming week shows as its
  date. The cross pushes
  it behind the others, so the next ones move up; the order is remembered on
  the phone.
- "Liste importieren" in the app bar reads a list pasted as text or a
  photographed note with AI. A review shows each product with its shelf,
  note and count; products on the list already are unticked and say so.
  Lines that are not products are shown as skipped. The ticked ones go on
  the list in one step.
- "Fertig" opens a page with what is in the cart, how many stay open, and
  which saved products stay saved. "Einkauf abschließen" takes the cart of
  the list shown off the list; the receipt is imported later in the Vorrat.
  Favorites and products with a Dauerauftrag stay saved.
- Firestore-backed list repository.
- Public operations used by inventory and templates.
- Reminder the day before planned food that misses ingredients: a phone
  notification "Für morgen fehlen N Zutaten", at 17:00 by default. Foods
  already on the list do not count, and a day with nothing missing gets
  none. Tapping it checks again and asks "N Zutaten fehlen. Auf die
  Einkaufsliste setzen?" with each ingredient tickable; when nothing is
  missing any more it says "Für den Plan ist alles da." Once answered, the
  plan day stays quiet. "Nicht mehr fragen" turns the reminder off. The app
  asks for the notification permission once, with the first reminder. The
  text is counted when the app last ran, so a purchase by another household
  member while the app is closed shows only after the tap.

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
- Design: System (default), Light, Dark, or Individuell, as segments under
  Darstellung. A tap switches the app at once. The choice is saved on the
  device only. The home-screen widget keeps following the system.
- Accent color (System, Light and Dark only): Lime (default), Pink, Violet,
  Cyan, or Emerald, picked in a sheet under Darstellung. A tap recolors the
  app at once and the sheet stays open. The choice is saved on the device
  only. It recolors what is lime by default (main buttons, the tab marker,
  the kcal number and bar, links, selected chips such as training days) and
  the home-screen widget's kcal value and bar. In these designs macro,
  plan, weight, activity, and onboarding chapter colors are fixed; the plan
  color is brown. A plan color picked under the earlier "Plan-Farbe" row (never
  released) is dropped on purpose; own plan colors live in Individuell.
- Individuell: the first switch asks "Worauf aufbauen?" with a sample of
  Hell and Dunkel; the own colors start as a copy of that design with the
  picked accent (cancel keeps the design). The Darstellung section then
  shows "Farben bearbeiten" (with "Aufgebaut auf Hell/Dunkel") instead of
  the accent row. The editor shows a small diary day in the own colors
  (the app's snack bar on top, the budget card, a lunch with a plan, the scan
  button), a row of swatches (Eiweiß, Kohlenh., Fett, Plan, Akzent, Signal,
  Hintergrund, Karten, Text, Nebentext, Linien), and the switch "Makros
  immer bunt" under it. Nothing scrolls: the preview shrinks when room is
  short. A tap on a swatch or on a part of the preview opens a panel for
  that color in place of the swatches, so the preview stays in view: a
  color wheel (hue around, saturation out from the middle), beside it the
  last six taken colors ("Zuletzt", saved on the device), a brightness
  slider, "Abbrechen" and "Übernehmen". There is no readability check. The
  whole app, the editor and the panel too, follows every move;
  "Übernehmen", or a tap on another color, saves the color and puts it
  first in "Zuletzt"; "Abbrechen", back, or leaving the editor drops it.
  The undo arrow takes back the last saved color or reset, step by step,
  while the editor is open.
  Signal is the error color (errors, deleting, the over part of budget
  lines); snack bars take the card tinted with the accent, text in the
  text color.
  "Makros immer bunt" shows every macro of the budget card in its color
  instead of only the lowest one; it is one choice for every design, off by
  default, and the reset leaves it alone. The reset icon ("Farben
  zurücksetzen") asks "Worauf aufbauen?" again and starts the colors over
  as a copy of Hell or Dunkel; cancel keeps them. Picked
  macro colors show as picked, also as text on light paper. The choice is
  saved on the device only; the home-screen widget does not follow it yet.
- Language display.
- "Erinnerung für fehlende Zutaten" switch (on by default) and its time
  ("Uhrzeit", 17:00 by default) in the App section; the time row is greyed
  out while the switch is off. Saved on the device only. When the switch is
  on but the system blocks the app's notifications or mutes the reminder's
  channel, after the app has asked for the permission, the row says
  "Benachrichtigungen sind aus. Tippen zum Erlauben." and a tap opens the system settings; the row checks again when
  the user comes back to the app. Turning the switch on asks for the
  permission again.
- Privacy placeholder.
- About/app version tile.

## Recipes Support

- Recipe ingredient requirement parsing. An explicit "à" or "je" size multiplies
  by the count ("2 Dosen à 400 g" is 800 g); a bare size stays the total.
- Recipe ingredient unit modeling and display codes.
- Pending ingredient label formatting.
- Public parser used by inventory and meal templates.

## Shared UI Support

- Shared auth form widgets for email/password flows.
- Shared credential form constants and reusable auth components.
- Shared app/core widgets for responsive viewports, state views, cached images,
  haptics, nutrition strips, voice search bar, selection list tiles, and home
  shell chrome.
