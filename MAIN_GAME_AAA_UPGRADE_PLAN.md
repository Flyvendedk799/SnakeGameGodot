# Main Game Triple-A Upgrade Plan

**Project**: Snake Game Godot - main_game  
**Target**: 200% closer to triple-A quality  
**Scope**: 8 phases, equivalent to 20+ dev team for 6 months

---

## How to Use This Plan (For AI Execution)

Execute phases in priority order. Each section includes:
- **Technical** details and implementation approach
- **Files** to create or modify (paths relative to project root)

**Suggested prompt for another AI:**
> "Implement [Phase X] from MAIN_GAME_AAA_UPGRADE_PLAN.md in this Godot project. Follow the technical details and file paths specified. Make the changes incrementally and test as you go."

---

## Current State Assessment

The main_game is a polished 2D side-scrolling platformer (Shantae-style) with:

- **Graphics**: post_cinematic.gdshader (bloom, cel, edge detection, lens distortion), parallax backdrop, toon lighting, occlusion silhouettes, weapon trails
- **Gameplay**: combo melee, grapple, wall jump, air dash, ground pound, block/parry, sprint
- **Systems**: FXManager event bus, spawn director, checkpoint/shop, themes (grass, cave, sky, summit, lava, ice)

---

## Phase 1: Advanced Rendering Pipeline (Graphics Team)

**Scope**: GPU-first rendering, multi-pass effects, deferred lighting simulation, HDR workflow.

### 1.1 Multi-Pass Post-Process Pipeline

**Technical**: Godot 4.x supports `SubViewport` + `CanvasLayer` for custom pipelines. Replace single-pass `post_cinematic.gdshader` with a 3-pass chain:

- **Pass 1 - Extract & Bloom**: Render to SubViewport, extract brights (Luma > 0.6), dual-kawase bloom blur at 2 resolutions (half-res + quarter-res), additive blend back.
- **Pass 2 - Tonemap & Color**: ACES/Reinhard hybrid, per-theme LUT (256x16 strip) for color grading instead of lift/gamma/gain math. Load LUT from theme config.
- **Pass 3 - Final**: Edge detection (Sobel), chromatic, vignette, film grain, scanlines—all in one pass for efficiency.

**Files**: Create `main_game/systems/post_process_pipeline.gd` with SubViewports; refactor `main_game/systems/post_process_layer.gd` to orchestrate passes. Add `assets/luts/` with per-theme .png LUTs.

### 1.2 HDR-Like Brightness Range

**Technical**: 
- Bloom threshold at 0.35 (allow more bright overflow)
- Exposure slider 0.8–1.4 driven by scene brightness (parallax sky vs. cave)
- Tone mapping curve with shoulder for highlights (ACES already in shader—extend parameters)

**Files**: `assets/shaders/post_cinematic.gdshader` — add `exposure_curve` uniform for highlight rolloff.

### 1.3 Resolution Scaling & Quality Tiers

**Technical**: Godot 4's `stretch_mode` + `scale` for internal resolution. Add runtime quality tiers:
- Ultra: 1.0 scale, full bloom radius
- High: 0.95 scale
- Medium: 0.9 scale, reduced bloom samples

Temporal smoothing: cache previous frame, blend 10% for motion blur reduction at 60fps.

**Files**: `project.godot` stretch settings; new `main_game/systems/quality_manager.gd` for tier switching.

---

## Phase 2: Environmental Art & Atmosphere (Art + Tech Art)

**Scope**: Parallax depth, dynamic lighting, weather, volumetric effects.

### 2.1 Multi-Layer Parallax Overhaul

**Technical**: Current `main_game/map/parallax_backdrop_v2.gd` uses procedural `_fill_rect` for hill silhouettes. Upgrade:
- **5–7 layers** with distinct motion scales: 0.0 (sky), 0.08, 0.2, 0.4, 0.65, 0.85, 0.98 (foreground)
- **Sprite-based layers** for far/mid: Import or procedurally generate hill/cave/sky assets (PNG), tile horizontally with `texture_repeat`
- **Foreground layer**: Semi-transparent foliage/particles moving at 0.98 scale. Use `GPUParticles2D` with `emitting = true`, `amount = 20`, theme-colored.

