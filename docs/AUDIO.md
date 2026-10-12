# Audio implementation and verification

Implemented on 2026-10-09 for Godot 4.7.2. The existing `SoundEffects` autoload now directs licensed audio, music, UI feedback, and gameplay effects. No second manager, runtime dependencies, artwork changes, or gameplay balance changes were added.

## Assets and licensing

35 actual downloaded audio assets are installed under `assets/audio/{music,ui,weapons,spaceship,enemies,gameplay,ambient}`. All selected sources identify their assets as **CC0**, allowing commercial distribution without required attribution. Courtesy credits: **Kenney, yd, KiluaBoy, wipics, and MintoDog**.

[The asset manifest](../assets/audio/manifest.json) lists every installed file, original filename, creator, source page, direct download URL, license URL, commercial-use/attribution status, processing, duration, usage, and original/output SHA-256 hashes. Original Kenney license notices are retained in `assets/audio/licenses`. The manifest and license notices are included in exports.

| Source | Installed content |
|---|---|
| [Kenney Interface Sounds](https://kenney.nl/assets/interface-sounds) | 13 interface and reward/mission cues |
| [Kenney Sci-fi Sounds](https://kenney.nl/assets/sci-fi-sounds) | 14 weapon, enemy, spaceship, and engine sounds |
| [Kenney Music Jingles](https://kenney.nl/assets/music-jingles) | 3 result fanfares |
| [Out There — yd](https://opengameart.org/content/space-music-out-there) | Main menu music |
| [IntoTheStars — KiluaBoy](https://opengameart.org/content/sci-fi-adventure-eastern-quiet-piano-loop) | Campaign music |
| [Outer Space Loop — wipics](https://opengameart.org/content/outer-space-loop) | Hangar music |
| [Space Battle — MintoDog](https://opengameart.org/content/space-battle) | Gameplay music |
| [Pressure — yd](https://opengameart.org/content/pressure) | Guardian encounter music |

The previous implementation generated four sounds in memory; there were no existing audio files to remove or overwrite. The procedural synthesizer was replaced with the downloaded assets while retaining its public `play_shoot`, `play_hit`, `play_pickup`, `play_explosion`, and `stop_all` entry points.

## Music assignments

| Screen/event | Audio |
|---|---|
| Main menu | `command_menu.ogg` / Out There |
| Planet campaign / level selection | `planet_exploration.ogg` / IntoTheStars |
| Hangar / weapon selection | `hangar_ambient.ogg` / Outer Space Loop; opening loadout keeps the same track and playback position |
| Gameplay | `space_combat.ogg` / Space Battle |
| Living guardian | `guardian_battle.ogg` / Pressure; returns to combat music if objectives remain |
| Three-star victory | `victory.ogg`, sequential ascending star cues, and a newly unlocked world cue when applicable |
| One-/two-star completion | `mission_complete.ogg` and the corresponding number of star cues |
| Defeat | `defeat.ogg` plus ship destruction |

All five background tracks loop. Music changes crossfade over 650 ms using two persistent players; old resources are released afterward. Identical music requests keep playback running. Result fanfares are one-shots and fade out the previous background track. Pending loads and delayed result cues are protected against scene changes/restarts.

## Event coverage

Buttons throughout the UI automatically receive consistent click/confirm/back/toggle feedback, including dynamically created controls and keyboard button activation. Aircraft/weapon selection, swipes, planet inspection, locked planets, pause/resume, settings/manual/loadout opening and closing, and volume/control-layout sliders have feedback. Short cooldowns suppress duplicate cues caused by one action invoking both a button and a selection/popup callback.

Gameplay hooks cover all four weapons (one cue per volley), enemy and guardian volleys, charger dashes, projectile impacts, enemy/guardian destruction, meteor impacts, accepted damage, critical health, ship destruction, crystal collection, deployment/restart, star results, new level unlock, and mission success/failure. A quiet engine loop changes pitch/gain with existing player movement and stops on results or menu navigation.

The game has no missiles, boost ability, active shield toggle, weapon charge/special attack, purchasable upgrades, achievements, countdown, checkpoints, or power-up mechanics. No speculative mechanics or sounds for those events were introduced. Existing shield cells represent health; their accepted damage event uses the force-field impact asset.

## Settings and performance

The existing Audio category now offers Master, Music, Sound Effects, UI Sounds, and Mute All Audio. It retains the flight-console theme and existing slider artwork, supports keyboard focus/arrow adjustment, and translates into English and Bahasa Indonesia.

Values apply immediately to separate Master/Music/UI/SFX buses. The existing save file stores normalized volumes in an `audio` section and retains `settings/audio` as the legacy mute flag. Old saves receive defaults; loaded values are checked for finite numeric values and clamped. Slider saves are debounced by 300 ms and also committed on drag completion, focus loss, dialog closing, and application backgrounding.

- Vorbis background music is loaded asynchronously on demand; it is decoded during playback, rather than expanded into whole-track PCM buffers. Existing Vorbis source quality is preserved where available.
- Short effects use peak-normalized 24 kHz mono PCM16, avoiding frequent compressed-effect decoder startup. The total installed WAV data is approximately 0.81 MiB.
- Eight reusable combat voices, three UI voices, two music players, one engine, one damage voice, and one result player bound simultaneous playback to 16 voices. Rapid repeated effects have cooldowns; low-priority effects are dropped when saturated. Player firing and critical/destruction cues can replace an older low-priority voice.
- The engine uses an 80 ms wrap crossfade. Long warning/dash source effects were edited to short gameplay cues with release fades.
- Gameplay voices pause with the simulation. Music ducks 8 dB in pause/settings while UI remains responsive. All players suspend in the background and restore on foregrounding. A Master limiter limits summed peaks.
- Deferred UI wiring uses instance IDs, so controls removed before their deferred hook cannot produce freed-object errors. Resources and pending requests are released on shutdown.

## Verification results

All nine existing suites passed with zero assertion failures: game smoke, hangar review, campaign combat, landscape UI, localization/controls, control input, three-star progression, performance safety, and the 20-minute accelerated simulation soak. The soak excludes real-time audio-driver scheduling; its result verifies simulation bounds, not Android sound latency. Three immediate-exit test runners now wait briefly for the audio mixer to release stopped playback; the fixed-fps soak gives the real mixer clock a shutdown interval.

The added `tests/audio_system.tscn` passed with both headless playback and the native CoreAudio driver. It checks all imported files and loop flags, a real decoded loop endpoint, same-track continuity, rapid music requests, outgoing-player cleanup, a nonzero mixed signal on the Master bus, actual weapon/enemy events, bounded player allocation, pause/background/resume, guardian music changes, all three result ratings, the unlock cue, immediate volume changes, slider bounds, and persistent saves. A separate fresh-process `--reload` run passed for all four saved volumes and the mute flag.

Rendered English and Indonesian settings were visually reviewed at 1280×720 with no clipping; existing localization/layout tests also passed at their supported landscape sizes. Captures are in `qa/audio_settings_en.png` and `qa/audio_settings_id.png`.

All 35 audio paths and output hashes match the manifest. Godot import and Android resource-pack export succeeded. The exported pack also passed a runtime menu/audio smoke test with clean mixer shutdown. `git diff --check` passed. No generated placeholder audio is used.

Commands:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . tests/audio_system.tscn
godot --headless --path . tests/audio_system.tscn -- --reload
godot --path . --windowed --resolution 1280x720 --rendering-method gl_compatibility tests/audio_system.tscn -- --screenshots
godot --headless --path . --export-pack Android qa/audio-android.pck
```

## Remaining validation limits

No Android device was connected (`adb devices -l` returned an empty list). Physical Android output latency, interruptions, thermal behavior, and low-end hardware stutter therefore remain unverified. The Android resource pack was exported; this phase did not produce or validate a signed APK. Production certification still requires that device QA and the project's normal signing/build setup.

Sandboxed macOS runs emitted host certificate-store/editor-settings access diagnostics; the native CoreAudio test outside that sandbox passed without project errors or shutdown leaks. These host diagnostics do not indicate missing game resources.

## Native crash correction (2026-10-09)

The engine-loop WAV now imports `edit/loop_end=-1`, resolving to the final valid frame (118079), rather than its frame count (118080). PCM loop resources are validated once before first playback. The supplied Android fault reads that exact one-past-end frame; full register/instruction correlation and verification limits are in [the audio crash report](ANDROID_AUDIO_CRASH.md). Debug-only audio isolation flags and automated gameplay are excluded from normal behavior; no audio feature was permanently disabled.
