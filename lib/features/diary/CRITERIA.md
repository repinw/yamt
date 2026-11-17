# Diary – Acceptance Criteria

## Kalorien-Übertrag optional + Wochenleiste (#911, with #318 and #922)

Sources used below:

- **Notes** = the user's decisions in the playground notes
  `kalorien-uebertrag-decisions.md`, all dated 2026-11-17; each criterion
  quotes the entry it comes from. "FREIGABE" is the entry "FREIGABE DES MOCKS
  (Version 50)". "KF" are the later entries "Kriterien-Fragen" (KF 1 =
  "Frage 1 (Standard)", KF 2 = "Frage 2 (leerer Tag), Platz, Fasten-Frage",
  KF 3 = "Frage 3 (Knopf ‚abschließen‘)", KF list n = item n of "Liste der
  kleinen Punkte").
- **Mock** = the approved artboard "Vorschlag · Wochenleiste"
  (`Vorschlag.dc.html`, artifact version 50). Its dark strip
  "Mock-Steuerung" is not part of the app. The rejected artboards
  (`Main.dc.html`, `Balken.dc.html`) are no source. Where a KF entry differs
  from the mock (intro overlay), the KF entry wins.
- **Issue** = GitHub issue text (#911, #922, #318, #875).

Words used below:

- **Run**: the fixed block of 7 days that starts on the goal's start day.
- **Goal**: the day's own kcal goal (normal day, training day).
- **Budget**: what the budget card counts against on that day: the goal, plus
  the carryover when the mode is "Mit Übertrag".
- **Mode**: the one choice "Aus", "Anzeigen" or "Mit Übertrag".
- **Empty day**: a finished day without entries that is no pause day.

Example values (from the mock) unless a criterion says otherwise: goal 2.200
kcal on every day, weight goal "Abnehmen".

**Group: mode and menu**

### K1 – Holding the week card opens its menu
Source: notes ("Einstellungen über Halten (#930)", "zeig im mock"); FREIGABE; mock; KF list 11 (menu name).
Given: the week card is shown (mode "Anzeigen" or "Mit Übertrag").
When: I hold the card (long press).
Then: a menu sheet opens with the heading "Wochenzielbalance" and the choice of the mode.

### K2 – The menu offers exactly three modes
Source: FREIGABE ("Auswahl ‚Aus · Anzeigen · Mit Übertrag‘"); mock (option texts).
Given: the menu of the week card is open.
Then: it lists three options, one of them selected:
| Option        | Line below it                                       |
| ------------- | --------------------------------------------------- |
| Aus           | Jeder Tag steht für sich.                           |
| Anzeigen      | Zeigt die Woche. Dein Tagesbudget bleibt gleich.    |
| Mit Übertrag  | Gleicht die Woche aus, höchstens <limit> kcal pro Tag. (see K35) |
And: below the options stands "Später ändern: in den Einstellungen."
And: there is no separate switch for "Übertrag" and none for "anzeigen"; a
carryover without the week card cannot be chosen.

### K35 – The "Mit Übertrag" line names the user's own limit
Source: notes, entry "Kriterien-Fragen · Punkt 13" (13a, 2026-11-17); FREIGABE (20 % / 350 kcal); mock (line text).
The limit is 20 % of the goal, at most 350 kcal.
| Goal  | Line under "Mit Übertrag"                            |
| ----- | ---------------------------------------------------- |
| 2.200 | Gleicht die Woche aus, höchstens 350 kcal pro Tag.   |
| 1.750 | Gleicht die Woche aus, höchstens 350 kcal pro Tag.   |
| 1.600 | Gleicht die Woche aus, höchstens 320 kcal pro Tag.   |
| 1.500 | Gleicht die Woche aus, höchstens 300 kcal pro Tag.   |
| 1.200 | Gleicht die Woche aus, höchstens 240 kcal pro Tag.   |
| 1.500 on normal days, 1.750 on training days | Gleicht die Woche aus, höchstens 300 kcal pro Tag. |
With training days, the line uses the normal day's goal (notes, entry
"Kriterien-Fragen · letzte Punkte", point 3, 2026-11-17).
The same line stands in the settings (K4).

