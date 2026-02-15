# Karen Defense Companion – Comprehensive Guide

This document explains the companion system architecture, how to make it more robust, add features, and enhance the user experience.

---

## 1. Architecture Overview

### Flow

```
Companion App (browser)  <--WebSocket-->  Railway Server  <--WebSocket-->  Godot Game
       |                        |                              |
   - Create session         - Route messages                - Connect with code
   - Tap to drop            - Validate & relay              - Receive bomb/supply
   - Live minimap           - Cooldowns & limits             - Send minimap data
   - Impact feedback                                          - HUD notifications
```

### Message Types

| Direction | Type | Purpose |
|-----------|------|---------|
| Game → Server | `join` | Connect with session code |
| Companion → Server | `join` | Join session as companion |
| Game → Server | `new_wave` | Reset per-wave limits |
| Companion → Server | `helicopter_drop` | Request bomb at normalized x,y |
| Companion → Server | `supply_drop` | Request supply crate at normalized x,y |
| Game → Server | `minimap` | Send enemy/ally/player positions |
| Game → Server | `bomb_impact` | Bomb landed + kill count |
| Game → Server | `supply_impact` | Supply landed |
| Server → Game | `joined` / `error` | Connection result |
| Server → Companion | `game_connected` | Game joined session |
| Server → Companion | `drop_ack` | Drop accepted |
| Server → Companion | `new_wave` | New wave started |
| Server → Companion | `minimap` | Live entity positions |
| Server → Companion | `bomb_impact` / `supply_impact` | Impact feedback |

---

## 2. Robustness Improvements

### 2.1 Godot – Null Safety

Always guard companion usage:

```gdscript
if companion_session and companion_session.is_session_connected():
    companion_session.send_minimap(...)
```

Skip companion entities in combat/update loops:

```gdscript
if proj is HelicopterBombEntity or proj is SupplyDropEntity:
    continue
```

### 2.2 Server – Validation

- Normalize session codes to uppercase
- Rate limit messages (50/10s)
- Max message size (4096 bytes)
- Session expiry (2 hours)
- Safe `ws.send()` in try/catch

### 2.3 Companion Client – Reconnection

- Reconnect button when disconnected
- Heartbeat (ping/pong) keeps connections alive
- Haptic feedback on successful drop

### 2.4 Minimap Real-Time Updates

- Send minimap during **WAVE_ACTIVE** and **BETWEEN_WAVES**
- Throttle to ~6–7 Hz (150ms interval)
- Normalize coordinates: `pos.x / SCREEN_W`, `pos.y / SCREEN_H`

---

## 3. Feature Ideas

### 3.1 New Companion Abilities

| Ability | Cooldown | Per Wave | Effect |
|---------|----------|----------|--------|
| Radar Ping | 60s | 1 | Reveal enemies on minimap for 5s |
| EMP | 90s | 1 | Stun enemies in radius for 2s |
| Shield | 45s | 1 | Temporary damage reduction for players |
| Ammo Drop | 40s | 2 | Restore ammo / cooldowns |

### 3.2 Companion UI Enhancements

- **Wave counter** – Show current wave from game
- **Drops remaining** – Already shown; ensure it updates on `new_wave`
- **Connection quality** – Ping/latency indicator
- **Sound effects** – Optional SFX on drop, impact, wave start
- **Tutorial overlay** – First-time user tips

### 3.3 Game HUD Enhancements

- **Companion status** – "Companion connected" badge when active
- **Last action** – Already implemented; extend to show kill count
- **Companion cooldowns** – Show when companion can drop next (requires game ↔ companion sync)
- **Look-at-helicopter** – "Hold D-pad Up to follow helicopter"

### 3.4 Server Enhancements

- **Session list** – Debug endpoint for active sessions
- **Metrics** – Drop count, connection duration
- **Reconnect token** – Allow companion to reconnect after disconnect without new code

---

## 4. UX Guidelines

### 4.1 Companion App

- **Clear states** – Landing → Waiting (code) → Connected (minimap)
- **Immediate feedback** – Haptic + visual on tap (success or reject)
- **Live minimap** – Enemies (red), allies (blue), players (green)
- **Impact feedback** – Bomb: orange ring + "X KILLS!"; Supply: green ring
- **Cooldown display** – "Ready!" or "Cooldown: Xs"
- **Drops remaining** – "2/2" or "1/2 left this wave"

### 4.2 In-Game

- **HUD notification** – "Companion: Bomb inbound!" / "Companion bomb: 3 kills!"
- **Camera** – Hold D-pad Up / L to pan to helicopter
- **Enable toggle** – Checkbox on world select; no companion = no overhead

### 4.3 Error Handling

- **Invalid code** – Server sends `error`; Godot stops reconnect
- **Session expired** – Server rejects after 2h
- **Drop rejected** – Cooldown or limit; companion shows reject flash
- **Disconnect** – Companion shows Reconnect button; game auto-reconnects

---

## 5. Key Files

| File | Role |
|------|------|
| `companion/server/index.js` | Express + WebSocket server |
| `companion/client/app.js` | Companion web UI logic |
| `karen_defense/systems/companion_session.gd` | Godot WebSocket client |
| `karen_defense/entities/helicopter_bomb.gd` | Bomb entity, reports kills |
| `karen_defense/entities/supply_drop.gd` | Supply entity |
| `karen_defense/systems/combat_system.gd` | Must skip companion entities |
| `karen_defense/ui/hud.gd` | Companion action notification |
| `karen_defense/ui/world_select.gd` | Enable checkbox, code input |

---

## 6. Deployment Checklist

1. **Railway** – Root directory `companion`, deploy from GitHub
2. **Godot** – Set `companion_session.server_url` to `wss://YOUR-DOMAIN/ws`
3. **Test** – Companion creates session → Game connects → Drop bomb → Verify HUD + impact

---

## 7. Future Enhancements (Roadmap)

1. **Persistent sessions** – Redis/DB for sessions across server restarts
2. **Multiple companions** – Allow 2+ companions per session (with per-companion limits)
3. **Spectator mode** – Watch-only companion with minimap, no drops
4. **Replay** – Record companion actions for post-game view
5. **Voice/chat** – Optional voice or quick-chat between game and companion
6. **Achievements** – "Companion assisted 10 kills" etc.