**Files**: `main_game/map/parallax_backdrop_v2.gd`; add `assets/parallax/` for layer textures.

### 2.2 Dynamic Time-of-Day & Atmospheric Scattering

**Technical**: `main_game/map/lighting_system.gd` has `time_of_day` and `update()` but is not wired. Integrate:
- Expose `time_of_day` (0–1) in main_game, advance at 0.02/min (optional) or per-level config
- Sky gradient: `lerp(midnight_color, noon_color, sin(time * PI))` in parallax sky layer
- Horizon tint: Warm at dawn/dusk, cool at noon. Pass `time_of_day` to post-process for `warm_tint`/`cool_tint` interpolation
- Far parallax layers: `modulate = Color(1, 1, 1, 0.85)` and slight blue tint at distance

**Files**: `main_game/map/parallax_backdrop_v2.gd`, `main_game/systems/post_process_layer.gd`, `main_game/main_game.gd`

### 2.3 Weather & Ambient Particles

**Technical**:
- **Rain/Snow/Dust**: `GPUParticles2D` with `sub_emitter` for splash. Rain: 500 particles, `direction = Vector2(0, 1)`. Theme-gated (rain in grass, dust in lava).
- **Floating motes**: Expand `main_game/fx_draw_node.gd` `_draw_ambient_particles` — increase `MAX_AMBIENT_PARTICLES` to 80, add depth layers, theme-specific colors.
- **Light shafts (god rays)**: Shader-based radial blur. Single fullscreen pass: sample along ray from light_pos, accumulate brightness.

**Files**: New `main_game/systems/weather_system.gd`; `main_game/fx_draw_node.gd`; new `assets/shaders/light_shaft.gdshader`.

### 2.4 Procedural Terrain Detail

**Technical**: `main_game/map/linear_map.gd` draws grass tufts, rocks, plants. Enhance:
- **Normal map variation**: Add 2–3 variants, sample by `(floor(x/64) + floor(y/64)) % 3` for tile variation
- **Decal-like overlays**: Crack/dirt/stain textures (32x32) at floor corners
- **Grass density**: Increase tuft count 1.5x, add secondary layer. Wind: add `cos(anim_time * 1.2) * 1.5` for secondary motion

**Files**: `main_game/map/linear_map.gd`, `main_game/map/terrain_texture_generator.gd`.

---

## Phase 3: Character & Animation (Animation + Tech)

**Scope**: Skeletal animation feel, squash-and-stretch, procedural motion, impact frames.

### 3.1 Animation State Machine Upgrade

**Technical**: Player uses `Sprite2D` + `SpriteAnimator` / `SpriteFrameLoader`. Upgrade:
- **State machine**: Explicit `AnimationState` enum (IDLE, WALK, SPRINT, JUMP_ASCEND, JUMP_FALL, LAND, MELEE_ANTICIPATE, MELEE_STRIKE, MELEE_RECOVERY, DASH, GROUND_POUND, GRAPPLE, BLOCK, HURT, DEATH)
- **Blend times**: 0.05s blend between WALK↔SPRINT. Store `prev_state`, `transition_t` in player
- **Animation events**: Callbacks at strike frame. Add `on_land_frame`, `on_dash_start_frame` for FX sync

**Files**: `karen_defense/entities/player.gd`; `main_game/systems/sprite_animator.gd`.

### 3.2 Procedural Squash & Stretch

