# AAA Visual & Presentation Upgrade — Master Plan

## Vision
Transform the Main Game from **browser-level indie prototype** to **premium indie title approaching AAA presentation quality** — suitable for a $30 Steam release.

**Target Reference:** Hollow Knight, Shantae, Ori, Dead Cells — premium 2.5D side-scrollers with cinematic presentation.

---

## Implementation Phases

### Phase 1: Camera & Perspective (Critical)
**Goal:** True cinematic side-view; clear 3D depth; professional camera feel.

| Task | Status | Files |
|------|--------|-------|
| Increase camera perspective tilt (stronger depth illusion) | ✅ Done (0.28) | main_game.gd |
| SubViewport + tilted Camera2D for pseudo-3D projection | Pending | New: SubViewport wrapper |
| Enhanced FOV / zoom for dimensionality | ✅ Done (zoom 0.92 = wider FOV) | main_game.gd |
| Dynamic camera: combat zoom-in, landing pulse | ✅ Done | main_game.gd |
| Depth parallax (Y-based layer movement) | ✅ Done | parallax_backdrop.gd, DepthPlanes |
| Screen shake on impactful moments | ✅ Done | main_game.gd |
| Smooth spring-damped follow | ✅ Done | main_game.gd |
| Stronger velocity-based camera tilt (0.12 rad max) | ✅ Done | main_game.gd |
| Always-on subtle vignette for cinematic framing | ✅ Done | main_game.gd, fx_draw_node.gd |

### Phase 2: Environment & Level Art
**Goal:** Handcrafted feel; immersive depth; consistent art direction.

| Task | Status | Files |
|------|--------|-------|
| Terrain materials (higher-fidelity textures) | Partial | linear_map.gd, TerrainTextureGenerator |
| Theme-specific color palettes | ✅ Done | linear_map.gd, parallax_backdrop.gd |
| Background depth layers with parallax | ✅ Done | parallax_backdrop.gd |
| Depth fog for background separation | ✅ Done | parallax_backdrop.gd |
| Environmental storytelling (props, silhouettes) | Partial | linear_map.gd decor |
| Floor/ceiling terrain fill | ✅ Done | linear_map.gd |
| Contrast and color grading | In Progress | fx_draw_node.gd |

### Phase 3: Characters — 2.5D Enhancement
**Goal:** Premium character presence; dimensionality; life.

| Task | Status | Files |
|------|--------|-------|
| 2.5D shading (depth-based lighting) | Pending | player.gd, enemy.gd (Main Game context) |
| Character lighting interaction | Pending | LightingSystem integration |
| Silhouette readability | Pending | Outline shader or draw pass |
| Idle animations (breathing, stance) | Partial | player.gd (walk_anim, idle) |
| Hit reactions (flash, knockback) | ✅ Done | player.gd, enemy.gd |
| Depth-scaled shadows | ✅ Done | DepthPlanes, entity _draw |

### Phase 4: Combat Feel & Flow
**Goal:** Weighty, satisfying, responsive combat.

| Task | Status | Files |
|------|--------|-------|
| Hit feedback (impact frames, VFX, sound sync) | Partial | combat_system.gd, fx_manager.gd |
| Impact flashes on all hits | In Progress | combat_system.gd |
| Hitstop / slow-mo on heavy hits | ✅ Done | main_game.gd |
| Screen shake by impact type | ✅ Done | main_game.gd |
| FXManager pipeline integration | In Progress | combat_system → FXManager |
| Damage number polish (bounce, scale) | ✅ Done | main_game.gd |
| Critical strike VFX (chromatic, bloom) | ✅ Done | main_game.gd |

### Phase 5: Animation Polish
**Goal:** Fluid, intentional movement; no indie stiffness.

| Task | Status | Files |
|------|--------|-------|
| Ease curves (replace linear) | Partial | player.gd, enemy.gd |
| Secondary motion (cloth, weapon follow) | Pending | Entity draw |
| State transition smoothing | Partial | player.gd |
| Landing squash/recovery | ✅ Done | player.gd |
| Attack anticipation frame | ✅ Done | player.gd |
| Spawn-in / death animations | Partial | enemy.gd |

### Phase 6: Lighting & Post-Processing
**Goal:** Depth communication; atmosphere; premium look.

| Task | Status | Files |
|------|--------|-------|
| Dynamic lighting (directional) | Partial | linear_map.gd, LightingSystem |
| Bloom (controlled) | ✅ Done | fx_draw_node.gd |
| Color grading (theme-aware) | In Progress | fx_draw_node.gd |
| Vignette (light usage) | ✅ Done | fx_draw_node.gd |
| Depth fog | ✅ Done | parallax_backdrop.gd |
| Film grain | ✅ Done | fx_draw_node.gd |
| Light rays / god rays | ✅ Done | fx_draw_node.gd |
| Ambient particles | ✅ Done | fx_draw_node.gd |

---

## Architecture Notes

### FX Pipeline
- **FXManager** — Central coordinator for land, jump, attack_hit, dash, death, grapple
- **main_game** — Hosts: start_shake, start_hitstop, spawn_damage_number, spawn_impact_flash, trigger_bloom, trigger_camera_zoom_pulse
- **combat_system** — Currently calls game methods directly; should emit via FXManager for consistency

### Depth System
- **DepthPlanes** — Y → depth factor, scale, shadow alpha/scale, parallax factor
- **ParallaxBackdrop** — Uses `DepthPlanes.get_parallax_factor_for_y()` for player-Y-based parallax
- **Entities** — Use DepthPlanes for scale and shadow (player.gd, enemy.gd, ally.gd)

### Rendering
- **2D Canvas** — No 3D; premium feel via post-processing and 2.5D tricks
- **FXDrawNode** — Full-screen effects on CanvasLayer 15
- **SubViewport** — Optional for camera tilt (Phase 1 advanced)

---

## Files Modified (This Upgrade)

| File | Changes |
|------|---------|
| main_game/main_game.gd | Camera tuning, vignette baseline, FOV |
| main_game/fx_draw_node.gd | Color grading, vignette, bloom tuning |
| main_game/map/parallax_backdrop.gd | Depth fog, parallax refinement |
| main_game/systems/combat_system.gd | FXManager integration, impact on hit 1 |
| main_game/systems/fx_manager.gd | New events, theme-aware intensity |
| project.godot | Rendering settings if needed |

---

## Success Criteria

1. **First impression:** Camera and depth read as "premium" within 5 seconds
2. **Combat:** Every hit feels weighted; crits feel explosive
3. **Environment:** Levels feel handcrafted, not procedural
4. **Atmosphere:** Lighting and post-processing sell mood
5. **Polish:** No obvious "indie stiffness" — movement feels intentional
