# Companion Experience – Improvement Plan

A step-by-step plan to significantly improve the Karen Defense companion system across robustness, features, UX, and performance. **This is a plan only—implementation is separate.**

---

## 1. Robustness

### 1.1 Reconnection & Session Recovery
**Problem:** Companion or game disconnect causes loss of session; companion must refresh to get new code.

**Plan:**
- Add `reconnect_token` to session: when session is created, generate a 12-char token; return it to companion in `joined`.
- Companion stores token; on disconnect, can send `rejoin` with token instead of code. Server looks up session by token.
- Game stores session token when connected; on disconnect, auto-reconnect using token (not code) so companion doesn’t need to re-share.
- **Files:** `companion/server/index.js` (session schema, rejoin handler), `companion/client/app.js` (store token, rejoin flow), `karen_defense/systems/companion_session.gd` (store token, rejoin on reconnect).

### 1.2 Graceful Degradation When Game Pauses
**Problem:** Drops during pause/shop may be “wasted”; companion has no feedback.

**Plan:**
- Game sends `game_state` to server when state changes: `wave_active`, `between_waves`, `paused`, `level_up`, `game_over`.
- Server forwards to companion.
- Companion grays out or disables tap when `game_state !== 'wave_active'`, shows “Wait for combat…”.
- Optionally: queue drop and execute when wave becomes active (adds complexity).
- **Files:** `karen_defense/karen_defense.gd` (send state on change), `companion/server/index.js` (forward), `companion/client/app.js` (disable + message).

### 1.3 Malformed Message Handling
**Plan:**
- Server: wrap each message handler in try/catch; log malformed messages; never crash.
- Companion: validate all incoming messages (type, required fields) before use.
- Godot: use `JSON.parse_string` with null check; validate `data is Dictionary` before accessing.
- **Files:** All three layers.

### 1.4 WebSocket Reconnection Backoff
**Plan:**
- Godot: cap backoff at 30s; add jitter (±2s) to avoid thundering herd.
- Companion: exponential backoff on reconnect button (e.g. 1s, 2s, 4s) before allowing another attempt.
- **Files:** `companion_session.gd`, `companion/client/app.js`.

---

## 2. New Companion Abilities

### 2.1 Radar Ping
**Effect:** Reveal enemy positions on minimap for 5 seconds (highlight or pulse).

**Plan:**
- Server: new message `radar_ping` from companion; cooldown 60s, 1 per wave.
- Game: new handler `_on_companion_radar()`; set `radar_reveal_timer = 5.0`; enemies in “revealed” state draw with special highlight on HUD minimap.
- Companion: new ability button; sends `radar_ping`; UI shows cooldown and “1/1 this wave”.
- **Files:** `companion/server/index.js`, `companion/client/app.js` + `index.html`, `karen_defense/systems/companion_session.gd`, `karen_defense/karen_defense.gd`, `karen_defense/ui/hud.gd`.

### 2.2 EMP / Stun
**Effect:** Stun enemies in 80px radius for 2 seconds.

**Plan:**
- Server: `emp_drop` with x,y; cooldown 90s, 1 per wave.
- Game: new `EmpEffectEntity`; apply `stun_timer = 2.0` to enemies in radius; enemies skip AI when stunned.
- Companion: new ability; same UI pattern as bomb.
- **Files:** Same pattern as bomb/supply.

### 2.3 Shield Booster
**Effect:** 30% damage reduction for players for 8 seconds.

**Plan:**
- Server: `shield_request`; cooldown 45s, 1 per wave.
- Game: set `companion_shield_timer = 8.0`; in `take_damage`, multiply by 0.7 when timer > 0.
- Companion: single “Shield” button (no map tap).
- **Files:** Similar pattern; no positional drop.

### 2.4 Ammo / Cooldown Restore
**Effect:** Restore 1 grenade and reduce weapon cooldowns by 50%.

