# Burn Week Now

Only near-term work. No long-term idea dump here.

## 1. Lock Rules First

- Define one canonical formula:
  `week target = 7 x base kcal`
- Define `base kcal` source order:
  learned TDEE first, calculator fallback second
- Define exact star tiers and safe-zone widths:
  - `0-5 stars = +/- 1.0 x base kcal`
  - `6-15 stars = +/- 0.8 x base kcal`
  - `16+ stars = +/- 0.5 x base kcal`
- Define exact heart rule:
  auto-buyback into safe zone or explicit confirm dialog
- Define exact shard rule:
  `7 shards = 1 heart`
- Define what counts as:
  - tracked day
  - full meal tracking
  - inactivity

## 2. Real Burn Run State

- Add `shardCount` to real Burn run state
- Add `runStatus`
  - `active`
  - `failed`
  - `sandbox`
  - `waitingForStart`
- Add `runStartMode`
  - `startTomorrow`
  - `startNow`
- Keep explicit week anchor in persistent state
- Prepare migration for existing Burn state

## 3. Live Burn Engine

- Make bar true `0 -> 7 x base kcal`
- Keep ideal marker continuous over whole 7-day run
- Use real current-week-only baseline after reset/restart
- Make safe zone depend on star tier
- Finish live week loop:
  - in zone
  - below zone
  - above zone
  - rescued by heart
  - failed with no heart
- Finish week close logic:
  - perfect week -> `+1 star`
  - shard rewards
  - next week starts cleanly

## 4. Calories Split For Bar

- Split Burn kcal into:
  - logged now
  - planned later
  - heart credit
- Shadow kcal must be visible immediately
- Shadow kcal must count only after planned time is reached

## 5. Rolling TDEE

- Add rolling TDEE source from last `7-14` days
- Smooth updates so base kcal does not jump hard
- Keep fallback to calculator until enough data exists

## 6. Hearts And Shards

- Heart value:
  `1 heart = 1 x base kcal`
- Daily shard earn:
  - `+1` full tracking
  - `+1` step goal
  - `+1` tracked sport
- Add daily shard cap
- Add automatic shard-to-heart conversion or explicit claim rule

## 7. Reset And Failure

- Add casual reset button
- Reset deletes current unfinished run only
- No star loss on manual reset
- Add real fail state when user leaves safe zone and has no heart
- Add inactivity penalty:
  lose `1 star` only after full `7` inactive days

## 8. Onboarding

- Mid-day start choice:
  - `Tomorrow` sandbox
  - `Start now`
- For `Start now`, add quick catch-up:
  - `Little`
  - `Normal`
  - `Much`
- Place user safely into current zone based on choice

## 9. UI Needed Soon

- Burn card shows:
  - week bar
  - ideal marker
  - safe zone
  - shadow bar
  - stars
  - hearts
  - shards
- Add reset action with warning
- Add compact explanation dialog for:
  - base kcal
  - activity kcal
  - target mode
  - safe-zone width
  - heart value

## Build Order

1. Lock formulas and rules
2. Finish live 7-day bar and safe-zone tiers
3. Add shards to real state and week resolution
4. Add shadow/pre-logging support
5. Add rolling TDEE
6. Add reset, onboarding, inactivity penalty
