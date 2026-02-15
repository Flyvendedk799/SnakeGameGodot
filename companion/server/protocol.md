# Companion Protocol Schema

Single source of truth for companion websocket payloads.

## Shared constraints

- Every payload is a JSON object with a string `type`.
- No undeclared fields are allowed per message type.
- Normalized map coordinates use `[0.0, 1.0]` bounds.
- Chopper joystick axes use `[-1.0, 1.0]` bounds.
- Integer fields must be safe integers and within listed bounds.

## HTTP

### `GET /session/create`

Success:

```json
{ "code": "ABC234", "token": "ABCDEFGH2345" }
```

Rate-limited response:

```json
{ "error": "rate_limited" }
```

## Client/Server WebSocket messages

### Companion/Game -> Server

- `join`
  - `{ type, code, role }`
  - `code`: 6 chars (`[A-Z2-9]{6}`)
  - `role`: `"game" | "companion"`
- `rejoin`
  - `{ type, token, role }`
  - `token`: 12 chars (`[A-Z2-9]{12}`)
- `helicopter_drop` / `supply_drop` / `emp_drop`
  - `{ type, x, y }`, `x/y` in `[0,1]`
- `radar_ping`
  - `{ type }`
- `chopper_input`
  - `{ type, x, y }`, `x/y` in `[-1,1]`
- `new_wave`
  - `{ type }` (game role only)
- `minimap`
  - `{ type, enemies, allies, players, wave?, state?, chopper? }`
  - `enemies/allies/players`: arrays of `[x,y]` points, each in `[0,1]`, each list max 256
  - `wave`: integer `[0,9999]`
  - `state`: string (1..64 chars)
  - `chopper`: `[x,y]` in `[0,1]`
- `bomb_impact`
  - `{ type, x, y, kills }`, `kills` integer `[0,999]`
- `supply_impact`
  - `{ type, x, y }`
- `game_state`
  - `{ type, state }`, `state` string (1..64 chars)
- `ping`
  - `{ type, timestamp }`, `timestamp` integer `>= 0`

### Server -> Companion/Game

- `joined`
  - `{ type, code, token }`
- `error`
  - `{ type, code }`
  - `code`: minimal safe reason (`invalid_session`, `request_rejected`, ...)
- `game_connected`
  - `{ type }`
- `companion_connected`
  - `{ type }`
- `drop_ack`
  - `{ type, x, y, ability, remaining }`
  - `ability`: `bomb | supply | emp`
- `radar_ack`
  - `{ type, remaining }`
- `new_wave`
  - `{ type }`
- `bomb_drop`
  - `{ type, x, y }`
- `supply_drop`
  - `{ type, x, y }`
- `emp_drop`
  - `{ type, x, y }`
- `radar_ping`
  - `{ type }`
- `chopper_input`
  - `{ type, x, y }`
- `minimap`
  - `{ type, enemies, allies, players, wave?, state?, chopper? }`
- `bomb_impact`
  - `{ type, x, y, kills, mega }`
- `supply_impact`
  - `{ type, x, y }`
- `game_state`
  - `{ type, state }`
- `pong`
  - `{ type, timestamp }`

## Server enforcement notes

- `/session/create` is IP-throttled and capped by active sessions per IP.
- Ability actions (`bomb`, `supply`, `radar`, `emp`) enforce per-wave budgets, cooldown, and burst windows.
- Dropped/blocked packets are logged server-side with structured reasons.
- Clients only receive minimal safe error codes.