**Technical**: `main_game/systems/character_visual.gd` receives transform. Add:
- **Squash on land**: `scale.y = 0.7, scale.x = 1.3` for 2 frames post-land, spring back to 1.0
- **Stretch on jump**: `scale.y = 1.15, scale.x = 0.9` during ascend
- **Strike anticipation**: `scale.x = 0.95` in ANTICIPATE, snap to `1.1` on STRIKE
- **Implementation**: `squash_stretch_scale: Vector2` in CharacterVisual, entity passes `{ "squash": 1.2, "axis": "y" }` on landing

**Files**: `main_game/systems/character_visual.gd`, `karen_defense/entities/player.gd`.

### 3.3 Hit React & Knockback Polish

**Technical**: Add to enemies:
- **Hit react animation**: 1–2 frame "flinch" or `rotation = 0.1` for 0.05s
- **Knockback smoothing**: `knockback_velocity` that decays over 0.15s
- **Stagger tiers**: Light hit = small knockback; heavy (combo 3, crit) = larger knockback + 0.1s stun

**Files**: `karen_defense/entities/enemy.gd`; `karen_defense/systems/combat_system.gd`.

### 3.4 Dissolve & Death Variety

**Technical**: `main_game/systems/character_visual.gd` has `dissolve_material`. Expand:
- **Dissolve direction**: Top-down vs. center-outburst. Add `dissolve_origin` uniform
- **Death types**: "poof", "explode", "freeze" (ice shatter—different shader)
- **Ragdoll-style fall**: For larger enemies, brief downward + horizontal velocity, 0.3s, then dissolve

**Files**: `main_game/systems/character_visual.gd`, `assets/shaders/dissolve.gdshader`; enemy config for `death_type`.

---

## Phase 4: Combat & VFX (VFX + Design)

**Scope**: Hit feedback, screen feel, particle systems, impact clarity.

### 4.1 Hitstop & Screen Shake Curves

**Technical**: `main_game/main_game.gd` has `start_hitstop(duration, intensity)`. Enhance:
- **Per-hit-type curves**: Light = 0.02s, 0.5x; Medium = 0.04s, 1.0x; Heavy = 0.08s, 1.5x; Finisher = 0.12s, 2.0x
- **Shake falloff**: Per-axis decay: vertical 1.2x for landings, horizontal 1.0x for melee
- **Rumble**: `Input.start_joy_vibration(0, weak, strong, duration)` — hit: 0.3/0.5; finisher: 0.6/0.8

**Files**: `main_game/main_game.gd`, `main_game/systems/fx_manager.gd`.

### 4.2 Particle System Overhaul

**Technical**:
- **GPU particles**: Migrate to `GPUParticles2D` for 500+ particles (explosions, death bursts). Keep CPU for small counts
- **Sub-emitters**: Death burst spawns embers on expiration
- **Color over lifetime**: Gradient from hit_color to transparent

**Files**: Locate ParticleSystem; create `main_game/systems/gpu_particle_emitter.gd` wrapper.

### 4.3 Impact Distortion & Flash

**Technical**:
- **Directional warp**: `uv += direction * strength * falloff` for directional "push" from hit
- **Multi-point impacts**: Support 2 simultaneous impact centers
- **Crit screen flash**: Fullscreen 1-frame at 0.15 alpha for crits via FXManager

**Files**: `assets/shaders/post_cinematic.gdshader` — add `impact_direction` uniform; `main_game/systems/fx_manager.gd`.

### 4.4 Weapon Trail & Afterimage

**Technical**:
- **Ribbon mesh**: Use `Polygon2D` or `Line2D` with `width_curve` for taper. Sample 12 points, build triangulated ribbon
- **Dash afterimage**: Player leaves 3–4 fading sprites (alpha 0.7→0). Store in `dash_trail` array
- **Combo trail persistence**: Extend trail lifetime to 0.4s for finisher; thicker base (12px)

**Files**: `main_game/systems/weapon_trail_manager.gd`, `main_game/systems/trail_renderer.gd`; `karen_defense/entities/player.gd`.

---

## Phase 5: Level Design & Progression (Design + Systems)

**Scope**: Segment flow, pacing, secrets, narrative beats.