### K36 – The profile's training note names the carryover as a condition
Source: notes, entry "Kriterien-Fragen · Punkt 13" (13b, 2026-11-17: "Bei eingeschaltetem Übertrag").
Given: any mode.
When: I open the training part of the profile.
Then: the note about the run is always shown, and its part about passing on what past days got differently starts with "Bei eingeschaltetem Übertrag".
And: the note no longer says without condition that the carryover passes it on.
The exact wording is left to the l10n step.

### K3 – "Aus" removes the week card
Source: FREIGABE; mock.
Given: the menu of the week card is open.
When: I pick "Aus".
Then: the menu closes and the week card is gone from the diary.
And: the budget card counts against the plain goal (K6).

### K4 – The mode can also be changed in the settings
Source: mock (text "Später ändern: in den Einstellungen."); KF list 11.
Given: the mode is "Aus", so the diary shows no week card.
When: I open the app settings.
Then: next to "Schritte im Tagebuch" stands the same choice with "Aus", "Anzeigen" and "Mit Übertrag".
When: I pick "Anzeigen" or "Mit Übertrag" there.
Then: the week card is back in the diary, and the menu of the card shows the same mode.

### K5 – The mode is stored per account
Source: issue #911 ("Gespeichert wird pro Konto").
Given: I picked "Mit Übertrag".
When: I sign in with the same account on another phone, or after a reinstall.
Then: the mode is "Mit Übertrag" there as well.

### K31 – Everyone starts with "Anzeigen"
Source: KF 1 ("übertrag aus ist für jetzige nutzer und alle neuen"); KF 2 ("ENTSCHIEDEN: Standard ist ‚Anzeigen‘ […] für alle").
Given: a new account, or an account from before this feature that never picked a mode.
When: I open the diary.
Then: the mode is "Anzeigen": the week card is shown and the budget card counts against the plain goal (K6).

### K32 – No intro on the card; "Was ist neu" tells the change
Source: KF list 10.
Given: I see the week card for the first time.
Then: nothing lies over the card; there is no intro and no "OK" button on it.
And: the "Was ist neu" of this version has an entry about this change (the carryover is now off by default). Its text is not fixed yet (l10n step); a test checks only that the entry exists.

### K30 – A mode switch recomputes the whole running run
Source: KF list 1; issue #911 ("An- und Ausschalten rechnet den ganzen Run neu").
Given: mode "Mit Übertrag"; this run: Monday 2.200, Tuesday 1.900, Wednesday 3.000 eaten (Wednesday's budget was 2.260, Thursday's is 2.075); "Details" open.
When: I switch to "Anzeigen".
Then: Thursday's budget card shows the plain goal 2.200, and under Wednesday stands "+800" instead of "+740".
When: I switch back to "Mit Übertrag".
Then: Thursday's budget is 2.075 again and under Wednesday stands "+740" again.

**Group: fixed daily budget ("Aus" and "Anzeigen")**

### K6 – The daily budget does not move by itself
Source: notes ("fakt ist, die nutzer mögen es nicht dass man an ihren kcal rumspielt", "wir zeichnen keine zone mehr ein […] wenn jemand den übertrag einschaltet, dann wird es einfach verrechnet"); FREIGABE ("Übertrag optional"); issue #911 (Aus: "Jeder Tag hat nur sein eigenes Ziel").
Given: mode "Aus" or "Anzeigen"; in this run Tuesday I ate 1.900 and Wednesday 3.000.
When: I open the diary on Thursday before eating.
Then: the budget card shows "2.200" "kcal übrig".
And: it is the same on every other day of the run, whatever I ate before.

### K7 – Without the carryover, the budget card names no week
Source: notes ("das soll nicht stehen, wenn man nicht verrechnet": no sign, no row in the details); issue #911.
Given: mode "Aus" or "Anzeigen", and earlier days of the run were over or under the goal.
When: I open "Details" on the budget card.
Then: the ledger has no row "Übertrag aus der Woche", there is no chip "… aus der Woche", and nothing on the card mentions the week.

### K8 – Without the carryover, the macro targets follow the plain goal
Source: issue #911 ("Die Makroziele folgen dann auch nur dem Tagesziel"); KF list 5.
Given: mode "Aus" or "Anzeigen", and Wednesday of this run was 800 kcal over.
When: I look at the macro targets on Thursday.
Then: they are the same as on a day without anything over or under before it.

