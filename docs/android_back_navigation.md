# Android Back navigation verification — 16 October 2026

Implemented in the existing Godot 4.7.2 project. The production release was built with `./build_apk.sh release` and installed twice with `adb install -r`, without uninstalling or clearing app data.

## Cause and implementation

The project left Godot's default `application/config/quit_on_go_back` enabled. Android Back therefore quit the app before the scattered keyboard Escape handlers could provide in-app navigation. The default is documented in [Godot's quit-request guidance](https://docs.godotengine.org/en/latest/tutorials/inputs/handling_quit_requests.html).

`Navigation` is now an always-processing autoload. Both the project setting and runtime `SceneTree.quit_on_go_back` disable automatic exit. The autoload dispatches Android `NOTIFICATION_WM_GO_BACK_REQUEST`, `ui_cancel`, Escape, and Back keys. Local Escape handlers were removed so a single event cannot close an overlay and navigate its parent. A 250 ms guard coalesces duplicate notifications and rapid repeats; a scene-change guard stays active until `scene_changed`.

History stores resource paths, never scene instances. Returning to an existing path truncates history, Home clears it, repeated destinations are ignored, and gameplay is excluded as a return destination. External direct scene replacements are observed too. Navigation continues using the existing scene-change mechanism; the loading screen retains its crossfade. Map's return label now reflects Home or Hangar.

Back traverses the UI from the topmost nested child before changing scenes. Gameplay Back uses the existing pause/resume implementation, including releasing fire and resetting the joystick. Result Back stops the automatic return timer, flushes the existing save, and returns to the launch screen. Reward/progression calculations and signing configuration were not changed.

Home alone shows the existing sci-fi panel artwork with “Swipe back again to exit” / “Geser kembali sekali lagi untuk keluar”. The second delivered Back within 2000 ms flushes saves and quits normally. Timeout, scene changes, modal Back, and application focus/pause reset the confirmation.

The packaged Godot Android activity uses AndroidX `OnBackPressedDispatcher` and forwards to Godot's Back handler (verified with `apkanalyzer dex code`). Target SDK remains 36, minimum SDK 24. No custom native callback or predictive animation was added; the template's Android compatibility path is retained.

## Screens discovered and covered

| Actual project UI | Behavior |
|---|---|
| Startup loading / crossfade | Consume Back until loading completes; never exit |
| Home | Warn, then exit only within the confirmation window |
| Hangar / aircraft browsing and purchases | Return to actual previous screen |
| Weapon loadout / weapon purchases | Close popup before leaving Hangar |
| Galaxy Map / level selection | Return to actual previous screen |
| Planet information | Existing inline map briefing; no separate detail scene |
| Settings: General, Language, Audio, Display, Graphics, Controls | Close settings to its owning screen |
| Display → Gameplay | Return to Display first |
| Customize Control Position | Cancel draft, restore parent settings; saved layout retained |
| Flight Manual | Close manual first |
| Active gameplay | Pause |
| Pause | Resume |
| Settings over Pause | Close settings and retain Pause |
| Failed / completed mission results | Save and return to launch screen |

There are no standalone upgrade scenes, separate shop scenes, or native confirmation dialogs in this checkout. Aircraft purchases live in Hangar and weapon purchases in the loadout popup. Future modal UIs can implement `navigation_back() -> bool` to join the dispatcher.

## Redmi Note 8 device verification

ADB serial `13ff9514`, model Redmi Note 8 / ginkgo, Android API 33, 2340 × 1080 landscape. Inputs below were executed through ADB / Android UiAutomation on the real device; they were not hand-operated gestures.

- Real right-edge swipe returned Hangar → Home and Galaxy Map → Home.
- Real edge swipe closed map Settings, weapon loadout, and the nested control editor while retaining their parent UI.
- Android Back key closed Settings and Flight Manual.
- Gameplay edge Back opened Pause; closing Settings retained Pause; subsequent edge Back resumed gameplay.
- Real mission failure results: edge Back returned to Hangar without exiting.
- Map drag changed the visible constellation position. Actual two-pointer input injected 43 events and changed zoom from 100% to 126%.
- Actual movement plus fire injected 62 events; aircraft movement, projectiles, and enemy kills were visible after resume.
- English and Indonesian exit messages were captured. A Back after expiration kept the process alive. Two delivered edge Back gestures inside two seconds terminated the app normally; it was relaunched afterward.
- Temporarily enabled Android three-button navigation, exposed its software controls, and tapped the actual triangle Back button: Hangar → Home. Restored the original gestural overlay and navigation mode 2 afterward.
- Restored the original English language after localization verification.
- Final APK smoke check: Home → Galaxy Map → Home, with the new Home return label.
- Captured Godot/AndroidRuntime Logcat shows normal startup without script exceptions or Android crashes during the inspected navigation sessions.

Screenshots, input reports, and Logcat are retained under `qa/back-navigation/` (local QA output, ignored by Git).

## Automated verification

Passed: `back_navigation`, `galaxy_zoom`, `continuous_planet_map`, `three_star_progression`, `equipment_integration`, `landscape_ui`, `control_position_resume`, and `game_smoke`.

The new test exercises real Godot Escape and `ui_cancel` input dispatch, nested history, popup priority, draft cancellation, timeout, rapid repeat suppression, pause/resume, external scene replacement, cycle removal, and actual `Game.complete_mission()` for two-star and three-star results. Saved coin balances and mission stars are checked after result Back. Tests write a separate QA save, not the player's save.

## Release artifact

- APK: `build/arena_dash_release.apk`, approximately 53 MB.
- Package: `com.example.arenadash`, version 1.1 / code 2, arm64, non-debuggable release.
- SHA-256: `9b07863ced9a8e49eb83fdef1fa06a46f2887932d03af1277d20b5bf14ccf694`.
- Original production certificate SHA-256: `317b9baedaf187bd9e4cf17096fbca1119dac169f063e3090bd9b5bc8e3523af`.
- Signature v2/v3, alignment, ZIP integrity, exact release template, and build policy checks passed.
- In-place installation succeeded; no signature conflict and no app data clearing.

## Limits

Android's immersive fullscreen mode sometimes consumes the first edge swipe to reveal transient system bars. A subsequent swipe is delivered as Back; this OS reveal is separate from the game's confirmation window. Existing fullscreen appearance was preserved.

Successful two-/three-star result reward preservation was verified in automated game tests; the physical device run reached failure results rather than completing a successful mission. Predictive Back visual previews on newer Android releases were not tested on this Android 13 phone.

The navigation regression exits successfully but Godot's headless shutdown reports retained Ogg music playback resources (8 objects / 4 resources); verbose inspection identifies Hangar and map music. No navigation assertion failed. This audio cleanup warning remains outside the navigation change.