**Plan:**
- Server: `ammo_drop` at x,y; cooldown 40s, 2 per wave.
- Game: spawn pickup at location; player/ally who grabs gets grenade + cooldown reset.
- Companion: tap map to drop ammo crate.
- **Files:** New entity + pickup logic.

---

## 3. Companion App UX

### 3.1 Wave & Game State Display
**Plan:**
- Game sends `wave_number` and `game_state` in minimap payload (or separate heartbeat).
- Companion shows “Wave 12” and “In combat” / “Between waves” / “Paused”.
- **Files:** `karen_defense/karen_defense.gd` (add to minimap or new message), `companion/server/index.js`, `companion/client/app.js` + HTML.

### 3.2 Improved Minimap Visualization
**Plan:**
- Draw fort/keep outlines (match game map) from config or static data.
- Different sizes for boss enemies (3px) vs normal (1.5px).
- Smooth interpolation: lerp entity positions over 2–3 frames to reduce jitter.
- Optional: trail/history dots for recent enemy positions (fade out).
- **Files:** `companion/client/app.js` (draw logic), optionally `companion/client/minimap_config.json` for fort geometry.

### 3.3 Sound Design
**Plan:**
- Add Web Audio / HTML5 Audio: soft “whoosh” on bomb drop, “thud” on impact, “chime” on supply, “beep” on wave start.
- Toggle in settings: “Sound effects: On/Off”.
- **Files:** `companion/client/app.js`, `companion/client/sounds/` (asset files), `companion/client/index.html` (toggle).

### 3.4 First-Time Tutorial
**Plan:**
- LocalStorage flag `companion_tutorial_seen`.
- On first connect: overlay with 3 steps—“Share code”, “Tap map to drop”, “See impact”—with Next/Done.
- **Files:** `companion/client/app.js`, `companion/client/index.html`, `companion/client/style.css`.

### 3.5 Connection Quality Indicator
**Plan:**
- Companion sends `ping` every 5s; server responds `pong` with timestamp.
- Companion computes RTT; show green / yellow / red dot and optional “XX ms” tooltip.
- **Files:** `companion/client/app.js`, `companion/server/index.js`.

### 3.6 Accessibility
**Plan:**
- Increase tap targets to 48px minimum.
- Add `aria-label` to buttons and canvas.
- Support “Reduce motion” / prefers-reduced-motion for impact animations.
- **Files:** `companion/client/index.html`, `companion/client/app.js`, `companion/client/style.css`.

---

## 4. In-Game HUD & Feedback

### 4.1 Companion Status Badge
**Plan:**
- When companion connected: small badge near minimap—“Companion online” with green dot.
- When disconnected: “Companion offline” (gray) or hide badge.
- **Files:** `karen_defense/ui/hud.gd`, `karen_defense/karen_defense.gd` (expose connection state).

### 4.2 Companion Action Feed
**Plan:**
- Extend current notification: show last 2–3 actions in a small vertical feed (e.g. “Bomb: 3 kills”, “Supply dropped”, “Radar active”).
- Each fades after 3s; newest on top.
- **Files:** `karen_defense/karen_defense.gd` (array of `{text, timer}`), `karen_defense/ui/hud.gd` (draw list).

### 4.3 Companion Cooldown Preview
**Plan:**
- Game doesn’t know companion cooldowns. Option A: companion sends `cooldown_status` (bomb_ready_at, supply_ready_at); game shows “Companion: Bomb in 12s”. Option B: keep it companion-only.
- Implement Option A: new message type, server forward, HUD displays.
- **Files:** `companion/client/app.js`, `companion/server/index.js`, `karen_defense/systems/companion_session.gd`, `karen_defense/ui/hud.gd`.

### 4.4 “Hold D-pad Up to follow helicopter” Hint
**Plan:**
- When companion connected and helicopter exists: show brief hint below companion notification—“D-pad Up: Look at helicopter”.
- **Files:** `karen_defense/ui/hud.gd`.