### K9 – No "<Wochentag> abschließen" in any mode
Source: KF 3 ("so wie du es sagst. nichts zum abschließen ohne übertrag": the button is struck); issue #922.
Given: any mode.
When: I open tomorrow in the diary.
Then: the budget card shows no button "<Wochentag> abschließen" (e.g. no "Do abschließen") and no "<Wochentag> abgeschlossen".

### K34 – Sheet "Alle Tage" shows the carryover only with the carryover
Source: KF list 9.
Given: mode "Aus" or "Anzeigen".
When: I open "Alle Tage" from the budget card's details.
Then: the sheet has no section "Übertrag aus den Vortagen".
And: in mode "Mit Übertrag" the section is there.

**Group: with the carryover ("Mit Übertrag")**

### K10 – With the carryover, the daily budget includes it
Source: notes ("Übertrag ist ein Schalter, an = verrechnet wie die App heute"); FREIGABE; mock; KF list 12.
Given: mode "Mit Übertrag"; this run: Monday 2.200, Tuesday 1.900, Wednesday 3.000 eaten.
When: I open the diary on Thursday before eating.
Then: the budget card shows "2.075" "kcal übrig" (budget per K11).
When: I open "Details".
Then: under the big number stands the chip "2.200 − 125 aus der Woche", and the ledger has the row "Übertrag aus der Woche" with "−125".
When: I close "Details".
Then: the chip is gone.
And: on a day with a positive carryover the chip adds it, e.g. Sunday after six days of 1.900: "2.200 + 350 aus der Woche" and the row "+350" (mock).
And: on a day with carryover 0 there is neither chip nor row.

### K11 – The carryover of a day
Source: notes ("Stand am 2026-11-17", point 2; "ja, in beide richtungen"; "Ja, nie unter 1.200"; Ist-Zustand: balance of the run's finished days divided by the run's remaining days, today included; user report "budget von 2700 […] jeden tag an die 300 eingespart"); FREIGABE ("in beide Richtungen gedeckelt (20 % / 350 kcal, nie unter 1.200)"); KF 2 (empty day does not count); KF list 4 (20 % of the day's goal, training day included); mock scenarios.
Balance = sum of (goal − eaten) over the finished days of the same run. A
pause day and an empty day add 0. Carryover per day = balance ÷ remaining
days of the run (today included), limited to 20 % of that day's goal (on a
training day: of its higher goal) and at most 350 kcal, in both directions,
and never so far that the budget falls below 1.200. Whatever is left at the
end of the run is dropped.
| Goal today          | Finished days of the run (eaten)                 | Today is run day | Carryover | Budget today |
| ------------------- | ------------------------------------------------ | ---------------- | --------- | ------------ |
| 2.200               | none                                             | 1                | 0         | 2.200        |
| 2.200               | 2.200 · 1.900 · 3.000                            | 4                | −125      | 2.075        |
| 2.200               | 2.200 · 2.200 · 2.200                            | 4                | 0         | 2.200        |
| 2.200               | 2.200 · 6.750 (whole cake)                       | 3                | −350      | 1.850        |
| 2.200               | six days of 1.900                                | 7                | +350      | 2.550        |
| 2.700               | six days of 2.400                                | 7                | +350      | 3.050        |
| 2.200               | 2.300 · 2.300 · 2.300 (balance −300)             | 4                | −75       | 2.125        |
| 2.200               | 2.200 · empty day · 3.000                        | 4                | −200      | 2.000        |
| 2.200               | six empty days                                   | 7                | 0         | 2.200        |
| 1.500               | 4.500 (balance −3.000)                           | 2                | −300      | 1.200        |
| 1.500               | 3.000 on a day that was a pause day (balance 0)  | 2                | 0         | 1.500        |
| 1.500               | six days of 1.300 (balance +1.200)               | 7                | +300      | 1.800        |
| 1.750 (training day)| balance −2.400                                   | 5                | −350      | 1.400        |
| 1.300               | balance −1.300                                   | 7                | −100      | 1.200        |
| 1.200               | balance −2.000                                   | 5                | 0         | 1.200        |
| 1.200               | balance +600                                     | 6                | +240      | 1.440        |
| 2.200               | previous run ended with balance −2.000           | 1 of a new run   | 0         | 2.200        |
Rows without "training day" are normal days; weight goal "Abnehmen".

