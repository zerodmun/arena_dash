# Arena Dash 🚀
> **HD Semi-3D Hyperspace Shooter built with Godot 4.7**  
> Battle hostile drones across alien planetary sectors, customize advanced starfighters in the 3D Hangar, harness devastating energy armaments, and dodge dynamic cosmic hazards.

---

## 🌟 Overview & Highlights

**Arena Dash** is an action-packed, cross-platform top-down semi-3D arena space shooter engineered in **Godot 4.7**. Designed for both high-end desktop displays and mobile touch devices, the game features high-definition vector graphics, simulated 3D ship physics, responsive mobile virtual controls, dynamic biome hazards, and synthetic audio.

### Key Features
- **Cinematic 3D Hangar Hub**:
  - Interactive 3D yaw/pitch motion simulation with dynamic engine particle exhausts and idle hover physics.
  - Smooth swipe/drag carousel switching between 3 distinct starfighters.
  - Real-time tactical telemetry and ship performance stat meters (Speed, Armor, Firepower).
- **Advanced Starfighter Roster**:
  - 🔵 **Valkyrie Interceptor**: High-maneuverability strike craft equipped with rapid twin plasma blasters.
  - 🟣 **Phantom Specter**: Ultra-agile stealth interceptor optimized for lightning-fast strafing runs.
  - 🟠 **Titan Dreadnought**: Heavy armored battlecruiser boasting reinforced hull plating and overwhelming firepower.
- **Armory Weapon Systems**:
  - ⚡ **Plasma Cannons**: Standard ionized plasma bolts with rapid cycler rates.
  - 🔴 **Twin Ruby Lasers**: High-intensity dual coherent beam cannons with optical focusing crystals.
  - 🌀 **Quantum Singularity**: Heavy 3-way gravitational cluster projectile spreading destruction across the arena.
- **Mission Sector Deployment Modal**:
  - Tactical pre-flight mission deployment dialog triggered upon clicking **"START MISSION"**.
  - Detailed planetary telemetry, threat ratings, and hazard briefings:
    - **Sector 01: Cyber Matrix** – Orbital digital fortress with holographic barricades and laser pillars.
    - **Sector 02: Primal Jungle** – Exotic exoplanet infested with prehistoric flora and predatory dinosaur titans.
    - **Sector 03: Void Horizon** – Deep-space cosmic nebula plagued by dense 3D asteroid belts and meteor storms.
    - **Purpose-Built Dual UI Architectures (Mobile App vs. Desktop Command Deck)**:
  - **Mobile App**: Purpose-built mobile-first interface designed specifically for touch screens. Features a clean top app bar (`⚡ ARENA DASH` + `🏆 BEST: %d`), hero starfighter showcase with smooth swipe rotation, compact 3-gauge horizontal telemetry dock (`SPD`, `SHD`, `RATE`), horizontal tactical weapon dock, full-width thumb launch actuator, and a purpose-built vertical tactical mission briefing drawer (`MobileMissionModal`).
  - **Browser/Desktop**: Widescreen command bridge layout with desktop keyboard hints (`[A/D]` ship cycling, `[1-3]` weapon cycling, `[ENTER]` launch, `[F11]` fullscreen), wide telemetry stats panel, and completely hidden touch controls for clean widescreen gameplay.
  - **Automatic Device & Viewport Detection**: Completely removed manual "Switch View" buttons. Viewport size, aspect ratio, and device touchscreen capabilities are dynamically tracked in real-time (`Game._update_device_detection()`), automatically switching layouts instantly when window is resized or device rotated.
