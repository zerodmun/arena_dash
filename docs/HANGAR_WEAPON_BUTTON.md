# Hangar weapon button — 12 October 2026

The equipped weapon button retains its 352 × 108 landscape footprint and existing rounded artwork, colors and borders. Existing weapon textures now occupy a centered 144 × 96 image slot (previously 32 × 50) with proportional fit and no crop. The weapon name uses 16-point wrapping text beside the image (previously 26), with a small gold localized Equipped / Dipakai status. The oversized loadout heading and chevron were removed to give the actual artwork focus. Six-pixel vertical inset and eight-pixel content spacing preserve full-height artwork without growing the container.

Only scripts/hangar.gd and the existing tests/hangar_layout.gd changed for implementation/verification. Gameplay, catalog prices, purchase/equip handlers and the weapon picker remain unchanged. The card refresh loads the current catalog texture immediately after equipment changes. Locked options retain their existing lock icon, translated price and purchase action in the picker; the main card represents the equipped weapon.

Verification:
- Hangar layout suite passed at 1280 × 720, 1440 × 720, 1560 × 720 and 1600 × 720, in English and Indonesian. All six weapon textures, proportional scaling, card containment, image/name separation and translated status checked.
- Connected Redmi Note 8: actual ADB taps selected/equipped all six weapons in the isolated QA package; resulting save selections were asserted and screenshots inspected for all six. Twin Lasers and Quantum Spread were purchased from locked state, then equipped; price deductions were 200 and 300 QA coins. Purchase feedback shifts the existing confirm button vertically in Indonesian; the runner adjusted its tap position to the actual rendered button before confirming. This did not require a game change.
- Normal signed APK built, installed and launched; actual normal-package Hangar screenshot captured and inspected. Player save remained byte-identical, including 2,510 coins and the original equipment selection.
- Evidence in qa/weapon-button-qa/: layout-test.log, signed build logs, six *-equipped.png captures, locked/purchased screenshots, normal-hangar.png and real-save-preservation.json. Test-process cleanup warnings remain in the headless log; the suite has zero assertion failures.

APK: build/arena_dash_debug.apk. SHA-256: 88c3ee87d01a2d5a8835cdacbee946dc38f13fcfafbe87624b32ba330b4e0a4f.