### K26 – Preview of the carryover on coming days
Source: KF list 3; notes ("der übertrag wirkt sich auf alle folgetage aus, nicht nur auf den nächsten"); mock (preview).
The preview assumes that today and every day until the shown day hit their
budget. What today is already over its budget counts at once; what today is
under its budget counts only after the day is over. Each coming day then gets
its carryover by K11.
Mode "Mit Übertrag", goal 2.200.
The run starts on a Monday.
| Finished days of the run       | Today (run day) | Budget today | Eaten today | Preview carryover of each coming day |
| ------------------------------ | --------------- | ------------ | ----------- | ------------------------------------ |
| Mo 2.200 · Tu 1.900 · We 3.000 | Thursday (4)    | 2.075        | 900         | Fr −125 · Sa −125 · Su −125          |
| Mo 2.200 · Tu 1.900 · We 3.000 | Thursday (4)    | 2.075        | 2.075       | Fr −125 · Sa −125 · Su −125          |
| Mo 2.200 · Tu 1.900 · We 3.000 | Thursday (4)    | 2.075        | 3.075       | Fr −350 · Sa −350 · Su −350          |
| Mo 2.200                       | Tuesday (2)     | 2.200        | 6.750       | We, Th, Fr, Sa, Su −350 each         |
| Mo 2.200                       | Tuesday (2)     | 2.200        | 1.000       | We, Th, Fr, Sa, Su 0 each            |
| Mo–Fr 1.900 each               | Saturday (6)    | 2.550        | 1.900       | Su +350                              |
| none                           | Monday (1)      | 2.200        | 2.800       | Tu −100 · We −100 · Th −100 · Fr −100 · Sa −100 · Su −100 |

### K27 – With the carryover, every coming day's budget card shows the preview
Source: KF 3 ("mit Übertrag zeigt die Budget-Karte von morgen dieselbe Vorschau wie die Leiste"); notes, entry "Kriterien-Fragen · letzte Punkte", point 1 (every coming day, not only tomorrow).
Given: mode "Mit Übertrag"; first row of K26 (Thursday, 900 eaten so far).
When: I open Friday, then Saturday, then Sunday in the diary.
Then: each budget card shows "2.075" "kcal übrig", the same budget as that day's field in the week card.
When: I eat 2.175 more on Thursday (3.075 in total) and open Friday, Saturday and Sunday again.
Then: each of their budget cards shows "1.850".
And: in mode "Aus" or "Anzeigen", every coming day's budget card shows the plain goal "2.200".

### K12 – With the carryover, the macro targets follow the budget
Source: issue #911 (macros count the carryover today, see #875; only "Aus" takes it out); notes Ist-Zustand ("Die Makroziele folgen dem Ziel plus Übertrag (#875)"); mock (macro targets follow the budget); KF list 5.
Given: mode "Mit Übertrag" and a budget of 2.075 today (K10).
Then: the macro targets of today are those of a 2.075 kcal day, not of a 2.200 kcal day.

### K33 – Everything that uses the day's budget uses the big number's budget
Source: KF list 5.
Given: mode "Mit Übertrag" and a budget of 2.075 today (K10); I ate 2.000.
Then: the budget card shows "75" "kcal übrig", and the home screen widget shows the same 75 kcal left.
And: the card wears the gold foil (2.000 is within 5 % of 2.075).
And: the pace marker, the meal targets and the message about freed kcal are worked out from 2.075.
Given: the same day in mode "Anzeigen" (budget 2.200), 2.000 eaten.
Then: card and widget show 200 kcal left, and the card has no gold foil (2.000 is more than 5 % under 2.200).
Phone only: the home screen widget and the timed message.

### K13 – The mode never changes the learned TDEE
Source: issue #911 ("Das TDEE-Lernen ist nicht betroffen").
Given: a learned TDEE from past weeks.
When: I switch between "Aus", "Anzeigen" and "Mit Übertrag".
Then: the learned TDEE stays the same.

