# Diary – Acceptance Criteria

## Kalorien-Übertrag optional + Wochenleiste (#911, with #318 and #922)

Sources used below:

- **Notes** = the user's decisions in the playground notes
  `kalorien-uebertrag-decisions.md`, dated 2026-11-17 unless named
  otherwise below (the KF 3 entries of 2026-11-18); each criterion
  quotes the entry it comes from. "FREIGABE" is the entry "FREIGABE DES MOCKS
  (Version 50)". "KF" are the later entries "Kriterien-Fragen" (KF 1 =
  "Frage 1 (Standard)", KF 2 = "Frage 2 (leerer Tag), Platz, Fasten-Frage",
  KF 3 = "Frage 3 (Knopf ‚abschließen‘)", KF list n = item n of "Liste der
  kleinen Punkte"). "KF 3 KORREKTUR" is the entry "KORREKTUR 2026-11-18"
  under KF 3, dated 2026-11-18; it replaces the first reading of KF 3.
  "KF 3 O4" is the entry "2026-11-18, Frage O4" under KF 3 (user's answer
  "Überall"). "KF 3 Session" is the entry "2026-11-18, von der Session
  entschieden, dem User gesagt, kein Einwand" under KF 3: decided by the
  session and told to the user, who did not object; these are not the
  user's own words.
- **features.md** = `features.md` on master, the Diary part about
  "<Wd> abschließen": how the button behaves today. The user decided to keep
  the button (KF 3 KORREKTUR), so this behaviour is a source where no newer
  decision differs.
- **Mock** = the approved artboard "Vorschlag · Wochenleiste"
  (`Vorschlag.dc.html`, artifact version 50). Its dark strip
  "Mock-Steuerung" is not part of the app. The rejected artboards
  (`Main.dc.html`, `Balken.dc.html`) are no source. Where a KF entry differs
  from the mock (intro overlay), the KF entry wins.
