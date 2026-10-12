# Adaptive icon, Hangar alignment and coin economy

Implemented 2026-10-10. This supersedes the padded adaptive-icon composition in HANGAR_ICON_UPDATE.md.

## Adaptive icon

The old foreground contained the complete square logo at 184 pixels inside a 432-pixel canvas. Android masked the surrounding plain background, leaving a small framed square inside the launcher shape.

`tools/generate_android_icons.gd` now separates existing artwork from `assets/logo.svg`: the original spaceship geometry and gradients become the transparent foreground; the original space gradient, rays and radar details become an opaque background covering the entire canvas. The baked square frame and bottom plaque are omitted from the adaptive composition so Android supplies its own outline. The provided source SVG and PNG are unchanged; no replacement spaceship or logo was drawn.

Both exported PNG layers are 432 × 432. Foreground geometry is uniformly scaled by 0.34 around the canvas center. Its measured maximum opaque-pixel radius is 121.58 pixels, inside the 132-pixel circular safe radius. Background opacity is checked at every pixel. Android's adaptive canvas/safe-area guidance is documented by [Android Developers](https://developer.android.com/codelabs/basic-android-kotlin-compose-training-change-app-icon).

Legacy icons at 48/72/96/144/192 pixels use the same visible full-bleed composition. Android presets already reference these resources; `build_apk.sh` now regenerates them before every export to prevent stale artwork.

APK inspection confirmed `res/mipmap-anydpi-v26/icon.xml` is an adaptive icon with separate foreground/background references. Density-specific foreground/background resources are present. The 432-pixel packaged background exactly matches the generated PNG. Foreground alpha matches exactly; visible color difference from export rounding is at most 12/255 with mean 0.006/255. Unreferenced stock monochrome bitmaps remain in the engine template but are not used by the adaptive XML.

Actual Redmi Note 8 / Android 13 launcher screenshots show a full circular icon with no internal square frame, transparent corner gaps or excessive outer padding. Circle, rounded-square, squircle and teardrop mask previews also pass full-coverage and foreground-clipping checks. Only the phone's available circular mask was physically tested; other masks were verified directly against the layers.

## Economy and Hangar

- HANGAR aligns to the top-left content margin without a header card. Coins replace the Hangar record display, using the existing coin icon; Home also displays coins. Gameplay score and best score remain separate combat statistics.
- Aircraft can be freely browsed, including locked previews. Locked entries show prices and an explicit unlock action. Owned entries equip normally. Weapons have live candidate previews, ownership/equipped/price states and an explicit purchase/equip button.
- `Game` centralizes ownership, balance, mission rewards and purchases. Balance and ownership save together in an atomic temporary-file replacement. Invalid IDs, insufficient funds and duplicate purchases cannot deduct coins. Failed saves roll back the purchase.
- Existing saves previously had every aircraft and weapon available for free, so migration preserves all of those entitlements. Historical mission completion receives one retroactive coin reward, and its first-clear bonus is marked claimed. Combat high scores are never converted into currency. Migration is immediately saved and cannot grant again on reopening.
- New players start with Falcon, Aurora and Valkyrie; Ion and Plasma are free. Paid aircraft prices are Titan 150, Phantom 200, Tempest 250, Mirage 300, Saucer 350, Rocket 400, Wedge 450, Speeder 500 and Booster 600. Twin Lasers cost 200 and Quantum Spread costs 300.
- Mission reward = 120 + 30 × earned stars + 10 × zero-based planet index. Each planet has a one-time 250-coin first-completion bonus. Replays intentionally earn the base performance reward. A three-star eight-planet campaign earns 3,960 coins; all paid equipment costs 3,700 coins. No advertisements or real-money currency were added.
- Results show reward and wallet balance. English and Indonesian keys cover prices, purchases, ownership, insufficient balance and rewards. Stars, difficulty rules and weapon balance are unchanged.

## Verification and evidence

`tests/coin_economy.tscn`: new-player ownership, insufficient balance, locked equip prevention, mission rewards, duplicate claim protection, intentional repeats, both equipment purchases, duplicate purchase protection, invalid IDs, saved balance/ownership/loadout, failed-write rollback, malformed saves and one-time legacy migration. Host run: PASS, zero failures.

Hangar review and landscape UI suites: PASS, zero failures. English/Indonesian text-fit checks: PASS across 16:9, 18:9, 19.5:9 and 20:9 with simulated safe-area insets. Temporary headless harnesses emitted resource-cleanup warnings at shutdown; these are not assertion failures.

Android economy tests run in a separate `com.example.arenadash.economyqa` app/save, preserving the player's production save. Mission reward tests simulate satisfied objective conditions through the real Game singleton; they do not claim a mission was manually played to completion. The first process reports COIN ECONOMY PASS; a second process reports ANDROID RESTART PASS for saved coins, ownership and loadout. The deliberately unwritable transaction test emits an expected file-write error. Historical logs also contain Vulkan surface-loss errors when backgrounding apps; no fatal crash occurred in these checks.

Evidence is in `qa/adaptive-icon-qa/`: build logs, `generation.log`, `mask-previews.png`, `mask-checks.json`, exported resource/XML dumps, phone launcher/app screenshots, Android economy logs, purchase screenshots and `verification.json`. The delivered APK is `build/arena_dash_debug.apk`, signed with the existing development key; signature and alignment verification pass. Final installation and screenshot results are recorded alongside the evidence.

`tests/coin_ui.tscn` additionally passed localized locked-equipment preview, insufficient-funds behavior, purchase text width and safe-area geometry checks across all four landscape aspect ratios.

Real ADB touches in the isolated QA Hangar purchased Titan (460 → 310 coins), purchased/equipped Quantum Spread (310 → 10), and attempted an unaffordable Phantom purchase (10 unchanged). Force-stop/relaunch restored 10 coins, Titan and Quantum Spread. The test application's save snapshot is `phone-ui-save.cfg`; the temporary QA app was removed afterward.

The final production install preserves the player's high score 235, Titan and Quantum Spread. Its historical Cyber mission earns a one-time migration credit of 460 coins. Final Home/Hangar/gameplay and launcher screenshots were inspected; Deploy starts gameplay. Packaged final icon layers match the inspected resources. No script error or fatal crash appears in the final captured runtime log.

Delivered/installed APK SHA-256: `b64ea9827068251acaa163cbe3308de6fc0ed6e50c1390fbcbcd94a1291e53f4`.
