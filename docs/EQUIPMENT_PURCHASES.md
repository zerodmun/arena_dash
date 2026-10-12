# New equipment and persistent purchases — 2026-10-10

## Asset audit

Scanned the assets directory and compared gameplay artwork with catalog references. All 22 identifiable equipment files are static SVGs: 16 aircraft and six projectile textures. No sprite-sheet or animated equipment assets were present. Four newer aircraft and two newer weapons already had partial catalog entries; this change completes their configuration, purchase presentation, migration behavior and gameplay validation rather than replacing the artwork.

All 22 source asset SHA-256 hashes remained unchanged. `qa/equipment-qa/asset-inventory.json` records paths, dimensions, animation detection, reference coverage and hashes. There are zero unreferenced identifiable gameplay equipment assets. Decorative UI cards, planet artwork, logo and menu environment are not treated as new purchasable equipment.

## Central configuration and actual gameplay

`scripts/equipment_catalog.gd` is now the source of stable IDs, prices, textures, colors, movement speeds, shields, firing intervals, visual scales, collision radii, muzzle/trail positions, projectile patterns, speeds, damage and lifetime. `Game.SHIPS` and `Game.WEAPONS` remain compatible aliases. Player customization and pooled bullets consume these properties. Existing equipment retains its established scales, collision sizes, projectile speeds, damage and cadence.

| New equipment | Price | Gameplay configuration |
|---|---:|---|
| Solaris | 750 | Speed 460, 4 shields, base interval 0.12 s, scale 0.28, radius 34 |
| Vortex | 900 | Speed 480, 3 shields, base interval 0.10 s, scale 0.26, radius 32 |
| Nemesis | 1100 | Speed 420, 5 shields, base interval 0.13 s, scale 0.30, radius 36 |
| Chronos | 1400 | Speed 440, 5 shields, base interval 0.11 s, scale 0.30, radius 36 |
| Plasma Lance | 450 | Single projectile, speed 960, damage 2, ship interval ×1.4 |
| Nova Burst | 600 | Two focused projectiles, speed 720, damage 2 each, ship interval ×1.5 |

Projectile lifetime is 2.4 s. These weapons use the existing single/burst patterns, collision and impact effects; no piercing, area damage or special abilities were invented. Descriptions now accurately describe the supported behavior. Existing weapon audio aliases reuse the existing plasma and quantum audio. Ships reuse established banking, recoil and thruster animation, with conventional forward muzzle positions. New equipment is functional during actual gameplay, not just in the decorative Hangar preview.

Fresh accounts retain Falcon, Aurora, Valkyrie, Ion Cannon and Plasma Bolt for free. Other equipment remains priced. Existing mission coin rewards are unchanged: base 120 + 30 per star + 10 per planet index, plus a one-time 250 first-clear bonus. A three-star campaign pays 3960 coins; all priced equipment totals 8900. Buying the entire collection requires additional ordinary replay rewards—24 three-star first-planet replays cover the difference. No premium currency, advertisements or real-money purchases were added.

## Hangar purchase flow

The existing theme, fonts, backgrounds, rounded button materials, upper-left title, upper-right wallet and prominent Deploy button remain intact. A compact Purchase/Select control sits between the existing aircraft arrows, with the aircraft ownership/count line above it.

Browsing previews equipment without changing the equipped aircraft. Locked aircraft show a lock badge, required price and LOCKED state. Deploy is disabled for a locked preview. Successful Purchase unlocks the aircraft, updates the wallet and changes the control to Select. Select persists the equipped aircraft; active equipment shows EQUIPPED. Deploy still launches an owned preview through the existing mission path.

Weapon options show full-size existing lock badges, prices and Unlocked/Selected/Equipped states. Purchase unlocks the chosen weapon without silently equipping it; the action changes to Equip. Equip persists the selection and closes the dialog. Insufficient balance leaves the item locked and deducts nothing. The six-option dialog uses the existing two-column preview/information layout, with wider option buttons and enough height for every option and translated description. English and Indonesian entries cover new actions, messages and descriptions.

## Saving and compatibility

Balance and ownership remain a single atomic ConfigFile snapshot written through the existing temporary-file/rename transaction. Duplicate purchase calls return `owned` and never deduct again. Failed writes roll the purchase back. Selection now also rolls back if its save fails, so the visible loadout cannot pretend an unsaved selection succeeded.

Migration grants only the original 12 aircraft/four weapon entitlements, plus explicitly saved equipped IDs as evidence of earlier access. It no longer grants every future catalog entry automatically. New equipment defaults to locked when no previous entitlement exists. Existing versioned ownership, positive coin balances, equipped IDs, campaign stars, reward history and high scores are preserved.

An earlier versioned save may already contain ownership granted by the previous migration. There is no receipt history that distinguishes that grant from a legitimate purchase. Such recorded ownership is retained rather than revoking player progress. Stable item IDs and the existing save schema remain unchanged.

## Completed verification

- Import/scene/script validation: no parse errors.
- Equipment integration: PASS in the desktop Godot renderer, zero assertions failed. Exercises all six new purchases, exact deductions, ten repeated duplicate calls per item, locked-selection guards, legacy/versioned migration, save-failure selection rollback, each new ship's gameplay texture/scale/collision/muzzle/speed/shields/HUD, both new weapon patterns, touchscreen-HUD input callbacks, actual enemy damage and pooled projectile reset to starter properties.
- Second independent Godot process: PASS. Restores all six purchased items, Chronos/Nova Burst loadout and the exact 10800-coin isolated test balance.
- Rendered purchase UI: PASS at 1280×720, 1440×720, 1560×720 and 1600×720 in English and Indonesian. Exercises insufficient funds, Purchase → Select/Equip, exact debits, restored equipment, lock icons, text fit and dialog containment.
- Existing coin economy, coin UI and Hangar layout regression suites: PASS. Some headless harness shutdowns report ObjectDB/resource cleanup warnings; the final rendered integration and UI runs exit cleanly.
- Original equipment artwork hashes: unchanged.
- Final exported APK contains the central catalog and all six new artwork resources. Signature v2/v3 and zip alignment checks pass.

Tests use dedicated `equipment-integration-review.cfg` and `equipment-ui-review.cfg` desktop profiles, rather than the production player save. Calls through the touch HUD were simulated in Godot; physical Android multitouch was not verified.

Evidence: `qa/equipment-qa/` contains inventory, import/build logs, rendered purchase screenshots, six actual gameplay captures, assertion logs, second-process restore results and APK resource inspection. These are desktop Godot captures, not phone screenshots.

## Android device verification remains blocked

ADB reports no connected device or paired wireless transport. Installation of the final APK on the previously connected Redmi Note 8 failed with `device '13ff9514' not found`. No phone profile, coin balance or purchase history was accessed or modified. Installation, physical Hangar inspection, Android purchases, restart persistence and touchscreen gameplay verification remain outstanding. Previous phone screenshots from earlier tasks do not verify this build.

Delivered development-signed APK: `build/arena_dash_debug.apk`.

SHA-256: `782ad0a03b009f4040d3486be4e071f82eef171cc193be39cdcfcfd7ea739198`.

The APK uses the existing official Godot Android export templates and landscape configuration. Tests/docs/build evidence are excluded from the production package; no controlled test balance is embedded in the application.
