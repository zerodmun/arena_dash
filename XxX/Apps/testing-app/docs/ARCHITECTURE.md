# Arena Dash: Technical Architecture & Systems Manual

This document provides a comprehensive technical overview of the systems, data models, physics interactions, rendering pipelines, and input architectures within **Arena Dash**.

---

## 1. High-Level System Architecture

Arena Dash utilizes an event-driven, decoupled architecture powered by Godot's node hierarchy, signal bus patterns, and persistent Autoload singletons.

```
+-------------------------------------------------------------------------+
|                               AUTOLOADS                                 |
|  [Game (game.gd)]       [SoundEffects (sound_effects.gd)]  [InputSetup] |
|   - Save / Config         - Real-time Audio Synthesizer     - ActionMap |
|   - Score & HighScore     - Waveform Generators                         |
|   - Ship / Weapon / Map   - SFX Signal Listeners                        |
+-------------------------------------------------------------------------+
                                    |
          +-------------------------+-------------------------+
          |                                                   |
          v                                                   v
+-------------------------------+             +-------------------------------+
|      HANGAR ENTRY SCENE       |             |       MAIN COMBAT ARENA       |
|      (scenes/hangar.tscn)     |             |       (scenes/main.tscn)      |
|  - 3D Pseudo-Mesh Carousel    |             |  - Arena Bounds & Background  |
|  - Real-time Stat Gauges      |             |  - Dynamic Obstacle Spawner   |
|  - Armory Weapon Systems      |             |  - Wave Enemy Spawner         |
|  - Mission Deployment Modal   |             |  - Energy Pickup Spawner      |
|    (%MissionModal)            |             |  - Camera2D Follow & Shake    |
+-------------------------------+             +-------------------------------+
                                                              |
                                           +------------------+------------------+
                                           |                                     |
                                           v                                     v
                            +-----------------------------+       +-----------------------------+
                            |        PLAYER SHIP          |       |         IN-GAME HUD         |
                            |    (scenes/player.tscn)     |       |      (scenes/hud.tscn)      |
                            | - CharacterBody2D Physics   |       | - Ergonomic Top Stat Bar    |
                            | - Dynamic Weapon Cycler     |       | - Shield/Health Gauge       |
                            | - Engine Glow / Exhaust     |       | - Floating Touch Joystick   |
                            | - Invulnerability Buffer    |       | - High-Tech Fire Trigger    |
                            +-----------------------------+       +-----------------------------+
```

---

## 2. Autoload Singletons

### 2.1 `Game` (`scripts/game.gd`)
The global state coordinator and persistent configuration manager.
- **State Storage**:
  - `selected_ship`: `"valkyrie"`, `"phantom"`, `"titan"`
  - `selected_weapon`: `"plasma"`, `"laser"`, `"quantum"`
  - `selected_map`: `"cyber"`, `"forest"`, `"space"`, `"random"`
  - `score`, `high_score`, `multiplier`, `lives`, `shield`
- **Dynamic Random Sector Routing**:
  - When `"random"` is selected, `select_map("random")` dynamically samples from `["cyber", "forest", "space"]` before scene instantiation.
- **Persistence**:
  - Saves high score and user loadouts to `user://arena_dash_save.cfg` using Godot's `ConfigFile`.
- **Global Signals**:
  - `score_changed(new_score)`, `high_score_changed(new_high)`
  - `lives_changed(new_lives)`, `shield_changed(new_shield, max_shield)`
  - `ship_selected(ship_id)`, `weapon_selected(weapon_id)`, `map_selected(map_id)`
  - `game_over`, `game_restarted`

### 2.2 `SoundEffects` (`scripts/sound_effects.gd`)
A pure algorithmic sound generator utilizing `AudioStreamGenerator` and `AudioStreamGeneratorPlayback`:
- **Zero Audio Bloat**: No `.wav` or `.ogg` sound files bundled into the APK/web pack.
- **Procedural Waveforms**:
  - **Laser**: High-frequency exponential pitch drop sine waves with high pass filtering.
  - **Plasma**: Square wave pulse with mild distortion and frequency sweep.
  - **Quantum Singularity**: Modulated multi-oscillator low-frequency thrum with harmonic sub-bass.
  - **Explosion**: Band-limited white noise envelope with exponential volume decay.
  - **Pickup Chime**: Dual-tone musical arpeggio with high resonance.