**Group: week card (modes "Anzeigen" and "Mit Übertrag")**

### K14 – The week card is a strip of seven day fields
Source: FREIGABE ("schlanke Leiste aus sieben Tagesfeldern ohne Titel und ohne Wochensumme"); notes ("dann sieht man direkt in welchem 7 tage run tag man sich befindet"); KF 2 ("zwischen schritte und tagesbudget"); mock.
Given: mode "Anzeigen" or "Mit Übertrag".
When: I open today in the diary.
Then: between the budget card and the steps card stands a card with seven fields, one for each day of the current run, in their order.
And: the card has no title and no total for the week.

### K37 – No strip without a run
Source: notes, entry "Kriterien-Fragen · letzte Punkte", point 2 (2026-11-17: "Ohne laufende Woche (kein Ziel gesetzt, Run beendet) gibt es keine Leiste").
Given: mode "Anzeigen" or "Mit Übertrag".
When: the diary shows a day while no goal is set, or a day after the goal's run has ended.
Then: there is no week card; the steps card follows the budget card directly.

### K15 – Day names under the fields
Source: mock; notes (Vorschlag Version 34, point 3).
Given: the week card is shown; today is the 4th day of a run that started on a Monday.
Then: the fields are named "Mo", "Di", "Mi", "Heute", "Fr", "Sa", "So".
And: "Heute" is bold and its field has a frame.
And: a run that starts on another weekday names its fields from that weekday on.

### K28 – On another day, the strip shows that day's run
Source: KF list 6.
Given: today is Thursday, the 4th day of a run that started on a Monday.
When: I page the diary to Tuesday.
Then: the strip shows the same run, Tuesday's field has the frame, and the field names are "Mo", "Di", "Mi", "Heute", "Fr", "Sa", "So" ("Heute" stays at the real today).
When: I page to a day of the previous run.
Then: the strip shows the seven days of that previous run with the frame on the shown day, and no field is named "Heute".

### K29 – A plain tap on the strip does nothing
Source: KF list 8; mock.
Given: the week card is shown.
When: I tap the card briefly.
Then: no menu opens and nothing on the screen changes.

