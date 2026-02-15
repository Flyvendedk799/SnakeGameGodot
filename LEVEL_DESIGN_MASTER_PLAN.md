# Level Design Master Plan — Elite Upgrade Roadmap

**Purpose:** Elevate all 15 main game levels from 9.4/10 to the next tier via elite-level design principles. This plan is implementation-ready for another model.

---

## 1. Design Philosophy

### 1.1 Core Principles
- **Readability First:** Every pit, platform, and threat must be readable at sprint speed.
- **One Primary Mechanic Per Section:** Introduce → Reinforce → Remix per level.
- **Intentional Pacing:** Combat bursts → traversal breather → combat burst. No flat endurance slogs.
- **Meaningful Choice:** Multiple valid routes (e.g., grapple vs. platform chain vs. wall jump).
- **Death as Teacher:** Every death teaches spacing, timing, or mechanic usage—never cheap geometry.

### 1.2 Mechanic Distribution Matrix
| Mechanic      | Primary Levels | Secondary Levels |
|---------------|----------------|------------------|
| Jump          | 1              | 2–15             |
| Dash          | 1, 6           | 2, 3, 4, 7, 8–15 |
| Double Jump   | 1, 2           | 4, 5, 12         |
| Wall Jump     | 2, 5, 15       | 4                |
| Drop-through  | 3, 11          | 9, 13            |
| Air Dash      | 4, 5, 12       | 15               |
| Grapple       | 4, 5, 12       | 8, 9, 10, 13, 15 |
| Sprint        | 6, 7, 14       | 2, 9             |
| Block         | 3, 10          | 11, 15           |

---

## 2. Per-Level Upgrade Specifications

### Level 1 — First Steps
**Current:** Basic tutorial geometry.  
**Target:** Iconic "first run" that feels crafted.

- **Geometry:** Add one optional secret ledge (double-jump height) with a small reward or easter egg. Create a 3-tier pit sequence: small jump → 90px dash gap → 120px double-jump platform. Ensure the second pit *requires* dash (no jump-only skip).
- **Pacing:** Stagger spawns so the player meets 1–2 enemies before the first pit; post-pit density increases. First checkpoint feels earned (after first dash).
- **Visual Landmarks:** Add explicit `decor` entries for tutorial landmarks (e.g., "first_pit_marker", "double_jump_sign"). Ensure parallax conveys "opening vista."
- **Checkpoint:** Verify checkpoint 2 sits *after* the dash gap so death before it reinforces "you must dash."

---

### Level 2 — The Ascent
**Current:** Wall-jump shaft, double-jump chain, underground pocket.  
**Target:** "Ah, this is a platformer" moment.

- **Geometry:** Make the wall-jump shaft *feel* tighter: narrow the shaft by 10–15px if needed, or add a one-way drop-through floor at the top so descent uses drop-through. Add a sprint stretch (200–300px of uninterrupted floor) before the final checkpoint.
- **Underground Pocket:** Give the underground segment a distinct "reward" feel—consider a gold_multiplier or a short safe zone before re-emerging.
- **Optional Route:** One grapple anchor that bypasses the wall-jump shaft for skilled players; ensure the main route remains faster for first-timers.
- **Pacing:** Post–wall-jump, offer a 50–80px breather before next combat.

---

### Level 3 — Below
**Current:** Drop-through, bomber-heavy cave, BLOCK incentive.  
**Target:** "Block matters" eureka moment.

- **Geometry:** Add a "block gauntlet" corridor: 150–200px of floor with bombers above or behind, forcing block usage. Ensure drop-through platforms create clear "upper vs lower" paths.
- **Bomber Placement:** Cluster bombers so the player *must* block at least once. Add one platform with a bomber that can only be safely approached from below (drop-through).
- **Pacing:** One low-intensity section (single complainer) between bomber clusters.
- **Readability:** Ensure bomber spawn positions are visible before the player commits to a platform.

---

### Level 4 — High Wire
**Current:** Air dash, grapple, skybridge.  
**Target:** "High risk, high reward" verticality.

