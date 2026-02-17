# Main Game Visual Overhaul - 9/10 Ambition

## Current State Analysis

The main game already has substantial visual infrastructure, but critical systems are **built but not integrated**:

- **PostProcessSimple** is used; the full 6-pass **PostProcessLayer** (bloom, tonemap, cel, distort, perspective, LUT) exists but is not used
- **ParallaxBackdrop** (monolithic `_draw()`) is used; **ParallaxBackdropV2** (5-layer ParallaxBackground) exists but is not used
- **WeaponTrailManager** (GPU ribbon trails) exists but is never instantiated; player uses simpler `combo_visual_trails` data
- **CharacterVisual** is integrated (player, enemy, ally) with toon shaders
- Combat already triggers: particles, impact flash, damage numbers, hitstop, shake

The overhaul focuses on **game logic that drives visuals**, not cosmetic overlays.

---

## Phase 1: Integrate Existing Premium Systems (Foundation)

**Goal:** Activate systems that exist but are unused. Immediately noticeable depth and combat punch.

### 1.1 ParallaxBackdropV2 Migration

**File:** main_game/main_game.gd — `_build_scene_tree()` (~line 139)

- Replace `ParallaxBackdrop.new()` with `ParallaxBackdropV2.new()`
- ParallaxBackdropV2 extends `ParallaxBackground` and requires being added as child of a viewport-following node; verify scene tree (game_layer or root) so layers scroll correctly with camera
- ParallaxBackground expects `ParallaxLayer` children; V2 creates 5 layers: Sky (0), Far (0.15), Mid (0.4), Near (0.65), Foreground (0.92)

**Impact:** Structured parallax with distinct far/mid/near hills instead of single monolithic gradient. Clearly different look from first frame.

### 1.2 WeaponTrailManager Integration

**Files:** main_game/main_game.gd, karen_defense/entities/player.gd

- In `main_game.gd` `_build_scene_tree()`: add `weapon_trail_manager = WeaponTrailManager.new()`, call `setup(self)`, `add_child(weapon_trail_manager)`
- In `main_game.gd` `_process()`: add `weapon_trail_manager.update(delta)` (inside LEVEL_ACTIVE branch)
- In `player.gd` `spawn_combo_visual()`: compute weapon start/end from `position`, `facing_angle`, `melee_range`; call `game.weapon_trail_manager.spawn_weapon_trail(start, end, hit_index)` **instead of** only appending to `combo_visual_trails`
- Optionally keep `combo_visual_trails` for fallback or remove once trails are verified

**Impact:** GPU polyline ribbons with combo colors (white→blue→orange) replace lightweight arc/line/vortex data. Combat reads much more impactful.

### 1.3 Full PostProcess Pipeline (PostProcessLayer)

**Files:** main_game/main_game.gd, main_game/systems/post_process_layer.gd

- Verify PostProcessLayer uses SubViewport to render game first, then applies 6-pass chain (bloom → tonemap → cel → distort → perspective → LUT)
- Replace `PostProcessSimple.new()` with `PostProcessLayer.new()` in `_build_scene_tree()`
- Ensure `post_process.setup(self)` and `post_process.set_theme(...)` work with PostProcessLayer API
- PostProcessSimple uses single `post_working.gdshader`; PostProcessLayer uses multiple shader passes — different setup

**Impact:** Proper cel-shading, bloom, perspective warp, impact distortion. Requires validating PostProcessLayer works in Godot 4 with SubViewport; if not, enhance PostProcessSimple with cel+perspective from existing shaders instead.

---

## Phase 2: Game-State-Driven Environment Reactivity

**Goal:** World reacts to player. Requires new logic in map and entity systems.

### 2.1 Grass/Foliage Bend on Player Proximity

**File:** main_game/map/linear_map.gd — `_draw()` (~line 778)

- In the grass-tuft loop (lines 778–794): for each tuft, compute `dist = player_pos.distance_to(tuft_pos)` and `bend_angle = lerp(0, -0.4, 1.0 - clamp(dist/80, 0, 1))`
- Use `anim_time` + per-tuft seed for idle sway; add bend when player is within ~80px
- Requires `game.player_node.position` (or camera-follow target) passed into draw or cached in `anim_time`-style update

**Implementation:** Add `_update_decor_bend(delta)` that caches player position; pass to `_draw()` via member vars (e.g. `_grass_bend_map` or inline in draw loop with `game.player_node`).

### 2.2 Landing Dust Clouds

**Files:** karen_defense/entities/player.gd, main_game/main_game.gd

