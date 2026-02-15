# Visual, POV & Physics Upgrade Plan

## Goal
Transform the game's visuals and feel to be **more 3D, cartoony, and polished**—with smoother animations, better integration between systems, and physics that feel responsive and satisfying.

---

## 1. POV & Camera (3D Feel in 2D)

### Current State
- Flat 2D orthographic camera
- Subtle camera rotation (`camera_rotation_angle = 0.15`) for depth
- Linear lerp follow (6.0 speed)
- Y-based depth scaling (DepthPlanes: entities higher = smaller)

### Upgrades

#### 1.1 Fake 3D / Isometric POV
- **SubViewport + Camera2D tilt**: Increase rotation angle (0.15 → 0.25–0.35) for stronger top-down perspective; entities "back" (higher Y) appear smaller and flatter
- **Y-based scale gradient**: Smoother, continuous scaling instead of 4 discrete tiers—use `smoothstep` or `1.0 - (y / level_height) * 0.2` for gradual size
- **Shadow depth**: Shadows scale + fade based on Y; entities "in front" (low Y) get sharper, larger shadows

#### 1.2 Camera Feel
- **Ease-based follow**: Replace `lerp(delta * 6)` with `ease_out_expo` or spring-damped follow for smoother, less "floaty" camera
- **Lookahead momentum**: Camera anticipates movement direction with velocity-based offset (already partially done)
- **Zoom on landing/jump**: Subtle zoom pulse (0.98 → 1.02) on heavy landings; slight zoom-out at jump apex
- **Dead zone**: Configurable inner zone where camera doesn't micro-adjust (reduce jitter)

#### 1.3 Parallax Enhancement
- **More layers**: Add 1–2 mid-layer parallax elements (distant trees, clouds at different depths)
- **Parallax by Y**: Layers scroll at different rates based on player Y (simulate depth)
- **Depth fog**: Stronger fog gradient for distant elements (already partial in ParallaxBackdrop)

---

## 2. Visual Style (Cartoony & Polished)

### 2.1 Outline / Cel-Shading Look
- **Sprite outline**: Optional post-process or per-sprite outline (1–2px dark edge) for cartoony pop
- **Shadow softness**: Softer, rounded shadows instead of hard ellipses—use multi-layer gradient
- **Highlight band**: Subtle specular highlight on top of platforms/characters (top 10% lighter)

### 2.2 Lighting & Color
- **Directional light**: Single light from upper-left; entities and terrain darken toward bottom-right
- **Ambient occlusion**: Darken corners where floor meets wall; shadow under platforms
- **Color saturation**: Slightly boost saturation (1.05–1.1) for cartoony punch
- **Theme palettes**: Define saturated cartoony palettes per theme (grass = lush greens, sky = bright blues)

### 2.3 Visual Consistency
- **Unified shadow system**: All entities (player, enemies, allies) use same shadow logic—depth-based scale, soft falloff
- **Outline consistency**: Same outline color/width for all character sprites
- **Particle style**: Match particle colors to theme; use round/blobby shapes for cartoony feel

### 2.4 Terrain Fill (Floors & Ceilings)
- **Floor terrain fill**: Fill gaps between platforms and level bounds with terrain material (dirt, stone, grass) so floors read as solid ground rather than empty space
- **Ceiling terrain fill**: Extend walls/background up into a ceiling layer (cave rock, wooden beams, sky gradient) so vertical spaces feel enclosed and complete
- **Edge blending**: Smooth transitions where floor segments meet; use gradient or tile blends at seams
- **Theme-matched textures**: Terrain fill uses same palette as theme (e.g. grass theme → grass floor fill, cave theme → stone/cave floor)
- **Result**: Maps feel fully constructed and intentional, not like floating elements in void

---

## 3. Animation (Smoother & Juicier)

### 3.1 Entity Animation System
- **AnimationTree or StateMachine**: Migrate from procedural _draw to AnimationPlayer + Sprite2D for keyframe control (optional; more work)
- **Procedural improvements** (lower effort):
  - **Ease curves**: Replace linear `sin(t * PI)` with `ease_out_back`, `ease_out_elastic` for squash/stretch
  - **Spring physics**: Use damped spring for squash_factor, tilt, and bob—feels bouncier
  - **Blend timing**: Smoother transitions between idle/walk/attack (crossfade over 0.05–0.1s)

#### 3.2 Player-Specific
- **Landing**: Longer squash (0.6) with slower recovery; add small dust burst
- **Jump**: Smoother apex squash (1.12) with ease-in-out
- **Walk cycle**: Subtle hip sway + head bob (no feet lift—already fixed)
- **Attack anticipation**: Brief "wind-up" scale (0.9) before strike (0.05s)
- **Hit reaction**: Short stun flash + knockback ease-out

#### 3.3 Enemy/Entity
- **Spawn-in**: Scale from 0.8 → 1.0 with ease_out_back
- **Death**: Squash + fade; optional spin or wobble
- **Idle**: Subtle breathe/bob (amplitude 2–4px)