- **Issue** = GitHub issue text (#911, #922, #318, #875).

Words used below:

- **Run**: the fixed block of 7 days that starts on the goal's start day.
  A new goal starts a new run on its start day; the old run ends the day
  before, even if it had fewer than 7 days (notes, entry "2026-11-18,
  Review-Frage zu K28", user: "neues ziel setzt einen neuen 7 tage run
  voraus.").
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
And: below the options stands "Später ändern: in den Einstellungen." when the menu was opened by holding the week card; opened from the settings, the line is missing (K4; notes, entry "2026-11-19 Handytest: Einstellungs-Zeile funktioniert", user: "ja, lass weg").
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

### K4 – The mode can also be changed in the settings, through one row
Source: mock (text "Später ändern: in den Einstellungen."); KF list 11; notes, entry "2026-11-19 Handytest, Einstellungen" (user: "ja, mach eine zeile draus").
Changed 2026-11-19: before, the three options stood expanded in the settings.
Given: the mode is "Aus", so the diary shows no week card.
When: I open the app settings.
Then: next to "Schritte im Tagebuch" stands one row "Wochenzielbalance" with the chosen mode as its subtitle: "Aus".
And: the three options are not shown expanded in the settings.
When: I tap the row.
Then: the same menu opens as when I hold the week card (K1, K2, K35): heading "Wochenzielbalance", the three options with their lines, "Aus" selected.
And: the menu has no line "Später ändern: in den Einstellungen." (notes, entry "2026-11-19 Handytest: Einstellungs-Zeile funktioniert", user: "ja, lass weg").
When: I pick "Mit Übertrag" there.
Then: the menu closes and the row's subtitle reads "Mit Übertrag".
And: the week card is back in the diary, and the menu of the card shows the same mode.

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

### K9 – Without the carryover, no "<Wochentag> abschließen"
Source: KF 3 ("nichts zum abschließen ohne übertrag"); KF 3 KORREKTUR (2026-11-18: the button stays in "Mit Übertrag", "in ‚Aus‘ und ‚Anzeigen‘ gibt es ihn nicht"); issue #922.
Changed 2026-11-18: before, the button was struck in every mode; that misread KF 3.
Given: mode "Aus" or "Anzeigen".
When: I open tomorrow in the diary.
Then: the budget card shows no button "<Wochentag> abschließen" and no "<Wochentag> abgeschlossen".
And: in mode "Mit Übertrag" the button is there (K38).

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
| 2.000 (new goal from today, Thursday) | old run Mo 2.200 · Tu 1.900 · We 3.000 (balance −500), cut short by the new goal | 1 of a new run | 0 | 2.000 |
The last row: a new goal ends the old run the day before (notes, entry
"2026-11-18, Review-Frage zu K28"); the old run's balance never reaches a day
of the new run.
Rows without "training day" are normal days; weight goal "Abnehmen".

### K26 – Preview of the carryover on coming days
Source: KF list 3; notes ("der übertrag wirkt sich auf alle folgetage aus, nicht nur auf den nächsten"); mock (preview).
The preview assumes that today and every day until the shown day hit their
budget. What today is already over its budget counts at once; what today is
under its budget counts only after the day is over. Each coming day then gets
its carryover by K11.
This table is for a today that is not closed. Once today is closed (K39),
today counts as a finished day for every coming day, in the week card and on
the budget cards alike, so what today is under its budget counts at once too
(KF 3 O4).
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
Given: mode "Mit Übertrag"; first row of K26 (Thursday, 900 eaten so far); today is not closed (K39).
When: I open Friday, then Saturday, then Sunday in the diary.
Then: each budget card shows "2.075" "kcal übrig", the same budget as that day's field in the week card.
When: I eat 2.175 more on Thursday (3.075 in total) and open Friday, Saturday and Sunday again.
Then: each of their budget cards shows "1.850".
And: once today is closed, every coming day's budget card still matches its field in the week card (K39, KF 3 O4).
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

### K38 – With the carryover, tomorrow offers to close today
Source: KF 3 KORREKTUR (2026-11-18: "ich dachte wir behalten wochentag abschließen für leute die mit übertrag arbeiten?"); issue #922 ("Was er heute macht"); features.md; KF 3 Session (2026-11-18, O5: full weekday name).
Given: mode "Mit Übertrag"; today is Thursday, the 4th day of the run; today is not closed.
When: I open tomorrow (Friday) in the diary.
Then: the budget card shows the button "Donnerstag abschließen": today's weekday written out in full, not tomorrow's, and not short ("Do abschließen" is wrong).
And: today and the days of the run other than tomorrow show no such button.
And: in mode "Aus" or "Anzeigen" there is none (K9).

### K39 – Closing today makes it count as a finished day for every coming day
Source: KF 3 KORREKTUR; KF 3 O4 (2026-11-18, user: "Überall": week card and the budget cards of all coming days); issue #922 ("Morgen zählt dann wie ein schon begonnener Tag: Die Karte zeigt ‚kcal übrig‘ mit dem Ziel plus dem Übertrag von heute"); features.md; K11.
After a tap on "Donnerstag abschließen", today counts as a finished day
everywhere the carryover is worked out: the budget cards of tomorrow and of
every later day of the run, and those days' fields in the week card. Their
carryover is worked out by K11 with today's eaten kcal in the balance, also
when today is under its budget. Before the tap, they show the preview (K26,
K27).
Mode "Mit Übertrag", goal 2.200; run starts on a Monday; finished days Mo
2.200 · Tu 1.900 · We 3.000 (balance −500); today is Thursday (budget 2.075).
Friday, Saturday and Sunday get the same budget in every row (3 days
remain), so one column stands for all three.
| Eaten today (Thursday) | Fr, Sa, Su before closing | Fr, Sa, Su after closing |
| ---------------------- | ------------------------- | ------------------------ |
| 1.400                  | 2.075 (−125)              | 2.300 (+100)             |
| 1.475                  | 2.075 (−125)              | 2.275 (+75)              |
| 650                    | 2.075 (−125)              | 2.550 (+350)             |
| 500                    | 2.075 (−125)              | 2.550 (+350, limit)      |
| 2.075                  | 2.075 (−125)              | 2.075 (−125)             |
| 3.075                  | 1.850 (−350)              | 1.850 (−350)             |
Each of these budget cards shows the budget as "<n>" "kcal übrig" before anything is eaten on that day.
In the week card (K21), first row: before closing, the fields of Friday,
Saturday and Sunday each have a dark piece of 125 kcal at the front; after
closing, each has a dashed extra piece of 100 kcal at the end and no dark
piece. Thursday's own carryover stays −125 (it comes from Monday to
Wednesday only).
And: tomorrow then counts like a started day: plans on it show in the plan colour after the eaten share, as on today (features.md).

### K40 – The closed carryover stays live
Source: issue #922 ("Der Übertrag bleibt live: Isst man heute noch etwas oder ändert frühere Tage, ändert er sich"); features.md.
Given: the first row of K39 after closing (Thursday 1.400 eaten, Friday 2.300).
When: I log 75 kcal more on Thursday.
Then: Friday's budget card shows "2.275" (second row of K39).
When: I change Wednesday from 3.000 to 2.700.
Then: Friday's budget card shows "2.375" (balance +525, ÷ 3 = +175), and so do Saturday's and Sunday's (KF 3 O4).

### K41 – "Donnerstag abgeschlossen" reopens today, with undo
Source: issue #922 ("‚✓ Do abgeschlossen‘ öffnet den Tag wieder, und es gibt Rückgängig"); features.md ("a snack bar offers undo"); KF 3 O4 ("wieder öffnen nimmt es zurück"); KF 3 Session (O5: full weekday name).
Given: mode "Mit Übertrag"; first row of K39.
When: I tap "Donnerstag abschließen" on Friday.
Then: the button turns into "Donnerstag abgeschlossen" with a check mark, Friday shows "2.300", and a snack bar offers undo.
When: I tap undo in the snack bar.
Then: today is open again: the button reads "Donnerstag abschließen"; Friday, Saturday and Sunday show "2.075" again, and their fields in the week card have the 125 kcal dark piece again.
When: I close again and then tap "Donnerstag abgeschlossen".
Then: today is open again in the same way.

### K42 – The close holds until midnight, on this phone only
Source: issue #922 ("Der Abschluss wird nur auf dem Gerät gespeichert und gilt nur bis Mitternacht"); features.md.
Given: I closed Thursday on Thursday.
When: I close and open the app again on Thursday.
Then: Thursday is still closed (K41 label on Friday, Friday with today's carryover).
When: midnight passes and Friday is today.
Then: Friday's budget comes from K11 with Thursday as a finished day, and Saturday shows "Freitag abschließen", not closed.
Phone only: that a second phone with the same account does not see the close.

### K43 – No button when tomorrow starts a new run
Source: issue #922 ("Beginnt morgen ein neuer Run, gibt es keinen Übertrag und keinen Knopf"); features.md.
Given: mode "Mit Übertrag"; today is the 7th day of the run.
When: I open tomorrow in the diary.
Then: the budget card shows no "<Wochentag> abschließen" and tomorrow's budget is its plain goal (K11, first day of a new run).

### K44 – No button when tomorrow is a pause day
Source: KF 3 Session (2026-11-18, O6: "kein Knopf, wenn morgen ein Pausentag ist").
Given: mode "Mit Übertrag"; today is Thursday, the 4th day of the run; Friday is a pause day.
When: I open Friday in the diary.
Then: the budget card shows no "Donnerstag abschließen" and no "Donnerstag abgeschlossen".

### K45 – A mode switch keeps the close until midnight
Source: KF 3 Session (2026-11-18, O7: "ein Wechsel zu ‚Anzeigen‘ und zurück lässt den Tag bis Mitternacht abgeschlossen"); K9; K39.
Given: mode "Mit Übertrag"; first row of K39; I closed Thursday (Friday 2.300).
When: I switch to "Anzeigen" and open Friday.
Then: Friday shows the plain goal "2.200" and no button (K9).
When: I switch back to "Mit Übertrag" on the same Thursday and open Friday.
Then: the button reads "Donnerstag abgeschlossen", and Friday, Saturday and Sunday show "2.300".

### K46 – A closed today still looks like today in the week card
Source: notes, entry "2026-11-18, Frage O8" under KF 3 (user: "ja passt so"); K19; K23.
Given: mode "Mit Übertrag"; first row of K39; I closed Thursday; weight goal "Zunehmen"; "Details" open.
When: I look at the week card on Thursday.
Then: Thursday's field still looks like today: no number stands under it, and it is not red for being under its budget.
When: midnight passes and Friday is today.
Then: Thursday's field is a normal finished day: under it stands "−675" (1.400 against 2.075, K20), and it is red (K23).

**Group: week card (modes "Anzeigen" and "Mit Übertrag")**

### K14 – The week card is a strip of seven day fields
Source: FREIGABE ("schlanke Leiste aus sieben Tagesfeldern ohne Titel und ohne Wochensumme"); notes ("dann sieht man direkt in welchem 7 tage run tag man sich befindet"); KF 2 ("zwischen schritte und tagesbudget"); mock.
Given: mode "Anzeigen" or "Mit Übertrag".
When: I open today in the diary.
Then: between the budget card and the steps card stands a card with seven fields, one for each day of the current run, in their order.
And: a run cut short by a new goal has only its own days, so fewer fields (K47).
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
Source: KF list 6; notes, entry "2026-11-18, Review-Frage zu K28" (user: "neues ziel setzt einen neuen 7 tage run voraus.").
Given: today is Thursday, the 4th day of a run that started on a Monday.
When: I page the diary to Tuesday.
Then: the strip shows the same run, Tuesday's field has the frame, and the field names are "Mo", "Di", "Mi", "Heute", "Fr", "Sa", "So" ("Heute" stays at the real today).
When: I page to a day of the previous run.
Then: the strip shows the seven days of that previous run with the frame on the shown day, and no field is named "Heute".
Changed 2026-11-18: a run cut short by a new goal (K47).

### K47 – A new goal mid-run cuts the old run short in the strip
Source: notes, entry "2026-11-18, Review-Frage zu K28" (user: "neues ziel setzt einen neuen 7 tage run voraus."; a new goal starts a new 7-day run, the old run ends the day before); K11; K26; K28.
Given: mode "Mit Übertrag"; a run started on Monday with goal 2.200; Mo 2.200, Tu 1.900, We 3.000 eaten; on Thursday I set a new goal of 2.000 that counts from Thursday.
When: I open today (Thursday).
Then: the strip shows the new run from Thursday to next Wednesday: the fields are named "Heute", "Fr", "Sa", "So", "Mo", "Di", "Mi", and none of them holds a day of the old run.
And: the budget card shows "2.000" "kcal übrig", with no chip "… aus der Woche" (K11, last row).
And: Friday to next Wednesday carry no piece from the old run's balance of −500; with nothing eaten yet today, their fields have no dark piece and their budget cards show "2.000".
When: I page the diary to Tuesday.
Then: the strip shows the old run with the frame on Tuesday; no field is named "Heute", and no field shows Thursday or a later day with a piece from the old run's balance.
And: the strip of the old run shows only that run's days: three fields "Mo", "Di", "Mi", and no field for Thursday or later (notes, entry "2026-11-18, Frage O9", user: "Nur seine Tage"). A run cut short by a new goal is the one case with fewer than seven fields (K14, K49).
How the three fields fill the card (width, position) is decided by no source; it is left to the phone test.
Phone only: the layout of a strip with fewer than seven fields.
And: in mode "Anzeigen" the same holds for the fields and the day names; there are no pieces in any mode but "Mit Übertrag" (K21).

### K48 – Cutting a run short does not change its past budgets
Source: notes, entry "2026-11-18, O10, von der Session entschieden, dem User gesagt" (decided by the session and told to the user, not the user's own words); notes, entry "2026-11-18, von der Session entschieden … Folgerungen …" (same kind of source; training days); K11; K20.
Given: the setup of K47; on Wednesday, before the new goal existed, Wednesday's budget was 2.260 (balance +300 ÷ 5 remaining days = +60).
When: I set the new goal from Thursday and page the diary to Wednesday, "Details" open.
Then: Wednesday's budget card still counts against 2.260, not against a budget worked out with the shorter run (+300 ÷ 1 day, which would give 2.500).
And: under Wednesday's field stands "+740" (3.000 against 2.260, K20).
And: Tuesday keeps its budget of 2.200 (balance 0 on that day).
The day's goal stays too when the new goal has other training days (notes,
entry "2026-11-18, von der Session entschieden (dem User gesagt, keine
Aussage des Users), Folgerungen …": "Die Ziele der Tage eines gekürzten Runs
ändern sich nicht durch die Trainingstage des neuen Ziels"):
Given: mode "Anzeigen"; the old goal from Monday averages 2.200 with 350 kcal per training session and the training days Monday and Wednesday, so Monday and Wednesday have the goal 2.450 and Tuesday 2.100; on Thursday I set a new goal from Thursday with the same average and session and the training days Thursday, Friday and Saturday.
When: I page the diary to Monday, Tuesday and Wednesday.
Then: their budget cards show the goals 2.450, 2.100 and 2.450, as before the new goal; the training days of the new goal do not count in the old run (they would give 2.300, 1.950 and 2.300).

### K49 – A goal that counts from a later day: practice days belong to no run
Source: notes, entry "2026-11-18, von der Session entschieden (dem User gesagt, keine Aussage des Users), Folgerungen aus ‚neues ziel setzt einen neuen 7 tage run voraus‘, ‚Nur seine Tage‘ und K37" ("Der alte Run endet am Tag, bevor das neue Ziel gesetzt gilt, auch wenn das neue Ziel erst später zu zählen beginnt; Übungstage dazwischen gehören zu keinem Run und stehen in keiner Leiste"); K11; K37; K47.
Given: mode "Mit Übertrag"; a run started on Monday with goal 2.200; Mo 2.200, Tu 1.900, We 3.000 eaten; on Thursday I set a new goal of 2.000 that takes effect on Thursday and counts from Saturday ("Zielstart" Saturday).
Then: the old run ends on Wednesday, the day before the new goal takes effect.
When: I page the diary to Tuesday.
Then: the strip shows only "Mo", "Di", "Mi" (K47), with no field for Thursday or later.
When: I open Thursday (today), then Friday.
Then: neither shows a week card (K37): the steps card follows the budget card directly.
And: each budget card counts against the plain new goal "2.000", with no carryover and no chip "… aus der Woche"; the old run's balance of −500 does not reach them.
When: I open Saturday.
Then: the strip shows the new run from Saturday to the next Friday, named "Sa", "So", "Mo", "Di", "Mi", "Do", "Fr"; Thursday and Friday appear in no strip.
And: Saturday's carryover is 0 and its budget card shows "2.000" (K11, first day of a new run).
And: in mode "Anzeigen" the strips and the missing week card are the same.

### K50 – A close does not count while tomorrow is a pause day
Source: notes, entry "2026-11-18, von der Session entschieden (dem User gesagt, keine Aussage des Users), Folgerungen …" ("Ein Abschluss zählt nicht, solange morgen ein Pausentag ist"); K39; K44.
Given: mode "Mit Übertrag"; first row of K39; I closed Thursday (Friday, Saturday and Sunday 2.300).
When: on Thursday I make Friday a pause day.
Then: Friday shows no "Donnerstag abgeschlossen" and no "Donnerstag abschließen" (K44).
And: Saturday and Sunday show, in their budget cards and their fields in the week card, the same as if Thursday had never been closed.
When: on the same Thursday I make Friday a normal day again.
Then: the close counts again: Friday shows "Donnerstag abgeschlossen", and Friday, Saturday and Sunday show "2.300".

### K51 – "Tagesarten im Run" shows only the days of its run
Source: notes, entry "2026-11-18, von der Session entschieden (dem User gesagt, keine Aussage des Users), Folgerungen …" ("Die Tagesarten-Leiste in den Details zeigt nur die Tage des Runs"); K47; K48. Applies only while the strip "Tagesarten im Run" exists (O3).
Given: the setup of the training example in K48 (old run cut short to Monday–Wednesday, training days Monday and Wednesday; the new goal trains Thursday, Friday and Saturday).
When: I page the diary to Tuesday and open "Details" on the budget card.
Then: the strip "Tagesarten im Run" shows only Monday, Tuesday and Wednesday; no day from Thursday on is in it, so none can be switched there.
And: its count of training days counts only those days: 2, not 5.

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
And: today and every coming day of the run show their piece at once, not only tomorrow; coming days use the preview of K26, or K39 once today is closed (KF 3 O4).
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

## Ruhiger Tagebuch-Kopf (#1002)

Not covered here: the "Budgetkarte" and "Bewegung" parts of issue #1002; the
budget card waits for #930 (user decision 2026-11-19).

Criteria for the diary page header and the meal header (issue #1002). The
Menü button, the bottom bar and the Einkauf count are in
`lib/features/home/CRITERIA.md`.

Mocks: `Idee-Mitte.dc.html` (Idee B, page header only), `Farben.dc.html`
(Stufe 1, meal header only). Where a mock and issue #1002 disagree, the issue
wins.

### Seitenkopf

#### R1 – The date reads calmly, without capitals
Source: issue #1002; mock Idee-Mitte.dc.html; user decision 2026-11-19 ("Do, 19. Nov." wie im Mock); user decision 2026-11-20 (the small line always has text, so the header does not jump between days).
Today is Thursday, 19 November.
| Day shown            | Small line   | Date line    |
| -------------------- | ------------ | ------------ |
| Wednesday 11 Nov     | vor 8 Tagen  | Mi, 11. Nov. |
| Tuesday 17 Nov       | vor 2 Tagen  | Di, 17. Nov. |
| Wednesday 18 Nov     | Gestern      | Mi, 18. Nov. |
| Thursday 19 Nov      | Heute        | Do, 19. Nov. |
| Friday 20 Nov        | Morgen       | Fr, 20. Nov. |
| Saturday 21 Nov      | Übermorgen   | Sa, 21. Nov. |
| Sunday 22 Nov        | in 3 Tagen   | So, 22. Nov. |
The small line is never empty. Not: "Vorgestern", "HEUTE", "DONNERSTAG", "Do., 19. Nov." or a date without the weekday.

#### R2 – The arrows go to the previous and the next day
Source: issue #1002 ("Die Pfeile ... bleiben wie heute"); mock Idee-Mitte.dc.html.
Given: the diary shows Thursday, 19 November (today).
When: I tap the left arrow.
Then: the header reads "Gestern" and "Mi, 18. Nov.".
When: from today I tap the right arrow.
Then: the header reads "Morgen" and "Fr, 20. Nov.".

#### R3 – "Menü" stays under the menu icon in the diary
Source: issue #1002; user decision 2026-11-19 ("weil sonst nicht klar ist, was das soll").
Given: I open the diary.
When: I look at the top left.
Then: the menu icon shows with "Menü" under it, as in every tab (home K6). Mock Idee-Mitte.dc.html shows the icon alone; that does not apply.

#### R4 – On another day the Heute button replaces Einkauf
Source: user decision 2026-11-20; issue #1002; user decision 2026-11-19 (empty list).
"Empty" means no item that is not ticked off (home K8).
| Day shown        | Shopping list has open items      | Shopping list is empty        |
| ---------------- | --------------------------------- | ----------------------------- |
| today            | Einkauf top right, no Heute button | neither Einkauf nor Heute button |
| yesterday        | Heute button top right, no Einkauf | Heute button top right        |
| tomorrow         | Heute button top right, no Einkauf | Heute button top right        |
| 8 days ago       | Heute button top right, no Einkauf | Heute button top right        |

### Mahlzeiten

#### R5 – The meal header keeps today's layout
Source: issue #1002; mock Farben.dc.html (Stufe 1); user decision 2026-11-19 ("das hier").
Given: a meal time has entries, e.g. "Mittagessen" with 786 kcal eaten and a target of 730 kcal.
When: I look at its header.
Then: the name stands on the left, then "786 / 730 kcal", and the copy button stands rightmost.

#### R6 – Only the eaten number turns orange when the meal is over
Source: issue #1002 ("Orange statt Pink", "Liegt die Mahlzeit drüber"); mock Farben.dc.html (Stufe 1); user decision 2026-11-19.
Orange means the orange warning colour; its exact tone is left to the phone check. The rule holds on every day type, a Pause day included.
| Eaten / target | Eaten number                 | "/ target kcal" |
| -------------- | ---------------------------- | --------------- |
| 786 / 730      | orange                       | not orange      |
| 1.068 / 630    | orange                       | not orange      |
| 730 / 730      | not orange                   | not orange      |
| 500 / 730      | not orange                   | not orange      |
| 0 / 730        | not orange                   | not orange      |
| 786, no target shown | not orange             | —               |
Nothing in the meal header is pink.
Phone only: the exact orange tone.

#### R7 – Entries keep their macros and amount
Source: issue #1002; user decision 2026-11-19.
Given: an entry with protein, carbs and fat and an amount, e.g. "400 g" or "1/3 Portionen".
When: it stands under its meal.
Then: it still shows its macro line and the amount on the right, as today.

#### R8 – Macro numbers under an entry are always in the macro colours
Source: user decision 2026-11-20 ("farbig. 'makros immer bunt' hat keine auswirkung darauf"); mock Farben.dc.html; issue #1002.
Given: the setting "Makros immer bunt" is on, and an entry under a meal has protein, carbs and fat.
When: I look at the macro line under the entry.
Then: the protein number is in the protein colour (red), the carbs number in the carbs colour (blue) and the fat number in the fat colour (yellow). Only the numbers are coloured: no pills, no backgrounds.

Given: the setting "Makros immer bunt" is off, and the same entry.
When: I look at the macro line under the entry.
Then: the line looks exactly the same: all three numbers in their macro colours. The setting has no effect on this line.

#### R9 – Empty meal times stay hidden
Source: issue #1002; user decision 2026-11-19.
Given: a day with entries only at "Mittagessen" and "Abendessen".
When: I look at the diary for that day.
Then: no header shows for the meal times without entries, e.g. no "Frühstück".

### Schritte

#### R10 – The step card keeps its blinking
Source: issue #1002; user decision 2026-11-19.
Given: I open the diary.
When: the step card and the other widgets show.
Then: they blink as they do today.
Phone only: blinking is judged by eye.

## Gewicht-Kachel: Wiegen-Dialog (#864)

Bug criteria for the dialog that the diary's weight tile opens to enter a
weight.

#### W1 – The prefilled weight is written in the app's language
Source: phone test finding for issue #864, given by the orchestrator for the
user, user decision 2026-11-21; issue #864 phone test list ("erneut öffnen →
90,0 vorbelegt", "78,5 → gespeichert").
The field is prefilled with the weight the dialog offers, with one decimal
place, in the number format of the app's language.
| App language | Prefilled weight | Field shows | Saved unchanged as |
| ------------ | ---------------- | ----------- | ------------------ |
| German       | 74.9 kg          | 74,9        | 74.9 kg            |
| German       | 90 kg            | 90,0        | 90 kg              |
| English      | 74.9 kg          | 74.9        | 74.9 kg            |

Typing either separator keeps working:
| App language | I type | Saved as |
| ------------ | ------ | -------- |
| German       | 78,5   | 78.5 kg  |
| German       | 78.5   | 78.5 kg  |

Not: "74.9" with a dot in German.

## Tagebuch-Kacheln: Start-Anordnung (release 3.11.1)

Bug criteria for which tiles the diary dashboard shows before the user ever
changed its layout.

#### T1 – The default layout shows only the budget card
Source: user decision "die widgets sollen ausgeblendet bleiben" (before
2026-11-22); user decision 2026-11-22 "Jetzt schon" (for release 3.11.1);
orchestrator decision 2026-11-22 "keine Migration, wer sein Layout schon
geändert hat, behält seine Wahl".

| Layout                                         | Budget card | Weight tile | "Mahlzeiten-Aufteilung" | Other tiles |
| ---------------------------------------------- | ----------- | ----------- | ----------------------- | ----------- |
| Never changed by the user (no saved layout)    | shown       | hidden      | hidden                  | hidden      |
| Saved by the user, with weight and meals tiles | as saved    | shown       | shown                   | as saved    |
| Saved by the user, without them                | as saved    | hidden      | hidden                  | as saved    |

Given: I never changed the diary's tile layout.
When: I edit the tiles ("Kacheln anordnen") and add the weight tile or the
"Mahlzeiten-Aufteilung" tile.
Then: the added tile shows on the dashboard, as any other hidden tile can.

Not: the update changes a saved layout (no migration).

## Meldung bei freien kcal (#971, redesign for release 3.11.1)

Criteria for the notification that tells the user how many kcal are free
again (switch "Meldung bei freien kcal" in the "Tagesbudget" menu, channel
"Freie kcal"). They replace the trigger of issue #937 (the notice came once
the pace marker freed a meal's whole share); that trigger is gone and is not
kept next to these.

Source of every criterion below: **Decisions** = the user's decisions in
`pace-notice-971-decisions.md` (side-session notes, from the user on
2026-11-24, in the chat). Each criterion names the point. Point 7 is partly
the session's own setting ("Abend bis 20" and the shift of the pace marker);
the user did not object. "Unverändert" and "Bewusst so" are the two closing
paragraphs of that file. **Nachtrag 10** is point 10 of its section "Nachtrag
24.11.", a decision of the user of 2026-11-24. **Nachtrag session** are the
entries under "Selbst entschieden" in that section: decided by the session on
2026-11-24 as small things, not the user's own words.

Words used below:

- **Part of the day**: Frühstück, Mittagessen, Abendessen, each from its
  start to its end in the meal times. The snack is a part of the day for the
  pace marker, but never for this notice.
- **Due by the end of a part**: the day's budget (K33) times the shares of
  all meals up to and including that part.
- **Eaten**: everything eaten today, all meals together.

Example values unless a criterion says otherwise: budget 2.000 kcal, no pause
day, shares Frühstück 25 %, Mittagessen 35 %, Abendessen 30 %, Snack 10 %,
standard meal times (P8).

#### P1 – One notice at the start of each part of the day, never for the snack
Source: Decisions 1, 6, 7; Unverändert ("höchstens eine Meldung je Tageszeit").
| Part of the day | Notice comes at               | Standard time |
| --------------- | ----------------------------- | ------------- |
| Frühstück       | the day start ("Tagesbeginn") | 6:00          |
| Mittagessen     | the end of Frühstück          | 11:00         |
| Abendessen      | the end of Mittagessen        | 16:00         |
| Snack           | no notice                     | —             |
With own meal times the notices follow them, e.g. Frühstück by 10:00 moves
the Mittagessen notice to 10:00.
At most one notice per part of the day per day.
Not: a notice at the end of Abendessen (20:00), when the snack part starts, or
at any other time of the day.

#### P2 – The value is what is due by the end of the part minus what is eaten
Source: Decisions 2, 3, 6; Nachtrag session (rounding).
Due by the end: Frühstück 500, Mittagessen 1.200, Abendessen 1.800. The
snack's 200 are never counted.
| Notice      | Eaten today | Value | Notice comes                               |
| ----------- | ----------- | ----- | ------------------------------------------ |
| Frühstück   | 0           | 500   | yes, "500 kcal"                            |
| Mittagessen | 400         | 800   | yes, "800 kcal"                            |
| Mittagessen | 0           | 1.200 | yes, "1.200 kcal" (open kcal from earlier add up) |
| Mittagessen | 700         | 500   | yes, "500 kcal" (eating too much lowers it) |
| Mittagessen | 1.199       | 1     | yes, "1 kcal"                              |
| Abendessen  | 1.000       | 800   | yes, "800 kcal"                            |
| Abendessen  | 1.800       | 0     | no                                         |
| Abendessen  | 2.100       | −300  | no                                         |
With mode "Mit Übertrag" the value is worked out from the budget with the
carryover (K33), e.g. budget 2.100 and nothing eaten: Frühstück "525 kcal".
A value with a fraction is rounded half up:
| Budget | Notice      | Eaten today | Exact value | Shown      |
| ------ | ----------- | ----------- | ----------- | ---------- |
| 2.150  | Frühstück   | 0           | 537,5       | "538 kcal" |
| 2.150  | Frühstück   | 0,4         | 537,1       | "537 kcal" |
| 2.150  | Frühstück   | 537,2       | 0,3         | no notice  |
The rounded value decides: a value that rounds to 0 or less brings no notice
(Nachtrag session, "Ergibt gerundet 0 kcal (z. B. 0,3), kommt keine Meldung").

#### P3 – The title names neither a meal nor a breakdown
Source: Decisions 4, 6.
Given: the Mittagessen notice comes with a value of 800.
Then: its title reads "Hey, du hast wieder 800 kcal frei".
Not: "Fürs Mittagessen", "Für den Snack", any other meal name, "davon … für
Snacks", or a list of meals.
Source for English: Nachtrag session.
In English the title reads "Hey, you have 800 kcal free again".

#### P4 – The macro tip stays, but not while nothing is eaten today
Source: Decision 5.
| Eaten today               | Macro with the most left | Text under the title             |
| ------------------------- | ------------------------ | -------------------------------- |
| 0 kcal                    | (all equal)              | none                             |
| 400 kcal, little protein  | Eiweiß                   | "Versuch, mehr Eiweiß zu essen." |
| 1.000 kcal, little fat    | Fett                     | "Versuch, mehr Fett zu essen."   |
Not: "Eiweiß" in the Frühstück notice of a morning with nothing eaten.

#### P5 – Tomorrow's day-start notice is planned today
Source: Decision 9; Unverändert ("geplant wird nur heute (dazu die Morgen-Meldung von morgen)").
Given: the switch is on, and today the app plans the notices (I open it or
change the diary), e.g. at 21:30.
Then: tomorrow's Frühstück notice is planned for tomorrow's day start (6:00),
even if I do not open the app tomorrow before then.
And: its value is tomorrow's budget times the Frühstück share, with
tomorrow's real budget (training day, pause day, carryover of #911).
And: it has no macro tip.
| Tomorrow                     | Tomorrow's budget | Notice at 6:00 tomorrow             |
| ---------------------------- | ----------------- | ----------------------------------- |
| normal day                   | 2.000             | "Hey, du hast wieder 500 kcal frei" |
| training day                 | 2.400             | "Hey, du hast wieder 600 kcal frei" |
| "Mit Übertrag"               | 2.100             | "Hey, du hast wieder 525 kcal frei" |
| pause day                    | —                 | none                                |
Planning tomorrow's notice never cancels or changes today's pending notices,
and planning today's never cancels or changes tomorrow's.
A later planning today plans tomorrow's notice again with the newest budget,
e.g. after closing today (K39) changes tomorrow's carryover.
When tomorrow comes, only one Frühstück notice comes that day (P1), also when
I open the app before 6:00.
Phone only: the notice coming at 6:00 on the next day without opening the app.

#### P6 – A notice due before the app opens that day does not come late
Source: Bewusst so.
Given: it is 12:30, and I open the app for the first time today.
Then: no Mittagessen notice comes, not now and not later today.
And: the Abendessen notice is planned for 16:00 as usual.

#### P7 – A diary change re-plans the pending notice
Source: Bewusst so; Unverändert ("eine gezeigte Meldung wird nie zurückgezogen").
Given: it is 13:00; the Abendessen notice is pending for 16:00 with a value of
800 (1.000 eaten).
| I change the diary to | Pending notice at 16:00               |
| --------------------- | ------------------------------------- |
| 1.300 eaten           | "Hey, du hast wieder 500 kcal frei"   |
| 800 eaten (delete)    | "Hey, du hast wieder 1.000 kcal frei" |
| 1.800 eaten           | cancelled, nothing comes at 16:00     |
| 2.000 eaten           | cancelled, nothing comes at 16:00     |
| 2.000 eaten, then at 14:00 an entry of 1.000 deleted | planned again: "Hey, du hast wieder 800 kcal frei" |
Source for the last row: Nachtrag session (a cancelled notice is planned again
when kcal are free again before its time).
Given: it is 11:30 and the Mittagessen notice came at 11:00.
When: I add or delete an entry.
Then: the notice already shown stays in the notification list; it is not
withdrawn or changed, and no second Mittagessen notice comes.

#### P8 – New standard meal times, also for the pace marker
Source: Decision 7.
The standard meal times are: Tagesbeginn 6:00, Frühstück bis 11:00,
Mittagessen bis 16:00, Abendessen bis 20:00, Snack bis 21:00.
The pace marker uses them too (its values: P14).
Not: Frühstück bis 9:00, Mittagessen bis 13:00, Abendessen bis 19:00.

#### P9 – Own meal times are kept; "Zurücksetzen" brings the new standard
Source: Decision 7.
| Meal times before the update   | After the update        |
| ------------------------------ | ----------------------- |
| never changed by me            | 6 / 11 / 16 / 20 / 21   |
| own: 7 / 10 / 14 / 19 / 22     | 7 / 10 / 14 / 19 / 22   |
Given: I have own meal times.
When: I tap "Zurücksetzen" in the meal times editor.
Then: the times are 6 / 11 / 16 / 20 / 21.

#### P10 – Pause days stay quiet
Source: Unverändert ("Pausentage still"); Decision 9.
Given: today is a pause day.
Then: no notice comes today, whatever is eaten.
Given: tomorrow is a pause day.
Then: no Frühstück notice is planned for tomorrow (P5).

#### P11 – Turning the switch or the pace marker off cancels every pending notice
Source: Unverändert (the switch and "eine gezeigte Meldung wird nie zurückgezogen"); Decision 9; Nachtrag session ("nur, solange der Soll-Strich an ist", the switch stays where it is).
Given: it is 12:00; the Abendessen notice is pending for 16:00 and tomorrow's
Frühstück notice for 6:00.
When: I turn "Meldung bei freien kcal" off.
Then: neither comes. A notice already shown stays.
Given: the same pending notices.
When: I turn "Soll-Strich" off and leave "Meldung bei freien kcal" on.
Then: neither comes, and no notice is planned while the pace marker is off.
When: I turn "Soll-Strich" on again at 13:00.
Then: the Abendessen notice is planned for 16:00 again, and tomorrow's
Frühstück notice for 6:00.

#### P12 – The switch hint describes the new trigger
Source: Decisions 1, 4; closing paragraph ("diaryBudgetMenuPaceNoticeHint (DE+EN) braucht einen neuen Text"); Nachtrag session (wording).
Given: I open the "Tagesbudget" menu.
Then: the hint under "Meldung bei freien kcal" reads "Zu Beginn jeder
Tageszeit, wenn du kcal frei hast"; in English "At the start of each part of
the day, when you have kcal free".
Not: "Einmal pro Tageszeit, wenn der Soll-Strich ihre kcal wieder frei gibt",
and in English not "Once per part of the day, when the pace marker frees its
kcal again".

#### P13 – The debug button shows the new title
Source: closing paragraph ("der Debug-Knopf den neuen Titel"); Unverändert ("Debug-Knopf").
Given: the debug build, the switch on.
When: I tap "Test-Meldung in 5 s (Debug)".
Then: about 5 seconds later a notice comes whose title reads "Hey, du hast
wieder <number> kcal frei", with no meal name.
Phone only: the debug build and the real notification.

#### P14 – The pace marker jumps at the start of each part of the day
Source: Nachtrag 10 (user decision 2026-11-24: "man hat halt budget frei um zu frühstücken, das ergibt doch sinn").
Before the day start the marker stands at 0. At the start of each part of the
day it jumps at once to what is due by the end of that part (P2), and stays
there until the next part starts. It never rises evenly in between.
With the example values (budget 2.000, standard meal times):
| Time  | Marker at       |
| ----- | --------------- |
| 0:00  | 0               |
| 5:59  | 0               |
| 6:00  | 500 (25 %)      |
| 8:30  | 500             |
| 10:59 | 500             |
| 11:00 | 1.200 (60 %)    |
| 13:30 | 1.200           |
| 16:00 | 1.800 (90 %)    |
| 19:59 | 1.800           |
| 20:00 | 2.000 (100 %)   |
| 23:59 | 2.000           |
The jump at 20:00 is the snack part; it brings no notice (P1).
With own meal times the jumps follow them, e.g. day start 7:00: 0 at 6:30,
500 at 7:00.
So the marker and the notice show the same: at 11:00 with 400 eaten, the
marker stands 800 ahead of the kcal eaten, and the notice says "800 kcal".
Not: 250 at 8:30 (the old even rise).