- In `player.gd` landing logic (e.g. `was_on_ground = false`, `is_on_ground = true` transition): detect hard landing (e.g. `velocity.y > 300` before snap)
- Call `game.particles.emit_burst(position.x, position.y, dust_color, count)` or new `emit_landing_dust(pos, vel_mag)` that spawns wider, softer particles
- Add particle shape/config for "dust cloud" (wider radius, slower rise, theme-based color)

**Impact:** Clear feedback for landings; world feels responsive.

### 2.3 Water/Pit Edge Ripples (Theme-Dependent)

**File:** main_game/map/linear_map.gd

- For grass theme: define "water edge" positions (e.g. from `_decor_pipes` with `has_water`, or explicit config)
- When player position is within ~40px of water edge and just landed, add a "ripple" marker with timer
- In `_draw()`: for each active ripple, draw expanding concentric circles with decreasing alpha
- Store `_ripples: Array[{pos, timer, max_timer}]`; update in `_process` or via `anim_time`-style tick

**Impact:** Subtle but noticeable when player lands near drains/pipes. Skip for cave/summit/ice if no water.

---

## Phase 3: Depth Occlusion and Silhouettes

**Goal:** Entities behind platforms get distinct treatment. Pure visual logic.

### 3.1 Occlusion Detection

**File:** main_game/main_game.gd or new main_game/systems/occlusion_manager.gd

- Each frame, for each entity (player, enemies, allies): test if `entity.position.y` is above platform `rect.position.y` (standing on) vs below (under platform)
- Use `map.platform_rects` and `map.platform_collision_rects`; for each platform, define "occlusion band" (platform bottom to some offset below)
- If entity center is in occlusion band and to the left/right of platform x-bounds, mark as `occluded`

### 3.2 Silhouette Rendering

**Files:** main_game/systems/character_visual.gd, karen_defense/entities/player.gd

- Add `is_occluded: bool` to CharacterVisual (or entity); set by OcclusionManager each frame
- When occluded: either (a) reduce modulate to dark tint (0.4, 0.4, 0.5), or (b) swap to silhouette shader (solid dark with rim)
- Player, enemies, allies must read `game.occlusion_manager.get_occlusion(entity)` and pass to CharacterVisual

**Impact:** Clear depth hierarchy; character "goes into shadow" when under platforms.

---

## Phase 4: Dynamic Lighting from Game Events

**Goal:** Lights respond to gameplay, not just static theme.

### 4.1 Checkpoint and Goal Light2Ds

**Files:** main_game/systems/checkpoint_manager.gd, main_game/map/linear_map.gd

- At checkpoint positions: add `PointLight2D` or `DirectionalLight2D` as child of entity_layer (or dedicated lights node)
- Light color: warm (e.g. 1, 0.9, 0.7); energy/radius tuned for 1280x720
- At goal: similar light, possibly pulsed (sin `anim_time`) for "active" feel
- Requires Light2D to work with 2D canvas; Godot 4 supports this. Ensure world is in CanvasItem that receives light.

### 4.2 Hit Flash Lights

**File:** main_game/main_game.gd or FXManager

- On `spawn_impact_flash()` or when `start_hitstop(intensity > 1.0)`:
  - Spawn ephemeral PointLight2D at hit position
  - Life span ~0.15–0.2s; energy decays to 0
  - Or: drive a single "impact light" position + energy in a custom light node
- Requires combat_system or main_game to have access to a light spawner

### 4.3 Dash Trail Glow

**File:** karen_defense/entities/player.gd

- During `is_dashing`: add trailing lights (or enhanced trail particles with glow)
- Simpler: ensure dash trail (`trail_history` / TrailRenderer) uses bright color; post-process bloom will pick it up
- Heavier: spawn short-lived PointLight2D every 2–3 frames along dash path

---

## Phase 5: Animated Terrain (Theme-Specific)

**Goal:** Terrain feels alive. Logic in LinearMap.

### 5.1 Grass Rustle

**File:** main_game/map/linear_map.gd — grass tuft drawing

- Use `anim_time` with per-tuft phase: `phase = seed * 0.1 + anim_time`
- Sway offset: `offset_x = sin(phase) * 2`, `offset_y = cos(phase * 0.7) * 1`
- Already has `rng2.seed` per position; use for phase variance

### 5.2 Lava Bubbling

**File:** main_game/map/linear_map.gd

- For lava theme: in pit drawing or floor fill, add overlay with circular "bubbles"
- Store `_lava_bubbles: Array[{x, y, phase, radius}]` — built once in `_build_procedural_decor` or similar
- In draw: for each bubble, `scale = 0.3 + 0.7 * (sin(anim_time * 3 + phase) * 0.5 + 0.5)`
- Draw small circles with orange/red tint and alpha pulse