### 2.3 `InputSetup` (`scripts/input_setup.gd`)
Ensures that keybindings (`move_left`, `move_right`, `move_up`, `move_down`, `shoot`, `ui_accept`) are registered in `InputMap` at runtime across all targets without requiring hard-coded engine overrides.

---

## 3. The 3D Pseudo-Mesh Simulation (Hangar)

The Hangar (`scenes/hangar.tscn`, `scripts/hangar.gd`) provides a 3D showcase using 2D rendering:
1. **Kinematic Yaw & Pitch**:
   - As the ship idles or follows swipe gestures, its `scale.x` is modulated via `cos(time * 1.5) * tilt_factor` to simulate rotational perspective.
   - Dynamic skew and subtle vertical offset `sin(time * 2.0) * 12.0` model natural aerodynamic levitation in zero-g hangars.
2. **Procedural Engine Glow**:
   - Starfighter rear engine thrusters use radial gradients with oscillating alpha values `0.7 + 0.3 * sin(time * 15.0)` to emulate high-temperature plasma burn.
3. **Swipe Gesture Recognizer**:
   - Tracks touch delta across horizontal axis. Threshold-based triggers cycle the active ship model with spring easing curves (`Tween.TRANS_BACK`, `Tween.EASE_OUT`).

---

## 4. Mission Sector Deployment Modal Flow

Rather than selecting maps from a static bottom row, map selection is framed as a tactical mission briefing:
1. Player clicks **"START MISSION"** in the Hangar.
2. `%MissionModal` fades in with backdrop blur and high-contrast panel frames.
3. The UI presents 4 tactical sector cards:
   - **Sector 01 (Cyber Matrix)**: Orbital station graphics, laser barrier hazards.
   - **Sector 02 (Primal Jungle)**: Continental swirl world, prehistoric raptor obstacles.
   - **Sector 03 (Void Horizon)**: Asteroid belt nebula, meteor hazard waves.
   - **Sector 00 (Random Sector Warp)**: Quantum tesseract, unpredictable battlefield.
4. Player chooses a sector card, then confirms via **"WARP JUMP TO MISSION ❯"**.
5. `Game.select_map(id)` configures the game parameters and transitions cleanly to `res://scenes/main.tscn`.

---

## 5. Mobile Ergonomics & Virtual Controls

### 5.1 Virtual Joystick (`scripts/joystick.gd`)
The floating virtual joystick is engineered for extreme touch responsiveness:
- **Canvas-Space Coordinate Transformation**:
  - Local touch positions are mapped via `get_global_transform_with_canvas() * event.position`, ensuring pixel-perfect alignment under any DPI scaling or screen aspect ratio.
- **Touch Index Isolation**:
  - Captures `event.index` upon `InputEventScreenTouch.pressed` and discards all other finger touches for steering, preventing conflicts with right-thumb firing.
- **Lifecycle & Focus Resilience**:
  - Implements `_notification(what)` listening for:
    - `NOTIFICATION_APPLICATION_FOCUS_OUT`
    - `NOTIFICATION_WM_WINDOW_FOCUS_OUT`
    - `NOTIFICATION_APPLICATION_PAUSED`
  - Immediately resets touch indices, steering vectors, and knob visual coordinates to neutral resting positions if the player minimizes the app or opens system notifications.

### 5.2 Fire Trigger & HUD Positioning
- The **Fire Button** is offset from the bottom and right edges (`right: 120px`, `bottom: 120px`) with a generous 140px touch radius, preventing thumb fatigue and avoiding Android navigation gestures.
- The **Health / Shield Bar** and **Score Cards** are mounted inside top-center and top-left safe areas with margin protection for camera punch-holes and notches.

---

## 6. Rendering & Display Configuration

In `project.godot`:
- **Viewport Dimension**: `1920 × 1080` (Native Full HD).
- **Stretch Mode**: `canvas_items` (Aspect: `expand`).
- **Anti-Aliasing**:
  - `rendering/anti_aliasing/quality/msaa_2d=2` (4x MSAA for ultra-crisp vector edges).
  - High-DPI support enabled (`display/window/dpi/allow_hidpi=true`).
- **Web Renderer Fallback**:
  - Mobile/Desktop builds use Vulkan / Forward+ mobile pipelines.
  - Web export presets enforce `rendering/renderer/rendering_method.web="gl_compatibility"` to guarantee compatibility with WebGL 2.0 browsers.
