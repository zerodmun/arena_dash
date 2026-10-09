# Performance optimization and three-star progression

Implemented and validated 2026-10-09 with Godot 4.7.2. This report supersedes earlier star criteria and completion-based unlock rules. Planet artwork, aircraft, weapons, difficulty rosters and landscape map assignments remain as documented in [Campaign](CAMPAIGN_REDESIGN.md).

## Mandatory campaign rule

Level 1 is available by default. Each subsequent level requires a saved **three-star rating on every preceding level**, including planet transitions. Completion alone never unlocks a level. One- and two-star attempts save the highest rating but remain incomplete clears. Selection APIs, startup and mission completion enforce the same rule as the UI. Random selection is limited to unlocked worlds.

A surviving mission completion earns one star. One additional star comes from meeting the aircraft damage budget, and one from meeting the planet time limit. Either bonus can earn the second star; both are required for three. Damage counts actual shield damage taken during the mission, even if pickups subsequently repair shields. The budget is half the aircraft’s starting shields, rounded down with a minimum of one. Thresholds are inclusive. Guardian defeat is required in addition to the drone objective on levels 4–8.

| Level | Planet / map | Time limit | Drone target | Guardian |
|---|---|---:|---:|---|
| 1 | Cyber Matrix / cyber | 120 s | 16 | No |
| 2 | Primal Jungle / forest | 140 s | 22 | No |
| 3 | Void Horizon / space | 160 s | 28 | No |
| 4 | Coastal Front / coast | 210 s | 34 | Yes |
| 5 | Dune Outpost / desert | 230 s | 40 | Yes |
| 6 | Magma Caldera / volcano | 250 s | 46 | Yes |
| 7 | Glacial Tundra / glacier | 270 s | 52 | Yes |
| 8 | Toxic Citadel / toxic | 290 s | 58 | Yes |

Criteria are visible in the campaign briefing and results. Results distinguish actual attempt stars from the saved best, display time/damage, explain the three-star requirement, and emphasize Retry after a partial clear. Next remains disabled for a partial attempt, including a weaker replay after an earlier three-star clear; the previously legitimate campaign unlock remains saved. The campaign shows best stars and locked, ready, retry and three-star-clear states. All messages support English and Indonesian (199 matching translation keys).

Save loading retains valid integer ratings 1–3, removes malformed/out-of-range/nonfinite entries and derives locks from the full preceding chain. A later orphan three-star rating cannot bypass a missing earlier clear. Locked saved selections reset to the first world. Best ratings never decrease on replay. Legacy latest-completion metadata is accepted only for a valid clear, otherwise inferred from the contiguous cleared prefix.

## Causes addressed

Repeated synchronous high-score writes could stall a frame despite healthy average FPS. Scores now accumulate in memory and flush at pause/settings, results, defeat, background/focus loss, hangar return and orderly exit. Completed attempts still save immediately. Tests verify 1,000 score increments cause no writes before one flush.

Bullet, hostile-shot and explosion creation generated allocation churn. A scene-owned pool prewarms 96 bullets, 64 hostile shots and 24 bursts, resets lifetime/weapon/transform/interpolation on activation, and disables inactive collision/processing/group membership. Recycling is deferred out of collision callbacks. Extra bursts may grow the pool to preserve effects; retained free instances are bounded. Muted sound no longer allocates playback objects.

Other changes cache weapon/meteor textures and enemy volley angles, update HUD strings only when values change, calculate chunk culling bounds once per frame, stop unnecessary enemy redraws, cache joystick lookup and replace overlapping recoil tweens. Live pickups are capped at 32 by pausing new pickup spawns, preventing unbounded accumulation during stationary flights.

Movement, mission timing, pickup motion and camera tracking use fixed physics with interpolation. The camera follows after actors with a single exponential smoothing stage. Fire/spawn timers retain fractional remainder, preventing cadence drift; idle/cap timer debt cannot create catch-up bursts. The project uses 60 physics ticks, eight maximum catch-up steps, agile input flushing and VSync. Aircraft speed, enemy caps, arena size, resolution and particle counts were preserved.

## Desktop measurements

Same Apple M1, 1280×720 native Compatibility renderer; light phase holds four enemies for six seconds, heavy phase holds 28 for thirteen seconds with continuous quantum fire and score updates. First second of each phase is excluded. Each cell is before → after, in milliseconds unless stated otherwise.

| Phase | Average | p95 | p99 | Worst | Frames over 25 ms |
|---|---:|---:|---:|---:|---:|
| Light | 8.56 → 8.37 | 12.45 → 9.99 | 15.75 → 10.28 | 28.07 → 19.47 | 2 → 0 |
| Heavy | 7.76 → 8.36 | 11.81 → 9.80 | 13.48 → 10.70 | 83.51 → 22.18 | 3 → 0 |

Evidence: `build/performance-baseline.json` and `build/performance-after.json`. These short single-run measurements show improved frame consistency, not an increase in heavy-scene average throughput. Pool prewarming increases retained memory (heavy sample approximately 53.46 → 55.35 MB). Enemy counts match; corrected timing means projectile traces are not identical. Desktop results cannot establish Android performance.

Opt-in diagnostics require a debug build and `--perf`. They report wall-clock frame average/p95/p99/worst/spikes, physics/process time, viewport CPU/GPU render time, event-receipt-to-physics latency, actor counts, memory and draw calls through five-second `PERF` JSON samples. Fixed buffers hold at most 7,200 samples; ordinary/release runs allocate no diagnostic buffers or enable measurement. Diagnostics include startup, unlike the benchmark. Compatibility returned zero GPU timing, which is unavailable timing rather than measured zero cost. A routed-input test recorded one 13.694 ms software input-to-physics sample; it is not hardware input-to-display latency.

## Validation and remaining work

All nine automated suites passed: six existing regression suites plus strict progression, performance safety and soak. Every world/aircraft rating boundary, partial clear, best-rating replay, migration, direct-selection guard and EN/ID result state is covered. Rendered progression checks passed at 1280×720, with captures under `build/progression_*.png`. Movement and firing were checked at 30/60/120 Hz; 7,200 repeated pooled shots did not create additional bullets after warmup.

The headless soak ran **20 accelerated simulated minutes**, with audio muted to exclude wall-clock audio-driver scheduling. Enemies stayed at or below 28, hostile shots at or below 64, and pickups at or below 32. Middle/end node counts were both 1,015; tracked static memory changed from 60,734,302 to 60,744,518 bytes (about 10 KB). It exited without ObjectDB leak warnings. This is bounded-growth evidence, not a real-time thermal or process-RSS measurement.

The exported browser campaign was inspected in Indonesian: Level 2 showed the three-star prerequisite and a disabled deployment button, with no warning/error console messages (`build/web-three-star-campaign.jpg`). Web and Android release exports passed; APK v2/v3 signatures verified with the existing local test identity. All 215 source asset files matched the pre-change SHA-256 inventory. Existing portrait assets continue to use proportional landmarks/backgrounds with landscape terrain extension; no asset was created, duplicated or overwritten. `performance-progression-backup.zip` preserves the pre-change source/configuration and is excluded from exports.

Physical Android GPU/frame pacing, sustained thermals, real multitouch and input-to-display latency require device validation. Human playtesting of all aircraft/planet time and damage thresholds also remains outstanding; automated boundaries establish consistent achievable rules rather than proving every player can meet them. See [Testing](TESTING.md) and [Deployment](DEPLOYMENT.md) for reproduction commands.