- **Geometry:** Make the skybridge section (x 2075–2880) *narrower*—floating ribbon feel. Add one grapple-only shortcut that saves 3–4 seconds for experts.
- **Air Dash Gate:** Create a gap that is *impossible* without air dash (or grapple); no accidental double-jump skip.
- **Vertical Climb:** Ensure the ascent to skybridge has a clear "stair-step" platform rhythm.
- **Pacing:** Skybridge combat should feel tense—fewer, stronger enemies rather than a swarm.

---

### Level 5 — The Summit
**Current:** Epic multi-biome marathon.  
**Target:** Memorable finale for the first world.

- **Geometry:** Add a "breath" segment—80–120px of empty or low-density floor after the cave exit, before the wall-jump shaft. The final gauntlet (5580+) should have 2–3 micro-platforms as punctuation, not one long floor.
- **Biome Transitions:** Verify floor_segments and parallax/theme align at transitions (cave → platform → skybridge → surface). Add explicit `decor` at transition points for visual clarity.
- **Grapple Optionality:** Ensure both grapple and platform routes to the skybridge exist; grapple is faster but riskier.
- **Final 800px:** Escalate density and enemy variety; consider one "mega only" platform for a dramatic beat.

---

### Level 6 — Ambush Alley
**Current:** Sprint/dash pits, ambush spawns.  
**Target:** "Run or fight" tension.

- **Geometry:** Increase pit gap lengths slightly (by 10–20px) so sprint *into* dash is required for the middle pit. Add one "narrow escape" platform (60–70px wide) between ambush zones.
- **Ambush Timing:** Stagger ambush spawns so the player hears/anticipates before the first enemy appears. Ensure trigger_x creates "you're being chased" feel.
- **Checkpoint Placement:** One checkpoint in the middle of an ambush stretch—respawn should put the player *in* danger, not safe.
- **Pacing:** First segment low threat; second and third escalate; final segment is the hardest.

---

### Level 7 — Gold Rush
**Current:** Gold multiplier zone, single dash platform.  
**Target:** "Speed = gold" incentive.

- **Geometry:** Add 2–3 more platforms in the gold zone to create route variety (high path vs. low path). Consider a grapple anchor that skips to the gold zone entry.
- **Gold Zone Feel:** Ensure the gold_multiplier zone has a distinct visual cue (decor, or segment boundary). Lengthen the gold zone slightly if it feels too short.
- **Risk/Reward:** Add a narrow platform *inside* the gold zone—standing on it yields more kills but is riskier.
- **Pacing:** Build anticipation before the gold zone; a short empty stretch lets the player sprint in.

---

### Level 8 — Safe Havens
**Current:** Full heals, platforming oases.  
**Target:** "Oasis" feel—each checkpoint is a moment of relief.

- **Geometry:** Ensure each safe haven has a short (40–60px) "approach" where the player can see the checkpoint before committing. Add one optional high platform that requires double-jump + air dash to reach a bonus.
- **Checkpoint Identity:** Each safe haven should feel different—one on a platform, one at ground level, one after a grapple. Vary the geometry leading to each.
- **Pacing:** Combat density should *drop* 80–100px before each checkpoint rect.
- **Heal Moment:** Verify heal_ratio 1.0 triggers correctly; consider a brief visual/audio cue on full heal.

---

### Level 9 — The Long March
**Current:** Long varied stretch, 6 checkpoints.  
**Target:** Endurance with clear "milestone" beats.

- **Geometry:** Break the 6000px into 4–5 distinct "chapters": (1) cave entrance, (2) narrow shaft, (3) open cavern, (4) climb out, (5) final sprint. Each chapter should have a unique geometry signature.
- **Grapple Pacing:** Space grapple anchors so the player can choose "grapple shortcut" vs. "platform grind" every 800–1000px.
- **Checkpoint Spacing:** Ensure no two checkpoints are more than 1200px apart; the middle third (2400–3600) is the "cruel" stretch with fewer checkpoints.
- **Pacing:** Introduce a "calm" segment (300–400px, low density) around x=3200 as a breather before the final push.