### 3.4 Platform & Environment
- **Platform sway**: Optional subtle horizontal drift on floating platforms (sin wave)
- **Background motion**: Clouds, water, grass sway at different speeds
- **Prop animation**: Plants, torches, chains animate on a loop

---

## 4. Physics Integration (Accurate & Responsive)

### 4.1 Collision & Ground
- **Sub-pixel snap**: Ensure ground snap uses `floor()` or `round()` for pixel-perfect alignment (avoid sub-pixel jitter)
- **Slope support**: Optional—allow ramps; adjust collision normal for slide
- **Edge detection**: Slight down-slope at platform edges to prevent "ledge grab" feel

### 4.2 Movement Feel
- **Coyote time**: Already exists; tune (0.1s) for comfort
- **Jump buffer**: Already exists; verify 0.15s feels responsive
- **Air control**: Slight increase in `AIR_CONTROL_MULT` (0.85 → 0.9) for snappier mid-air correction
- **Landing forgiveness**: Reduce harsh "stick" when landing on moving/platform edges

### 4.3 Visual–Physics Sync
- **Squash on land**: Match squash timing to actual impact frame (already close)
- **Grapple swing**: Smoother velocity integration; avoid sudden direction flips
- **Wall slide**: Add subtle spark particles; slow slide speed for readability

### 4.4 Hitstop & Feedback
- **Hitstop on strike**: 1–2 frame freeze on melee hit (already have hitstop_timer; verify integration)
- **Screen shake**: Tune intensity by impact type (light hit = 2px, heavy = 6px)
- **Controller rumble**: Optional; trigger on hit, land, dash

---

## 5. Integration & Architecture

### 5.1 Centralized Animation Config
- **AnimationConfig resource**: Single `.tres` with squash factors, ease curves, timings
- **ThemeConfig**: Per-theme colors, outline settings, particle palettes

### 5.2 FX Pipeline
- **FXEvent bus or manager**: `FXManager.emit("land", position, intensity)` → triggers particles, camera pulse, sound
- **Unified triggers**: Landing, hit, dash, grapple all go through same pipeline for consistent feel

### 5.3 Depth System Unification
- **Single DepthPlanes reference**: All visual systems (scale, shadow, parallax) read from same Y→depth mapping
- **Smooth tiers**: Replace discrete bands with continuous curve: `depth_scale = 1.0 - (y - y_min) / (y_max - y_min) * 0.2`

---

## 6. Implementation Phases

### Phase 1: Quick Wins (1–2 days)
- [ ] Increase camera rotation for 3D tilt (0.15 → 0.25)
- [ ] Smooth depth scale (continuous instead of 4 tiers)
- [ ] Ease-out on camera follow
- [ ] Boost squash recovery smoothness (spring tuning)

### Phase 2: Visual Polish (2–3 days)
- [ ] Softer shadows (multi-layer gradient)
- [ ] Directional lighting pass on terrain
- [ ] **Terrain fill** for floors and ceilings (map completeness)
- [ ] Sprite outlines (optional, shader or draw pass)
- [ ] Hitstop + screen shake tuning

### Phase 3: Animation Refinement (2–3 days)
- [ ] Ease curves for all procedural animations
- [ ] Landing/jump polish (timing, squash, particles)
- [ ] Attack anticipation + recovery
- [ ] Entity spawn-in / death animations

### Phase 4: Integration & Config (1–2 days)
- [ ] AnimationConfig / ThemeConfig resources
- [ ] FX pipeline or event system
- [ ] Depth system refactor (smooth curve)

### Phase 5: Advanced (Optional)
- [ ] SubViewport for camera tilt (if needed)
- [ ] Slope/ramp collision
- [ ] AnimationPlayer migration for keyframe control

---

## 7. Reference: Target Feel

| Aspect        | Current           | Target                      |
|---------------|-------------------|-----------------------------|
| **POV**       | Flat 2D           | Subtle isometric/3D tilt    |
| **Camera**    | Linear lerp       | Ease-out / spring feel      |
| **Depth**     | 4 discrete tiers  | Smooth continuous scale    |
| **Animations**| Procedural sin   | Ease curves, spring squash |
| **Shadows**   | Hard ellipse     | Soft, depth-scaled          |
| **Lighting**  | Minimal          | Directional + AO           |
| **Feedback**  | Basic            | Hitstop, shake, particles   |
| **Maps**      | Gaps, floating   | Floor + ceiling terrain fill |

---

## 8. Files to Modify (by phase)

| Phase | Files |
|-------|-------|
| 1 | `main_game.gd`, `depth_planes.gd`, `player.gd`, `enemy.gd`, `ally.gd` |
| 2 | `linear_map.gd`, `parallax_backdrop.gd`, `fx_draw_node.gd`, terrain fill system, entity `_draw` |
| 3 | `player.gd`, `enemy.gd`, `ally.gd`, `particle_system.gd` |
| 4 | New: `animation_config.gd`, `theme_config.gd`; refactor FX triggers |

---

*Document created for SnakeGameGodot. Adjust phases and scope based on priorities.*
