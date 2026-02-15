# Level Editor

**→ Full step-by-step: [LEVEL_1_EDITING_GUIDE.md](LEVEL_1_EDITING_GUIDE.md)**

Two workflows: **Node-based** (recommended, drag-and-drop) and **TileMap** (grid paint).

---

## Node-Based Level Design (Drag-and-Drop) — Recommended

True drag-and-drop: select, move, resize, delete like any node.

### Setup

1. Open `res://main_game/levels/level_01_nodes.tscn` as a template
2. Or create a new Node2D scene and add level nodes as children

### Level Nodes (add from scene tree or duplicate existing)

| Node Class              | Use                    | Notes                          |
|-------------------------|------------------------|--------------------------------|
| **LevelFloorSegment**   | Walkable ground        | Position = top-left, resize via Inspector |
| **LevelPlatform**       | Floating platform      | Position = top-left           |
| **LevelCheckpoint**     | Respawn point          | Position = center             |
| **LevelGoal**           | Level end zone         | Position = center, resize     |
| **LevelGrappleAnchor**  | Grapple swing point    | Position = center             |
| **LevelChainLink**      | Pit recovery grapple   | Position = center             |

### Workflow

- **Add**: Right-click root → Add Child Node → search for the class name (e.g. `LevelFloorSegment`)
- **Move**: Select node, drag in 2D viewport
- **Resize**: Select Floor/Platform/Goal → change `Size` in Inspector
- **Delete**: Select node, press Delete
- **Duplicate**: Select node, Ctrl+D

### Naming

- `level_01_nodes.tscn` → level 1
- `level_02_nodes.tscn` → level 2
- etc.

Node-based levels take precedence over TileMap levels for the same level ID.

---

## TileMap Level Design (Grid Paint)

### First-Time Setup

1. Open `res://main_game/levels/generate_level_tiles.tscn`
2. Run the scene (F6) once
3. Creates `platformer_tiles.png`, `platformer_tileset.tres`, and `level_01.tscn`

### Tile Reference (atlas row 0)

| Column | Tile      | Color  | Use                    |
|--------|-----------|--------|------------------------|
| 0      | Floor     | Brown  | Walkable ground        |
| 1      | Platform  | Grey   | Floating platforms     |
| 2      | Checkpoint| Green  | Respawn point          |
| 3      | Goal      | Gold   | Level end              |
| 4      | Grapple   | Blue   | Grapple anchor (swing) |
| 5      | Chain     | Silver | Chain link (pit recovery) |

### Naming

- `level_01.tscn` → level 1 (TileMap)
- `level_02.tscn` → level 2
- etc.

---

## Priority

1. Node-based (`level_XX_nodes.tscn`) — loaded first if present
2. TileMap (`level_XX.tscn`) — used if no node-based level
3. Code config — fallback if no custom level scene
