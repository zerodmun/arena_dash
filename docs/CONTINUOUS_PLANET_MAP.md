# Continuous planet map

The campaign uses one 2420 × 1780 world containing the eight original planets and seven advanced planets, ordered by `Campaign.ORDER`. There are no planet pages or tabs. The world pans inside a clipped viewport; Hangar, Settings, the heading, and mission briefing stay fixed within the safe area.

Touch and mouse input share one pointer controller. A 12-pixel threshold distinguishes taps from drags. Only a release without a drag inspects a planet; locked missions cannot deploy. Panning supports both axes, cursor-anchored wheel zoom, trackpad pan gestures, bounded momentum, and exponential deceleration. Distant planet controls are hidden without rebuilding the scene. Existing planet textures are reused; gameplay scenes are not loaded by the map.

Unlocks retain the existing global prerequisite chain: every preceding planet must have three stars. Stable level IDs and the save schema remain unchanged. Coins, inventory, purchase flags, best ratings, and first-clear rewards follow the existing save and reward code.

A three-star completion saves progress and sets a transient map focus destination. The results remain visible for four seconds, then return automatically to the map and pan toward the next mission. Next Planet returns immediately. Replay and Hangar cancel the automatic return. Partial clears remain on the results screen for retry. The final campaign completion now occurs at planet 15. Reopening the map without a transient destination shows the highest unlocked planet; completed planets remain accessible by panning back. Reduced motion disables the camera tween and fade.

## Verification performed on 13 October 2026

- `continuous_planet_map`: PASS. Isolated new-player save, all 15 nodes, spacing, locked inspection, mouse/touch drag suppression, second-finger exclusion, four-direction movement, momentum, bounds, original-to-advanced transition, all seven advanced unlocks, rewards, equipment preservation through CFG reload, map reopen focus, previous planet access, four landscape sizes, and actual automatic gameplay-results-to-map transition.
- `three_star_progression`: PASS. One/two/three-star gating across all 15 planets, rating boundaries, replay best preservation, legacy-save validation, bilingual results.
- `advanced_campaign`: PASS. All seven advanced gameplay scenes, controlled guardian defeat, enemy roles, coins, duplicate reward prevention, and save reloads.
- `landscape_ui`: PASS. Existing landscape and safe-area checks, updated for a clipped scrollable world.
- `coin_economy`: PASS.
- Desktop OpenGL render run of `continuous_planet_map`: PASS; screenshots saved in `qa/continuous_map_new_player.png` and `qa/continuous_map_advanced.png` and visually inspected.
- Release built using the existing Keychain signing identity via `build_apk.sh`. Signature, alignment, packaged identity, release flags, icons, and ZIP integrity validation passed. Artifact: `build/arena_dash_release.apk`. SHA-256: `26964dd452dec435d3aecbaa98ee357ec8f574d821d6fbe279610d6b2f88fd60`.

All progression writes used isolated QA saves. No real player save was overwritten. Controlled test completions validate unlock and reward logic; they do not establish real-player difficulty balance or full manual playthroughs.

## Pending device verification

ADB was started with host access, but `adb devices -l` returned an empty device list on both checks. The release has not been installed or tested on the Android phone. Native Android gesture behavior, GPU performance, and persistence across force-stop/relaunch on the phone remain unverified. Connect and authorize the phone to finish this step; preserve its production app data and use a separate QA package/save for progression scenarios.


## Galaxy zoom update — 13 October 2026

The header now includes fixed minus, plus, and Fit controls plus a zoom percentage. Wheel events zoom smoothly toward the mouse cursor. Trackpad magnification is supported. Two tracked touch IDs provide pinch distance and midpoint translation; both run together so the same world point follows the midpoint. Lifting one finger allows continued panning, while the complete gesture suppresses planet taps. Canceled touches and focus loss clear the gesture safely. A second finger that crosses the fixed UI is consumed by the active map gesture.

Exported `minimum_zoom` and `maximum_zoom` default to 0.5 and 2.0 relative to the viewport base scale. The effective minimum also permits a complete fit view, calculated from the world, viewport, and minimum text/target sizes. At 1280 × 720 the overview is approximately 26%. Camera bounds include any readable labels extending beyond the nominal world, and smaller worlds are centered. Planet targets remain at least 48 screen pixels. Names have a minimum 12-pixel screen font and ellipsize within their own slots in overview; the full name remains in the fixed briefing. Stars and number markers have bounded screen sizes, and lock badges show locked missions even when a name is abbreviated.

Zoom preference is saved in the additive `settings/map_zoom` field. Legacy saves default to 1.0; invalid values fall back safely. Leaving the map or losing app focus saves changes. Mission focus changes position while retaining zoom. Progression and gameplay rules are unchanged by this zoom update.

Additional validation performed:

- `galaxy_zoom`: PASS in headless and rendered desktop runs. Godot viewport input events exercised wheel and two-finger gestures, moving anchors, one-finger continuation, canceled touch rejection, wheel while mouse dragging, zoom clamps, zoom buttons, full-world fit and centering, 48-pixel targets, readable fonts, separate name/star bounds, selection of every planet at four scales, four landscape safe-area layouts, saved preference, advanced unlock focus, and reduced motion.
- `continuous_planet_map`: PASS after updating the former second-finger exclusion expectation to pinch behavior.
- `three_star_progression`, `advanced_campaign`, `landscape_ui`, and `coin_economy`: PASS.
- Final fit and maximum-zoom images visually inspected: `qa/galaxy_zoom_fit.png`, `qa/galaxy_zoom_maximum.png`.
- Updated signed release rebuilt and signature/alignment/package/icon validation passed. SHA-256 recorded above now identifies the zoom build.

Device checks again returned no connected ADB device. Synthetic two-finger event tests passed, but physical Android pinch input and native landscape performance have not been tested. No production phone save was accessed or changed.
