# Main Game Gameplay Improvement Backlog

This document captures a focused, implementation-ready gameplay improvement plan for the Main Game mode.

## 1) Make difficulty meaningfully change runs

**Current gap**
- Difficulty can be selected in world map, but run-time impact is limited/inconsistent.

**Improvements**
- Apply difficulty multipliers directly during:
  - enemy stat initialization,
  - spawn pacing and caps,
  - checkpoint healing,
  - gold/soul rewards.
- Add one-line on-HUD difficulty summary at run start (e.g., `Hard: +20% enemy HP, +20% enemy damage, -20% gold`).

**Success criteria**
- Players can feel a clear difference between Normal/Hard/Nightmare in under 60 seconds of play.

## 2) Adaptive encounter pacing (director)

**Current gap**
- Spawn cadence is mostly static per zone.

**Improvements**
- Drive spawn_interval and effective density from a small pressure model:
  - player current HP ratio,
  - recent deaths/respawns,
  - kill speed over last N seconds,
  - active enemies near player.
- Add a short "recovery window" after respawn/checkpoint (reduced spawns for 8-12s).

**Success criteria**
- Fewer frustration spikes after a death while keeping high-skill runs intense.

## 3) Turn challenge modifiers into replay loops

**Current gap**
- Challenge modifier system exists but is underutilized in core run flow.

**Improvements**
- Add run-start modifier selection (optional) and daily challenge preset.
- Grant clear reward multipliers for modifiers.
- Show active modifiers and reward bonus in HUD/pause menu.

**Success criteria**
- Repeat runs become varied without building new content-heavy levels.

## 4) Rebalance checkpoint + shop tension

**Current gap**
- Checkpoint heal/shop can flatten risk-reward over time.

**Improvements**
- Tie checkpoint healing policy to difficulty and/or modifiers.
- Offer player tradeoffs:
  - full heal + reduced shop discounts, or
  - partial heal + improved shop discounts.
- On respawn, add optional "debt" choice: keep more gold but spawn one extra elite wave.

**Success criteria**
- Checkpoints remain meaningful strategic decisions rather than automatic resets.

## 5) Better onboarding of advanced movement/combat

**Current gap**
- Main Game has rich mechanics (dash, air dash, wall jump, grapple, parry, combo), but onboarding can overwhelm players.

**Improvements**
- Stage mechanics by world/level with explicit bite-sized challenges.
- Add contextual prompts that appear only until first successful use.
- Add optional practice room at world map for movement tech.

**Success criteria**
- New players reach mastery faster, with less early churn.

## 6) Encounter variety beyond raw spawn count

**Current gap**
- Segment identity relies heavily on spawn density and enemy mix.

**Improvements**
- Add encounter scripts/objectives per segment:
  - survive timer,
  - kill priority target,
  - protect checkpoint beacon,
  - ambush escape.
- Add short breather/reward micro-events between high-pressure segments.

**Success criteria**
- More memorable level beats and stronger pacing rhythm.

## 7) Improve challenge tracking + post-level feedback

**Current gap**
- Challenge evaluation is currently simplistic.

**Improvements**
- Track run telemetry (damage taken, deaths, clear time, kill completion) explicitly.
- Use weighted medal/star screen with reward bonuses.
- Make challenge failures clear at end-of-run recap.

**Success criteria**
- Players understand exactly why they did/did not earn rewards.

## 8) Camera behavior presets by context

**Current gap**
- Camera smoothing is strong but can still feel suboptimal in distinct contexts.

**Improvements**
- Use camera presets for:
  - platforming precision sections,
  - combat-heavy arenas,
  - coop spread scenarios.
- Blend between presets over 0.2-0.4s to avoid abrupt transitions.

**Success criteria**
- Better readability and less perceived camera friction.

---

## Suggested implementation order

1. Difficulty integration pass (high impact, low implementation risk).
2. Adaptive spawn pacing (high impact, medium risk).
3. Challenge modifier run flow + rewards (high replay value).
4. Checkpoint/shop tradeoff redesign.
5. Encounter scripting + improved post-level summary.