### 5.1 Segment Pacing & Spawn Tuning

**Technical**: `main_game/systems/spawn_director.gd`. Enhance:
- **Per-segment spawn config**: `spawn_density`, `enemy_pool`, `max_concurrent`
- **Pacing curve**: Level-level `intensity_curve`: array of `{x_min, intensity}`. E.g. intro=0.5, mid=1.0, boss_approach=1.3
- **Safe zone**: 80px around checkpoint, no spawns. Extend recovery window to 15s

**Files**: `main_game/systems/spawn_director.gd`; `main_game/map/linear_map.gd` level_config.

### 5.2 Secret Areas & Optional Paths

**Technical**:
- **Hidden passages**: `obstacle_rects` with `can_destroy = true`. Dash or ground pound breaks destructible wall. Add `WallSegment` with `hp`, `destroy_effect`
- **Alternate routes**: Vertical splits—upper (platforms) vs. lower (more enemies, gold). `path_type: "high" | "low" | "main"`
- **Collectibles**: Keys for locked doors. `LevelLock` node, `key_count >= required`

**Files**: `main_game/map/linear_map.gd`; new `level_door.gd`, `level_destructible.gd`.

### 5.3 Checkpoint & Economy Depth

**Technical**:
- **Tiered shop**: First checkpoint = basic; later = advanced (lifesteal, magnet, double jump). Use `checkpoint_index` to gate
- **Permanent vs. run upgrades**: Split `Progression` (persistent) and run modifiers (consumed at shop)
- **Risk/reward**: "Curse" items (+50% damage taken, +40% gold). Store in `ChallengeManager` modifiers

**Files**: `main_game/systems/checkpoint_manager.gd`; shop UI; `main_game/autoload/main_game_manager.gd`.

---

## Phase 6: AI & Gameplay Systems (Gameplay + AI)

**Scope**: Enemy behavior, encounter design, player feel.

### 6.1 Enemy AI Behavior Trees

**Technical**:
- **Behavior tree**: Root `Selector` (Aggressive | Defensive | Retreat). Aggressive: `Sequence`(InRange → Attack, else MoveToward). Defensive: Block if player attacking
- **Blackboard**: Shared `{ target, last_known_pos, health_ratio }`
- **Variants**: Melee rusher, ranged kiter, heavy slow—each with different BT roots

**Files**: `karen_defense/entities/enemy.gd`; create `karen_defense/ai/behavior_tree.gd`; `enemy_behaviors/` for per-type trees.

### 6.2 Encounter Design & Formation Spawning

**Technical**:
- **Formations**: `spawn_formation: "line" | "surround" | "ambush"`
- **Triggers**: `{ x: 1200, event: "spawn_formation", formation: "ambush", enemies: ["grunt", "ranged"] }`. SpawnDirector checks `player_x >= trigger.x` once
- **Wave mode**: Arena segments: spawn N, wait for all dead, next wave

**Files**: `main_game/systems/spawn_director.gd`; level_config `triggers`, `waves`.

### 6.3 Grapple & Movement Polish

**Technical**:
- **Swing physics**: Centripetal force + tangential velocity when attached. `velocity = tangent * swing_speed`; `swing_speed` increases with input
- **Release boost**: Add velocity in grapple direction * 1.5 (catapult feel)
- **Chain visual**: Catmull-Rom spline from player to anchor. 8 segments, 3px width, gradient alpha
- **Coyote & buffer**: `COYOTE_TIME = 0.18`, `JUMP_BUFFER_TIME = 0.22`

**Files**: `karen_defense/entities/player.gd`; `main_game/map/linear_map.gd` chain link draw.

### 6.4 Camera & Framing

**Technical**:
- **Boss frame**: When boss detected, camera pulls back 1.2x zoom, centers between player and boss
- **Danger framing**: 4+ enemies on screen → slight zoom out (0.95x)
- **Smooth zoom**: Spring-damped, no snapping