### 5.3 Cave Crystal Glow

**File:** main_game/map/linear_map.gd

- Cave theme decor: add crystal positions with `_decor_crystals`
- Draw with `Color(0.6, 0.8, 1.0, 0.3 + 0.2 * sin(anim_time * 2 + seed))`
- Optional: small PointLight2D per crystal for stronger glow

---

## Phase 6: Combat Visual Event Bus (Logic Centralization)

**Goal:** Every combat event flows through one pipeline for consistent, noticeable feedback.

### 6.1 Centralize Combat→Visual Triggers

**File:** New main_game/systems/combat_visual_bus.gd or extend main_game/systems/fx_manager.gd

- Define events: `MELEE_HIT`, `MELEE_CRIT`, `COMBO_FINISHER`, `ENEMY_DEATH`, `PROJECTILE_HIT`, `BLOCK_PARRY`
- Each event carries: position, direction, intensity, combo_index, is_crit
- Subscribers: particles, impact flash, damage numbers, hitstop, shake, camera zoom, weapon trail, bloom, chromatic
- CombatSystem and enemy.take_damage() emit to bus instead of calling game methods directly

### 6.2 Full Event Chain Per Hit

- `MELEE_HIT` → particles + impact_flash + damage_number + hitstop + shake + weapon_trail + (combo-specific) bloom/chromatic
- `MELEE_CRIT` → add crit ring, stronger chromatic, yellow particles
- `COMBO_FINISHER` → camera zoom pulse, larger impact ring, stronger distortion
- Ensures no hit feels "empty"; logic is in one place

---

## Phase 7: Entity Squash-Stretch from Physics

**Goal:** Animation driven by real velocity/impact.

### 7.1 Velocity-Based Stretch

**File:** karen_defense/entities/player.gd

- In `_update_squash()` or CharacterVisual update: derive stretch from `velocity`
- Horizontal: `stretch_x = 1.0 + clamp(velocity.x / 500, -0.15, 0.15)` (stretch when moving fast)
- Vertical: `stretch_y = 1.0 - clamp(velocity.y / 800, 0, 0.2)` when falling (squash)
- Combine with existing squash_factor from landing; use max of both

### 7.2 Hit Reaction from Damage Magnitude

**File:** karen_defense/entities/enemy.gd

- On `take_damage(dmg)`: compute `impact_strength = clamp(dmg / 30.0, 0.5, 2.0)`
- Pass to CharacterVisual or sprite: brief scale pulse (1.0 → 1.1 → 1.0) over ~0.1s
- Or: knockback direction influences squash direction (compress along hit direction)

---

## Suggested Implementation Order

1. **Phase 1.1** — ParallaxBackdropV2 (fast, very visible)
2. **Phase 1.2** — WeaponTrailManager (immediate combat upgrade)
3. **Phase 2.2** — Landing dust (quick win)
4. **Phase 2.1** — Grass bend (moderate)
5. **Phase 1.3** — PostProcessLayer (verify first; fallback to enhanced Simple)
6. **Phase 3** — Occlusion/silhouette
7. **Phase 4.1** — Checkpoint lights
8. **Phase 5** — Animated terrain
9. **Phase 6** — Combat event bus
10. **Phase 4.2–4.3, 7** — Hit lights, dash glow, physics squash (polish)

---

## Files Touched Summary

| File | Changes |
|------|---------|
| main_game/main_game.gd | ParallaxBackdropV2, WeaponTrailManager, occlusion update loop |
| main_game/map/linear_map.gd | Grass bend, ripples, lava bubbles, crystal glow |
| main_game/systems/checkpoint_manager.gd | Light2D at checkpoints |
| karen_defense/entities/player.gd | WeaponTrailManager calls, landing dust, optional squash from velocity |
| karen_defense/entities/enemy.gd | Hit reaction scale, occlusion query |
| karen_defense/systems/combat_system.gd | Optional bus emit or keep direct calls |
| main_game/systems/character_visual.gd | Occlusion modulate/silhouette |
| main_game/systems/occlusion_manager.gd | **New** — occlusion detection |
| particle_system.gd | `emit_landing_dust()` if needed |
| main_game/systems/post_process_layer.gd | Verify SubViewport pipeline for main_game |

---

## Success Criteria

- **First 5 seconds:** ParallaxV2 depth + grass sway + environment clearly different from current build
- **Combat:** Weapon trails + landing dust + occlusion when under platforms — unmistakable
- **Polish:** Checkpoint glow, animated lava/cave, hit-driven lights — world feels reactive