---

### Level 10 — Elite Invasion
**Current:** Block/parry focus, strong enemies, vertical play.  
**Target:** "Elite" combat showcase.

- **Geometry:** Add a "sniper perch"—one high platform with a witch or HOA that the player must block or climb to. Ensure the lower path is viable but harder.
- **Block Incentive:** Create a corridor (120–150px) where projectiles come from both sides; blocking is the optimal strategy.
- **Enemy Variety:** Ensure each segment introduces one new elite type before mixing. Final segment = all elites.
- **Pacing:** One platform-heavy section (2–3 platforms) where the player fights "above" the main floor.

---

### Level 11 — Underground Gauntlet
**Current:** Cave geometry, bombers, drop-through.  
**Target:** Claustrophobic gauntlet.

- **Geometry:** Add a "squeeze" section—narrower floor (e.g., 400–500px wide segment) to create pressure. Consider a vertical shaft with drop-through platforms that force the player to descend through bomber fire.
- **Bomber Rhythm:** Alternate "bomber cluster" with "melee cluster" (complainer/manager) so the player must switch between block and attack.
- **Surface Entry:** Make the surface→cave drop more dramatic—wider pit, or a platform that breaks away (conceptually; if not supported, use a long drop).
- **Pacing:** Each cave segment should peak in density at the 60–70% mark, then ease before the next checkpoint.

---

### Level 12 — Sky Scramble
**Current:** Floating islands, grapple, air dash.  
**Target:** "High-wire" precision platforming.

- **Geometry:** Make the skybridge section (1520–2280) feel like a tightrope—narrow the floor segments by 20–30px. Add one "fall-through" moment (platform that leads to a lower island) to create vertical decision-making.
- **Grapple Placement:** Ensure at least one grapple creates a "leap of faith" moment—grapple to an anchor the player can't see until committed.
- **Air Dash Gates:** Add 1–2 gaps that require air dash; double-jump alone should not suffice.
- **Pacing:** Transition from "grounded" (0–700) to "elevated" (830–1420) to "skybridge" (1520–2280) to "descent" (2380–3260) to "grounded finale" (3260+). Each phase should have a distinct combat feel.

---

### Level 13 — Mixed Madness
**Current:** All enemy types, high density, varied platforming.  
**Target:** Chaos with structure.

- **Geometry:** Create "arena" moments—wider floor segments (600–800px) where the player is surrounded, alternating with "corridor" moments (narrow platforms). Add one multi-level arena (ground + 2 platforms) for a climactic fight.
- **Enemy Sequencing:** Ensure each segment introduces a new type: Segment 1 adds witch, Segment 2 adds mega, etc. Final segment = all types.
- **Grapple Use:** One grapple anchor in the middle of an arena to allow vertical escape and re-engage.
- **Pacing:** Density should oscillate—high, medium, high, medium, peak. Avoid flat "max density" for 2000px.

---

### Level 14 — The Chase
**Current:** Ambush, dash platforms, chase feel.  
**Target:** Relentless pursuit.

- **Geometry:** Add one "catch-up" moment—a long floor (400–500px) where the player can create distance, followed by a pit that forces commitment. Enemies should spawn *ahead* of the player in one segment to create "they're everywhere" feel.
- **Platform Placement:** Ensure dash platforms are positioned so the player must chain dash→land→sprint→dash. No single dash should clear a whole stretch.
- **Ambush Layering:** Combine ground ambush with platform ambush—enemies above and behind.
- **Pacing:** Each segment should feel slightly harder; the final segment (3640+) is the "last stand" before the goal.

---

### Level 15 — The Final Gauntlet
**Current:** Marathon, surface→cave→skybridge→surface.  
**Target:** Epic capstone.