- **Hardcoded Typography (System Settings Bypass)**:
  - All font sizes, contrast outlines (`outline_size = 4..8`), and colors are strictly hardcoded via [`scripts/ui_styler.gd`](file:///Users/tentendigitalindonesia/Downloads/XxX/Apps/testing-app/scripts/ui_styler.gd).
  - Phone operating system accessibility font scaling, user zoom, or DPI distortions are bypassed via deterministic 1080p canvas scaling (`window/dpi/allow_hidpi=false`).
- **HD Graphics & Custom Splash**:
  - 1080p cinematic Arena Dash boot splash on Web and Android 12+ splash screens.
  - Lossless vector assets rendered with MSAA 4x anti-aliasing and 2D canvas stretch scaling.
- **Procedural Synthesizer Sound Engine**:
  - Fully procedural audio effects (lasers, plasma bolts, quantum explosions, warp jumps, engine hum, and UI clicks) requiring zero external audio samples.

---

## 🎮 Controls

### Desktop (Keyboard & Mouse)
| Action | Primary Key | Secondary Key | Notes |
| :--- | :--- | :--- | :--- |
| **Thrust / Flight** | `W`, `A`, `S`, `D` | `Arrow Keys` | Full 8-directional movement |
| **Fire Weapons** | `Space` | `J` / Left Click | Continuous auto-fire on hold |
| **Hangar Navigation** | `A` / `D` | Left / Right Arrows | Cycle starfighters |
| **Deploy Mission** | `Enter` | `Space` | Quick launch |

### Mobile & Touch (Android / Web Touch)
| Action | Touch Control | Behavior |
| :--- | :--- | :--- |
| **Steering / Movement** | **Floating Virtual Joystick** (Left Screen) | Touch and drag anywhere on the left screen half. Resets smoothly on release. |
| **Fire Weapon** | **Fire Button** (Bottom-Right) | Prominent semi-3D circular button with thumb margin. Hold to stream fire. |
| **Hangar Swipe** | **Horizontal Swipe** | Swipe ship model left/right to seamlessly cycle through starfighters. |
| **Mission Select** | **Interactive Sector Cards** | Tap any planetary card, then tap **WARP JUMP TO MISSION**. |

---

## 🏗️ Project Architecture & Directory Layout

```
testing-app/
├── project.godot            # Engine settings, display modes, autoloads, boot splash
├── export_presets.cfg       # Android & Web export presets (vulkan/gl_compatibility)
├── build_apk.sh             # Automated one-step Android headless build & signing script
├── serve_web.py             # Python HTTP server with COOP/COEP headers for Godot Web
├── README.md                # Main project documentation
├── docs/                    # Technical architecture & deployment guides
│   ├── ARCHITECTURE.md      # Detailed engine & system architecture
│   └── DEPLOYMENT.md        # APK signing, store distribution & web hosting
├── scripts/                 # Core GDScript game logic
│   ├── game.gd              # Autoload "Game" - Global state, save data, mission state
│   ├── input_setup.gd       # Autoload - Dynamically creates keybindings & input actions
│   ├── sound_effects.gd     # Autoload - Procedural audio waveform synthesizer
│   ├── hangar.gd            # 3D-style ship carousel, stat cards, mission deployment modal
│   ├── main.gd              # Arena orchestrator, hazard spawner, boundaries, camera
│   ├── player.gd            # Starfighter physics, thrust, shooting, hurtbox, invulnerability
│   ├── bullet.gd            # Projectile kinematics, collision detection, particle impacts
│   ├── enemy.gd             # Enemy chasing AI, health, hit flash, destruction effects
│   ├── enemy_spawner.gd     # Wave-based scaling enemy spawner
│   ├── obstacle.gd          # Sector-specific obstacles (asteroids, pillars, dinosaurs)
│   ├── pickup.gd            # Energy core collectible bobbing and magnetic pull
│   ├── pickup_spawner.gd    # Periodic pickup distribution across arena
│   ├── hud.gd               # In-game HUD, health/shield bars, score multiplier, pause
│   ├── joystick.gd          # Floating virtual joystick with touch isolation & focus safety
│   ├── explosion_particles.gd # Dynamic radial debris & plasma blast particles
│   └── floating_text.gd     # Pop-up score and combo text animations
├── scenes/                  # Godot scene trees (.tscn)
│   ├── hangar.tscn          # Initial entry point: 3D Hangar showcase & deployment dialog
│   ├── main.tscn            # Combat arena scene: gameplay, obstacles, boundaries
│   ├── player.tscn          # Player ship node with collision, hurtbox, engine thrusters
│   ├── enemy.tscn           # Enemy drone node
│   ├── bullet.tscn          # Projectile node with trail and particle emitters
│   ├── obstacle.tscn        # Obstacle node with dynamic texture & collision shape
│   ├── pickup.tscn          # Energy core pickup node
│   └── hud.tscn             # HUD canvas overlay & virtual touch controls
├── assets/                  # High-definition SVG vectors and artwork
│   ├── splash.png           # 1920x1080 master boot splash image
│   ├── splash.svg           # High-resolution vector source for splash artwork
│   ├── player.svg           # Valkyrie Interceptor vector texture
│   ├── player_phantom.svg   # Phantom Specter vector texture
│   ├── player_titan.svg     # Titan Dreadnought vector texture
│   ├── bullet.svg           # Plasma cannon bolt texture
│   ├── bullet_laser.svg     # Twin ruby laser bolt texture
│   ├── bullet_quantum.svg   # Quantum singularity bolt texture
│   ├── map_cyber.svg        # Cyber Matrix planetary sector illustration
│   ├── map_forest.svg       # Primal Jungle planetary sector illustration
│   ├── map_space.svg        # Void Horizon deep space nebula illustration
│   ├── map_random.svg       # Hyperspace warp anomaly illustration
│   ├── obstacle_*.svg       # Biome obstacle vectors (asteroids, barriers, dinos)
│   ├── joystick_*.svg       # High-tech virtual joystick textures
│   └── fire_button.svg      # High-tech fire trigger texture
└── build/                   # Compiled outputs
    ├── arena_dash.apk       # Cryptographically signed Android Release APK
    └── web/                 # Godot WebAssembly distribution package
        ├── index.html       # Web landing page with styled cyan progress loader
        ├── index.js         # Godot Web engine bridge
        ├── index.wasm       # Compiled engine WebAssembly binary
        └── index.pck        # Game assets and compiled bytecode package
```

---

## ⚡ Quick Start

### 1. Test in Local Browser (WebAssembly)
A local HTTP server with COOP/COEP headers is pre-configured and runs on port `8060`:

```bash
# Start server (if not already running)
python3 serve_web.py

# Open in browser
open http://127.0.0.1:8060/
```
*Note: Cross-Origin-Opener-Policy (`same-origin`) and Cross-Origin-Embedder-Policy (`require-corp`) are required for Godot 4 SharedArrayBuffer multi-threading.*

---

### 2. Run in Godot 4 Editor
1. Install **Godot 4.7+** (via Homebrew: `brew install --cask godot`).
2. Open Godot → Click **Import** → Select `project.godot`.
3. Press **F5** (or click the Play icon in the top right).
4. The game opens directly into the **Hangar Hub** (`scenes/hangar.tscn`).

---

### 3. Build & Install Android Release APK

The project includes an automated script [`build_apk.sh`](file:///Users/tentendigitalindonesia/Downloads/XxX/Apps/testing-app/build_apk.sh) that runs headless Godot export and cryptographically signs the APK with `apksigner`:

```bash
# Export and sign release APK
./build_apk.sh --export-release

# Install onto connected Android device or emulator via ADB
adb install -r build/arena_dash.apk
```

**APK Verification:**
```bash
JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home" \
/opt/homebrew/share/android-commandlinetools/build-tools/34.0.0/apksigner verify --verbose build/arena_dash.apk
# Output: Verifies (APK Signature Scheme v2 & v3: true)
```

---

## 🛡️ Collision Layers & Physics Setup

The physics system uses dedicated 2D collision layers to maintain strict separation of concerns and high performance:

| Layer ID | Bit Value | Name | Purpose | Collides With (Mask) |
| :---: | :---: | :--- | :--- | :--- |
| **1** | `1` | **Walls & Boundaries** | Arena bounding colliders & perimeter | Player Body, Enemies, Bullets |
| **2** | `2` | **Player Body** | Starfighter physical chassis | Walls, Obstacles |
| **3** | `4` | **Enemies** | Hostile drone chassis | Walls, Obstacles, Other Enemies |
| **4** | `8` | **Obstacles** | Dynamic sector obstacles (asteroids, barriers) | Player, Enemies, Bullets |
| **5** | `16` | **Pickups** | Energy cores & powerups | Player Hurtbox (Area2D) |

- **Player Damage**: Evaluated via child `Hurtbox` Area2D detecting Layer 3 (Enemies) and Layer 4 (Hazards).
- **Bullet Impact**: Layer mask set to detect Layers 1 (Walls), 3 (Enemies), and 4 (Obstacles).

---

## ⚙️ Scoring & Difficulty Scaling

- **Enemy Destruction**: `+100 pts` base score + combo multiplier bonus.
- **Energy Core Pickup**: `+250 pts` + shield regeneration.
- **Kill Streaks**: Sequential kills boost the score multiplier up to `4x`.
- **Dynamic Difficulty**:
  - Enemy spawn intervals decrease progressively from `2.0s` down to `0.45s` as score increases.
  - Enemy chase speed scales up by `5%` per wave milestone.
  - Dynamic biome hazards (e.g. meteor showers in Void Horizon) spawn more frequently over time.

---

## 📄 License & Credits
Developed with ❤️ using the [Godot Engine](https://godotengine.org/).  
Built and optimized for desktop, mobile, and web gaming.
### Flight Command update

- Hangar responsif dengan pilihan langsung pesawat, senjata, dan lokasi; tombol
  memiliki status pilihan, fokus keyboard, serta ringkasan lokasi sebelum mulai.
- Armada baru: **Falcon** (strike fighter) dan **Aurora** (recon wing), dengan aset
  SVG tersendiri, panel logam, cockpit, dan mesin.
- **Ion Cannon** ditambah ke tiga senjata sebelumnya. Semua peluru memiliki wake
  cahaya dan efek benturan sesuai warna senjata.
- Map **Coastal Front** dan **Dune Outpost** menggunakan terrain prosedural berupa
  garis pantai, pulau dangkal, riak air, bukit pasir dan landasan. Visual tetap 2D.
- Penghalang memakai AnimatableBody2D: arah, kecepatan, dan interval berubah acak
  dalam jangkauan lokal. Area tengah dijaga bebas untuk spawn; retry mengembalikan
  posisi penghalang. Pohon/relic bergerak sebagai hazard arcade.
- **Esc/P** membuka jeda dengan lanjutkan atau kembali ke hangar. Ada notifikasi
  awal misi, kilatan saat terkena serangan dan peringatan perisai kritis.

Pemeriksaan integrasi (semua map, pesawat preview, peluru, pergerakan dan pause):

```sh
godot --headless --path . --log-file /tmp/arena-smoke.log res://tests/game_smoke.tscn
```

Preview visual (jendela Godot; hasil PNG di `build/preview_*.png`):

```sh
godot --path . --rendering-method gl_compatibility --windowed --resolution 1440x1000 --log-file /tmp/arena-preview.log res://tests/game_smoke.tscn -- --screenshots
```

### Hangar 2D dengan preview interaktif

Hangar memakai aset SVG pesawat 2D dari katalog Game dengan komposisi referensi:
bar atas dengan judul tengah, strip statistik horizontal, display pesawat besar
di tengah dan panah kiri/kanan. Latar 2D menggambarkan dinding hangar berwarna
kuning, pipa, lantai perspektif, serta garis keselamatan.

Pilih pesawat dengan thumbnail di bawah, panah, A/D, atau geser horizontal pada
display. Swipe vertikal tidak mengubah pesawat.

Card peluru dan map berada di kiri bawah pada landscape, dengan tombol mulai
di kanan bawah. Keduanya membuka popup:

- **Pilih Peluru:** popup menampilkan pesawat yang sedang dipilih dan animasi
  tembakan. Klik tipe peluru di bawah preview untuk langsung mengganti tekstur,
  warna, dan pola tembakan (single, twin, spread). Popup tetap terbuka saat memilih.
- **Pilih Map:** popup menampilkan pesawat di arena dengan penghalang bergerak.
  Pilihan map dan lokasi acak berada di bawah preview.

Tutup dengan Selesai, X, Esc, atau klik area luar popup. Pilihan peluru tersimpan;
map diterapkan saat Mulai Misi. Preview hanya visual, tidak memunculkan body
peluru gameplay atau mengubah skor. Kontrol latar tidak aktif selama popup terbuka.
Pada portrait, statistik tetap di atas, display tetap di tengah, dan seluruh
kontrol berada di bawah tanpa perlu menggulir halaman utama.

Uji integrasi UI dan screenshot desktop/portrait:

```sh
godot --path . --rendering-method gl_compatibility --windowed --resolution 1440x900 --log-file /tmp/hangar-2d-visual.log res://tests/hangar_review.tscn -- --screenshots
```

Pengujian mengembalikan pilihan tersimpan setelah selesai. Hasil preview berada
di `build/preview_hangar.png`, `build/hangar_weapon_popup.png`,
`build/hangar_map_popup.png`, dan preview portrait terkait.