**Files**: `main_game/main_game.gd`; `main_game/systems/boss_manager.gd`.

---

## Phase 7: Audio & Haptics (Audio + UX)

**Scope**: Dynamic music, spatial audio, haptics, UI sound.

### 7.1 Dynamic Music System

**Technical**:
- **Stems**: Background (ambient), Percussion (combat), Melody (intensity). `AudioStreamPlayer` for each, crossfade
- **Intensity driver**: `combat_intensity = near_enemies * 0.2 + (1 - hp_ratio) * 0.3`. Fade percussion in over 2s when intensity > 0.5

**Files**: New `main_game/systems/music_controller.gd`; `main_game/main_game.gd`.

### 7.2 Spatial Audio

**Technical**: `AudioStreamPlayer2D` for positional SFX (enemy attacks, environmental). `AudioStreamPlayer` for UI, music. Projectile hit, gold pickup at position. Ambient: cave drip, grass rustle—low volume, 2D at fixed positions.

**Files**: KarenSfxPlayer; create `main_game/systems/audio_manager.gd` if needed.

### 7.3 Haptic Feedback

**Technical**: `Input.start_joy_vibration(device_id, weak, strong, duration)`.
- Hit: 0.2/0.4, 0.03s | Crit: 0.4/0.7, 0.06s | Land: 0.15/0.3, 0.02s | Dash: 0.1/0.25, 0.04s

**Files**: `main_game/systems/fx_manager.gd`; `karen_defense/entities/player.gd` for land/dash.

---

## Phase 8: Polish & Performance (Tech + QA)

**Scope**: Frame pacing, loading, debugging, accessibility.

### 8.1 Frame Pacing

**Technical**: Delta smoothing: `smoothed_delta = lerp(prev_delta, raw_delta, 0.2)`. Profiling: `Performance.get_monitor(TIME_PROCESS)` to debug HUD; flag when > 14ms.

**Files**: `main_game/main_game.gd`; debug overlay.

### 8.2 Loading & Streaming

**Technical**: Preload critical (player, map, post_process, FXManager). Parallax textures: `ResourceLoader.load_threaded_request`. Level chunks: load chunk N+1 when camera.x > chunk_N.x + 400.

**Files**: `main_game/main_game.gd`; new `main_game/systems/streaming_loader.gd`.

### 8.3 Accessibility

**Technical**: Color-blind LUT swap. Subtitles for SFX. Reduce motion: `shake_intensity *= 0.3`, `hitstop_duration *= 0.5`, speed lines off. Options menu toggle.

**Files**: `main_game/main_game.gd`; settings; `main_game/systems/post_process_layer.gd`.

### 8.4 Debug & Cheat Tools

**Technical**: F3 = FPS, entity count, spawn pressure, camera target. Cheats: `debug_invincible`, `debug_one_hit_kill`, `debug_slow_mo`. Guard with `OS.is_debug_build()`.

**Files**: New `main_game/systems/debug_overlay.gd`; `main_game/main_game.gd`.

---

## Priority Order for Implementation

1. **Phase 4** (Combat/VFX) — Highest player impact
2. **Phase 1** (Rendering) — Visual foundation
3. **Phase 3** (Character) — Animation feel
4. **Phase 2** (Environment) — Atmosphere
5. **Phase 6** (AI/Gameplay) — Depth
6. **Phase 5** (Level Design) — Content
7. **Phase 7** (Audio) — Immersion
8. **Phase 8** (Polish) — Ongoing

---

## Estimated Effort

| Phase | Focus | Est. Dev-Weeks |
|-------|-------|----------------|
| 1 | Rendering | 8 |
| 2 | Environment | 10 |
| 3 | Character/Anim | 6 |
| 4 | Combat/VFX | 8 |
| 5 | Level Design | 6 |
| 6 | AI/Gameplay | 8 |
| 7 | Audio | 4 |
| 8 | Polish | 6 |
| **Total** | | **~56 dev-weeks** |