- **Geometry:** Add a "victory lap" segment—the last 600–800px should be slightly easier than the segment before it, creating a "you made it" feel. The wall-jump shaft (3135–4135) should feel like a distinct "challenge room."
- **Full Heal Placement:** Verify the two full-heal checkpoints (x=600, x=4750) are positioned after the hardest sections (post-ambush, post-skybridge).
- **Grapple Optionality:** Ensure the grapple at 3500 and 6500 offer meaningful shortcuts; the main route should still be completable without grapple.
- **Pacing:** Segment 1–2 = warm-up; 3–4 = cave intensity; 5–6 = skybridge climax; 7–8 = surface gauntlet; 9–10 = victory lap. The gold_multiplier segment (4280–5300) should feel rewarding, not punishing.
- **Final 400px:** Consider lowering density slightly so the player finishes strong, not exhausted.

---

## 3. Cross-Cutting Improvements

### 3.1 Explicit Decor System
Add a `decor` array to level configs for hand-placed landmarks:
```gdscript
"decor": [
  {"x": 400, "y": 350, "type": "tutorial_marker"},
  {"x": 1200, "y": 280, "type": "checkpoint_beacon"},
  {"x": 3500, "y": 100, "type": "grapple_hint"}
]
```
Use for: tutorial cues, checkpoint visibility, grapple-hint clouds, biome transition markers.

### 3.2 Checkpoint Visibility
- Ensure each checkpoint rect is visible from at least 150px away.
- Add optional `checkpoint_approach_min_x` to define a "safe zone" before the checkpoint where density drops.
- Consider a `checkpoint_landmark` decor type for visual identity.

### 3.3 Pit Consistency
- Standard pit widths: Tutorial (60–80px), Easy (90–110px), Medium (120–150px), Hard (160–200px).
- Ensure pit depth is always "death" (no soft-landing in pits).
- Add visual pit indicators (existing theme colors) at pit edges.

### 3.4 Spawn Zone Refinements
- `trigger_x` should be 50–80px *before* the first platform/obstacle the player must overcome.
- For ambush segments, consider `spawn_delay` or `spawn_wave_count` if the system supports it.
- Ensure `y_min`/`y_max` of spawn zones align exactly with floor/platform surfaces (no floating spawns).

### 3.5 Theme Consistency
- Verify each level's `theme` matches its world (world_config.gd).
- Add theme-specific decor density (cave = more crystals, grass = more plants, sky = more clouds/pillars).

---

## 4. Implementation Checklist (Per Level)

For each level, the implementer should:

1. [ ] Audit all `floor_segments` for gaps, overlaps, and pit consistency.
2. [ ] Verify all `checkpoints` have valid `layer` and `rect` within floor/platform bounds.
3. [ ] Ensure all `spawn_zones` use `layer` values that exist in `layers`.
4. [ ] Add at least 1–3 explicit `decor` entries for landmarks.
5. [ ] Validate `trigger_x` creates intended pacing (no early/late spawns).
6. [ ] Playtest: Can a first-time player complete without guide? Can a skilled player find shortcuts?
7. [ ] Measure: Average clear time, death points, checkpoint usage.

---

## 5. Quality Gates

A level passes "next tier" when:

- **Readability:** 90% of deaths are attributed to player error (timing, spacing), not "I didn't see that."
- **Pacing:** No segment longer than 400px feels flat or monotonous.
- **Mechanic Use:** The primary mechanic is *required* at least once; secondary mechanics are *rewarded* (shortcuts, optional paths).
- **Checkpoint Utility:** Each checkpoint is reached by >70% of players on first completion attempt.
- **Theme Cohesion:** Visual and geometric identity matches theme (cave = tight, sky = floaty, summit = epic).

---

## 6. File Reference

- **Level data:** `main_game/data/linear_map_config.gd`
- **Map logic/visuals:** `main_game/map/linear_map.gd`
- **Parallax:** `main_game/map/parallax_backdrop.gd`
- **World config:** `main_game/data/world_config.gd`

---

*Document version: 1.0 — Ready for implementation by external model*