### K16 – A finished day's field is that day's kcal bar
Source: notes (Vorschlag Version 34, points 1–2, approved as "gefällt mir" and in FREIGABE); mock; KF list 2 (against that day's budget).
Given: the week card is shown.
Then: each field of a finished day fills from the left like the line of the budget card, against that day's budget.
And: a day over its budget shows the whole day, and only the part above the budget is red (e.g. 6.750 eaten at 2.200: about two thirds red).
And: a day under its budget keeps an empty tip at the end.
And: the days do not run into each other; each field shows only its own day.
And: all seven fields have the same width; a training day is measured against its higher budget but its field is not wider (mock; notes, entry "Kriterien-Fragen · letzte Punkte").
Phone only: proportions and how it reads.

### K17 – Coming days are an empty dashed outline
Source: notes (Vorschlag Version 34, point 2); mock.
Given: the week card is shown, mode "Anzeigen".
Then: the fields of the days after today are empty with a dashed outline.

### K18 – A pause day has its own field and does not count
Source: notes ("bei pause tag soll der balken anders gezeichnet werden"; "Klärung: […] Pausentage […] zählen nicht"); mock.
Given: Tuesday of this run was a pause day on which I ate 3.000.
Then: Tuesday's field is drawn hatched, not as a kcal bar, and it has no red part.
And: with "Details" open it is labelled "Pause" instead of a number.
And: in mode "Mit Übertrag" Tuesday adds nothing to the balance (K11).

### K25 – An empty day is "leer" and does not count
Source: KF 2 ("der tag soll leer sein"; "ENTSCHIEDEN: Ein Tag ohne Einträge ist ‚leer‘ und zählt im Übertrag nicht"); mock (label "leer").
Given: Tuesday of this run is over and has no entries, and it is no pause day.
Then: Tuesday's field is an empty track, with no fill and no red part.
And: with "Details" open it is labelled "leer" instead of a number.
And: in mode "Mit Übertrag" Tuesday adds nothing to the balance (K11).

### K19 – Numbers under the days only with "Details"
Source: FREIGABE ("Zahlen unter den Tagen nur bei offenen Details"); notes ("das war schon gut": numbers under the days, + = more eaten); mock.
Given: the week card is shown.
When: I tap "Details" on the budget card.
Then: numbers appear under the finished days of the week card (K20); nothing appears under today and the coming days.
When: I tap "Details" again.
Then: the numbers under the days are gone.

### K20 – The number under a finished day
Source: notes ("das war schon gut": "+300 = 300 mehr gegessen als das Ziel, −300 = weniger"); mock (shown from 50 kcal off; sign "−"); KF list 2 (with carryover: against that day's budget); KF 2 ("leer").
The number is eaten minus that day's budget. "Details" open.
| Mode          | That day's budget | Eaten that day        | Shown under the day |
| ------------- | ----------------- | --------------------- | ------------------- |
| Anzeigen      | 2.200             | 3.000                 | +800                |
| Anzeigen      | 2.200             | 6.750                 | +4.550              |
| Anzeigen      | 2.200             | 1.900                 | −300                |
| Anzeigen      | 2.200             | 2.250                 | +50                 |
| Anzeigen      | 2.200             | 2.150                 | −50                 |
| Anzeigen      | 2.200             | 2.230                 | nothing             |
| Anzeigen      | 2.200             | 2.200                 | nothing             |
| Anzeigen      | —                 | pause day, any amount | Pause               |
| Anzeigen      | —                 | no entries            | leer                |
| Mit Übertrag  | 2.260             | 3.000                 | +740                |
| Mit Übertrag  | 1.850             | 1.850                 | nothing             |
| Mit Übertrag  | 1.850             | 2.200                 | +350                |
The number is never capped (notes: "Anzeige ungedeckelt, Verrechnung gedeckelt").

### K21 – With the carryover, each field shows its share
Source: FREIGABE ("Schuld als dunkles Stück vorne in allen Folgetagen, Zusatz gestrichelt hinten"); notes ("der übertrag wirkt sich auf alle folgetage aus, nicht nur auf den nächsten"; "ja, mal es in den mock" for the piece that runs into the next day); KF list 3; mock.
Given: mode "Mit Übertrag".
Then: a day with less budget (negative carryover) has a dark piece at the front of its field as long as the carryover; what was eaten that day follows behind it, and red starts at that day's budget.
And: a day with more budget (positive carryover) has a dashed extra piece at the end of its field as long as the carryover.
And: today and every coming day of the run show their piece at once, not only tomorrow; coming days use the preview of K26.
And: in mode "Anzeigen" no field has such a piece.
Phone only: whether the dark piece reads as "from the days before" and whether a small piece (e.g. 25 kcal) is still visible.

**Group: colours follow the weight goal**

### K22 – Weight goals "Abnehmen" and "Halten": over is red
Source: notes ("Sollen die Farben dem Ziel folgen, und zwar in beiden Karten?" → "Ja, gleich mit"); KF list 7 ("Halten" like "Abnehmen"); mock (goal "Abnehmen").
Given: weight goal "Abnehmen" or "Halten", "Details" open.
Then: on the budget card "kcal drüber" and the part of the line over the budget are red.
And: in the week card "+800" under a day is red, "−300" is grey, and the field of a day under its budget is not red.

### K23 – Weight goal "Zunehmen": short is red, over is not
Source: notes ("Ja, gleich mit"); mock (goal "Zunehmen").
Given: weight goal "Zunehmen", "Details" open.
Then: on the budget card "kcal drüber" and the part of the line over the budget are not red.
And: in the week card "+800" under a day is not red; "−300" under a day is red and that day's field is red.
And: the words and directions stay the same as for "Abnehmen" ("kcal übrig", "kcal drüber", "+" = more eaten).
And: today never turns red for being under, because the day is not over yet.

**Open points (no criterion depends on them)**

- "Was ist neu" text: l10n step (K32 checks only that the entry exists).

- O1: decided 2026-11-17 (entry "Kriterien-Fragen · Punkt 13"), now K35 and K36.
- O2 (KF 2): asking the next day whether an empty or very low day was a
  fasting day. Separate issue idea, not part of #911.
- O3: whether the strip "Tagesarten im Run" in the budget card's details stays
  next to the new week card.
