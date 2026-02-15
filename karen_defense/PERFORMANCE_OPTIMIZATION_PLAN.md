# Karen Defense Performance Optimization Plan

## Goal
Stabilize FPS when large enemy groups cluster (especially near the player/fort) by reducing per-frame CPU cost and draw-call overhead, without changing core gameplay logic.

## What the code is currently doing (high-impact observations)

### 1) Every enemy redraws every frame with expensive custom drawing
- `EnemyEntity.update_enemy()` calls `queue_redraw()` every frame for every enemy.
- `EnemyEntity._draw()` performs many draw ops per enemy (shadow polygons, sprite outline, trail, HP bar, label, boss extras).
- `_draw_shadow_ellipse()` allocates and fills polygon arrays and computes trig every draw call.

**Why this is an “aha moment”:** stacked enemies multiply this cost heavily; it scales directly with enemy count and visual complexity.

### 2) Projectile collision is O(projectiles × enemies) every frame
- `CombatSystem._check_projectile_hits()` loops all projectiles and for player projectiles loops all enemies.
- Uses `distance_to()` (sqrt) for each candidate.

**Why this is an “aha moment”:** large swarms + many bullets create quadratic-like growth in checks.

### 3) Enemy chase/targeting does repeated global scans
- `EnemyEntity._state_chasing()` checks players and then iterates **all allies** each enemy update.
- Path selection can trigger `_build_nav_path()`, which does graph scans and repeated walkability tests.
- Main loop updates every enemy each frame in `_process_wave()`.

**Why this is an “aha moment”:** each enemy does non-trivial decision + potential path work, so clustered waves spike CPU.

### 4) Multiple full-container scans per frame across systems
In one frame during active wave, code scans enemy lists in several places:
- Enemy updates in `_process_wave()`
- Ally target updates (indirect scans)
- EMP snapshot pass
- `CombatSystem` melee + projectile passes
- Companion minimap pass (20 Hz)

**Why this is an “aha moment”:** even if each pass is “reasonable,” combined passes over large lists become expensive.

## Optimization plan (in order)

## Phase 0 — Baseline and profiling (must do first)
1. Add lightweight frame markers/timers around:
   - enemy update loop
   - ally update loop
   - combat system resolve
   - particle update
   - draw thread frame time (Godot profiler)
2. Record 3 scenarios:
   - low enemy count
   - high spread count
   - high stacked count (the problematic one)
3. Save baseline numbers: avg FPS, p95 frame time, and top 3 hot functions.

**Success criteria:** identify whether render or script time dominates in stacked scenario.

## Phase 1 — Biggest wins (render + broadphase)

### A. Replace per-enemy custom `_draw()` with node-based visuals (or LOD)
- Move enemy rendering from heavy `_draw()` calls to child nodes (`Sprite2D`, simple `ColorRect` HP bar, optional shadow sprite).
- Keep advanced effects only for nearby/on-screen enemies.
- Disable labels and trails by default for distant/off-focus enemies.
- Avoid per-frame polygon rebuilds in `_draw_shadow_ellipse()` (precompute once if kept).

**Expected impact:** major reduction in draw calls and script draw overhead.

### B. Add spatial partition for collision/target queries
- Build a simple grid/hash per frame (cell size around attack/projectile ranges).
- Use grid for:
  - projectile-vs-enemy checks
  - melee cone candidate prefilter
  - ally/enemy nearest-target queries
- Keep exact distance checks only on nearby candidates.

**Expected impact:** turns worst-case full scans into local neighbor checks.

### C. Replace `distance_to()` with squared-distance where possible
- In high-frequency loops, compare squared values (`distance_squared_to`) to squared thresholds.

**Expected impact:** cheap arithmetic win across thousands of checks/frame.

## Phase 2 — Update-frequency decoupling (logic throttling)

### A. Stagger expensive AI decisions
- Run heavy enemy target/path decisions at lower frequency (e.g., 5–10 Hz per enemy) with per-enemy randomized offsets.
- Keep movement interpolation every frame so motion remains smooth.

### B. Pathfinding budget
- Limit repath operations per frame globally (budget queue).
- Reuse last valid path longer unless target changed significantly.

### C. Batch shared data once/frame
- Cache active enemy/ally arrays once per frame in the game root and pass references to systems.
- Stop calling `get_children()` repeatedly across systems when same data is needed.

## Phase 3 — Visual scalability controls

1. Add “Performance Mode” toggles in Karen Defense settings:
   - reduced enemy trail
   - simplified shadows
   - hide enemy labels
   - reduced damage number spawn rate
2. Auto-degrade VFX when enemy count exceeds thresholds.
3. Clamp simultaneous particles/damage numbers globally.

## Phase 4 — Validation and guardrails

1. Re-profile same 3 scenarios from baseline.
2. Compare before/after p95 frame times and FPS.
3. Add regression guard:
   - debug metric print every N seconds during waves: enemy count, projectile count, collision checks this frame.

## Concrete, code-specific action list

1. **Enemy rendering refactor target:** `karen_defense/entities/enemy.gd`
   - Remove per-frame `queue_redraw()` dependency for common states.
   - Convert shadow and HP bar rendering to reusable nodes/textures.
2. **Collision broadphase target:** `karen_defense/systems/combat_system.gd`
   - Replace full enemy scan in `_check_projectile_hits()` with grid candidates.
3. **Frame cache target:** `karen_defense/karen_defense.gd`
   - Build per-frame `active_enemies`, `active_allies`, `active_projectiles` arrays once and share.
4. **AI throttling target:** `karen_defense/entities/enemy.gd` and `karen_defense/entities/ally.gd`
   - Split “decision tick” from “movement tick”.
5. **Instrumentation target:** `karen_defense/karen_defense.gd`
   - Add profiler-friendly markers/timers and summary logging.

## Recommended implementation order (fastest risk-adjusted ROI)
1. Collision broadphase + squared-distance checks.
2. Enemy render simplification / LOD.
3. AI decision throttling + path budget.
4. Optional QoL scalability toggles.

## Notes
- This plan intentionally avoids changing game design/logic outcomes.
- Focus is on CPU/render performance under large stacked enemy counts, exactly matching the reported issue.
