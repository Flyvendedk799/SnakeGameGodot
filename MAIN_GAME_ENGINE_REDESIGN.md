# Main Game Engine Redesign

The Main Game currently reuses Karen Defense's core: same `PlayerEntity`, `EnemyEntity`, combat system, and movement model. It's a linear layout of the same top-down experience. To make it "a completely different experience," the **game loop, controls, and feel** need to change at the engine level.

---

## Current vs. Redesigned

| Aspect | Current | Redesigned (proposed) |
|--------|---------|------------------------|
| **Movement** | Free 4-directional, full stop | Lane-based or auto-run |
| **Combat** | Manual melee/ranged, combos | Timing-based, auto-attack, or simplified |
| **Perspective** | Top-down (tilted) | Side-view runner or lane-scroller |
| **Flow** | Walk → fight → checkpoint → repeat | Run → react → survive |
| **Entities** | Shared with Karen Defense | Main-Game-specific (or adapter layer) |

---

## Option A: Lane-Based Runner

**Feel:** Temple Run / Subway Surfers style, but 2D side view.

- **Movement:** Player runs right automatically. Input: switch lane (up/down) between 3–4 fixed Y positions.
- **Combat:** Auto-attack when in same lane as enemy, or tap to attack. Enemies approach from the right.
- **Obstacles:** Gaps, barriers — jump/drop to avoid.
- **Engine changes:**
  - New `MainGamePlayer` (or `MainGameRunner`) with lane logic, no free movement.
  - Camera locked to player X, no lookahead.
  - Spawn director spawns ahead of camera, not behind.
  - Collision: discrete lanes instead of continuous Y.

**Pros:** Very different feel, clear runner identity, simpler controls.  
**Cons:** Less tactical, more reflex-based.

---

## Option B: Side-Scrolling Beat-Em-Up

**Feel:** Streets of Rage / Final Fight.

- **Movement:** Free 2D movement (left/right/up/down) on a side-view plane. Optional gravity/jump.
- **Combat:** Melee combo system (keep or simplify from current), with punch/kick/special.
- **Camera:** Side-on, scrolls with player. Enemies enter from left/right.
- **Engine changes:**
  - New `MainGamePlayer` with side-view movement and possibly jump/gravity.
  - Sprites/animations oriented for side view (or rotate existing).
  - Different collision model (platforms, ground line).
  - Combat tuned for side-view hitboxes.

**Pros:** Recognizable genre, strong combat focus.  
**Cons:** Highest scope, may need new art and animation.

---

## Option C: Auto-Runner with Reaction Combat

**Feel:** Canabalt meets combat — minimal input, high tension.

- **Movement:** Auto-run right. Player only: Jump, Attack, (optional) Block/Dash.
- **Combat:** Tap to attack in lane. Enemies in same lane get hit. Enemies ahead require timing.
- **Obstacles:** Jump over gaps, slide under barriers, attack through waves.
- **Engine changes:**
  - New `MainGameRunner` with auto-run X velocity.
  - Jump state (gravity, land).
  - Attack as a quick forward hit with cooldown.
  - Spawns only ahead; no backward spawns.

**Pros:** Strong runner identity, simple controls, reuse of combat concepts.  
**Cons:** Less exploratory than current.

---

## Option D: Runner-Mode Adapter (Incremental)

**Feel:** Keep current entities but change movement rules.

- **Movement:** Player has constant rightward drift; can move up/down and attack. Cannot go left beyond a margin.
- **Combat:** Same as now (melee, ranged, combos).
- **Engine changes:**
  - `MainGameManager` or a mode flag adds drift and left boundary.
  - Spawn director tuned for one-way flow.
  - Camera locked to player X with minimal lookahead.

**Pros:** Smallest change, reuses everything.  
**Cons:** Still feels like Karen Defense in a corridor.

---

## Recommendation

**Option A (Lane-Based Runner)** or **Option C (Auto-Runner)** give the biggest shift in feel with moderate scope. Both are clearly different from Karen Defense and create a distinct Main Game identity.

---

## Implementation Path (if you choose A or C)

1. **Create `MainGamePlayer`** — New script for Main Game only. Handles lanes (A) or auto-run + jump (C). Does not extend `PlayerEntity` to avoid dragging Karen Defense logic.
2. **Create `MainGameRunner` scene/manager** — Replaces or wraps main_game.gd for the new flow.
3. **Spawn director** — Spawn ahead of player; no zones behind.
4. **Combat** — Either a simplified `MainGameCombat` (lane/same-Y checks) or adapter that uses existing combat with different hit detection.
5. **Map** — Lane definitions (A) or jump-through platforms (C).
6. **HUD** — Simplified for runner: speed, distance, combo, gold.

---

---

## Implemented: Option B + 3D Twist (Depth Planes)

**Depth-Plane Beat-Em-Up:** Side-scrolling brawler where Y = depth in 3D space.

- **3 depth planes:** BACK (y~200), MID (y~360), FRONT (y~520) — higher Y = "closer" to camera
- **Plane-locked melee:** You only hit enemies in your plane; enemies only hit you in theirs
- **Scale by depth:** Back plane = 0.8x, mid = 1.0x, front = 1.15x (perspective)
- **Plane magnetism:** Gentle pull toward nearest plane for cleaner combat
- **Beat-em-up facing:** Face left or right only (no 360° aiming)
- **Visual tiers:** Depth bands drawn on map
- **Projectiles** ignore planes (ranged crosses depth)