---

## 5. Server Enhancements

### 5.1 Per-Ability Cooldown Tracking
**Plan:**
- Session stores `lastBombAt`, `lastSupplyAt`, `lastRadarAt`, etc.
- Each ability has `COOLDOWN_MS` and `MAX_PER_WAVE`.
- Reject with `drop_rejected` + `reason` (“cooldown”, “limit”) when invalid.
- Companion shows specific feedback.
- **Files:** `companion/server/index.js`, `companion/client/app.js`.

### 5.2 Debug / Admin Endpoint
**Plan:**
- `GET /admin/sessions` (or protected) returns count of active sessions, maybe session IDs (no codes).
- Useful for monitoring and debugging.
- **Files:** `companion/server/index.js`.

### 5.3 Session Persistence (Optional)
**Plan:**
- Use Redis or in-memory store with TTL for sessions.
- Survives server restart; companions can reconnect with same code for X minutes.
- **Files:** `companion/server/index.js`, add Redis client.

---

## 6. Performance

### 6.1 Minimap Payload Compression
**Plan:**
- Round coordinates to 2 decimals: `[0.12, 0.34]` → `[12, 34]` (scale 100).
- Cap entities: max 60 enemies, 20 allies.
- **Files:** `karen_defense/karen_defense.gd`, `companion/client/app.js` (decode).

### 6.2 Conditional Minimap Sending
**Plan:**
- Only send minimap when companion is on “connected” screen (companion sends `view_state: 'minimap'` or similar).
- Or: reduce frequency when in shop (every 500ms instead of 150ms).
- **Files:** `karen_defense/karen_defense.gd`, optionally `companion/client/app.js`.

### 6.3 Companion Client RAF Throttling
**Plan:**
- Cap draw loop at 30 FPS when idle (no new minimap data) to save battery on mobile.
- **Files:** `companion/client/app.js`.

---

## 7. Polish & Delight

### 7.1 Celebration Moments
**Plan:**
- When companion gets 5+ kills in one bomb: extra strong haptic, “MEGA STRIKE!” on companion.
- When supply saves barricade from breaking: “Barricade saved!” flash.
- **Files:** `companion/client/app.js`, `karen_defense/entities/helicopter_bomb.gd`, `companion/server/index.js` (optional: enhance `bomb_impact` with extra metadata).

### 7.2 Companion-Specific Achievements
**Plan:**
- Track: total bombs dropped, total kills, total supplies, waves assisted.
- Store in localStorage; show “Companion stats” panel.
- **Files:** `companion/client/app.js`, `companion/client/index.html`.

### 7.3 Theming
**Plan:**
- Light/dark theme toggle; store in localStorage.
- Match Karen Defense color palette (purple, gold accents).
- **Files:** `companion/client/style.css`, `companion/client/app.js`.

---

## 8. Implementation Order Suggestion

1. **Robustness first:** Reconnection token, graceful pause handling.
2. **HUD polish:** Companion badge, action feed, D-pad hint.
3. **Companion UX:** Wave display, minimap improvements, sounds.
4. **New abilities:** Radar, then EMP, then Shield (by complexity).
5. **Performance:** Minimap compression, throttling.
6. **Polish:** Celebrations, achievements, themes.

---

## 9. File Reference

| Area            | Primary Files                                                              |
|-----------------|----------------------------------------------------------------------------|
| Server          | `companion/server/index.js`                                                |
| Companion client| `companion/client/app.js`, `index.html`, `style.css`                       |
| Godot session   | `karen_defense/systems/companion_session.gd`                               |
| Godot game      | `karen_defense/karen_defense.gd`                                           |
| Godot HUD       | `karen_defense/ui/hud.gd`                                                  |
| Godot entities  | `karen_defense/entities/helicopter_bomb.gd`, `supply_drop.gd`             |
| Combat          | `karen_defense/systems/combat_system.gd`                                  |
