# Complete Guide: Editing Level 1

Step-by-step from opening Godot to testing your level.

---

## Quick Start (30 seconds)

1. Open Godot and your project.
2. FileSystem → `main_game/levels/` → double-click **`level_01_nodes.tscn`**.
3. Click nodes in the Scene tree, drag them in the 2D viewport to move.
4. Save (Ctrl+S), then run your game and play Level 1.

---

## Before You Start: Asset Checklist

These files should exist in `main_game/levels/`:

| Asset | Purpose | Used by |
|-------|---------|---------|
| `level_01_nodes.tscn` | Level 1 scene (drag-and-drop) | Node-based editor ✓ |
| `nodes/level_floor_segment.gd` | Floor node script | Node-based |
| `nodes/level_platform.gd` | Platform node script | Node-based |
| `nodes/level_checkpoint.gd` | Checkpoint node script | Node-based |
| `nodes/level_goal.gd` | Goal node script | Node-based |
| `nodes/level_grapple_anchor.gd` | Grapple node script | Node-based |
| `nodes/level_chain_link.gd` | Chain link node script | Node-based |
| `node_level_loader.gd` | Converts nodes → level data | Node-based |
| `platformer_tiles.png` | Tile texture (optional) | TileMap only |
| `platformer_tileset.tres` | TileSet (optional) | TileMap only |
| `level_01.tscn` | TileMap level (optional) | TileMap only |
| `generate_level_tiles.tscn` | Run once to create tiles | TileMap only |

**Node-based workflow needs no extra setup.** The scripts and `level_01_nodes.tscn` are already in place.

**If you prefer TileMap** (grid paint): open `generate_level_tiles.tscn` and run it (F6) once. That creates `platformer_tiles.png`, `platformer_tileset.tres`, and `level_01.tscn`.

---

## Part 1: Open the Level in Godot

1. **Open Godot Engine** and load your project.
2. In the **FileSystem** dock, go to `res://main_game/levels/`.
3. **Double-click** `level_01_nodes.tscn` to open it.
4. You should see:
   - **Scene** tree (left): root `Level01Nodes` with children (FloorStart, FloorEnd, Platform, Checkpoint, Goal, etc.).
   - **2D** viewport: colored shapes (brown floors, green checkpoint, gold goal, blue grapple, etc.).

---

## Part 2: Understanding What You See

Each node type has a distinct color:

| Color | Node | What it does in-game |
|-------|------|----------------------|
| Brown | Floor | Solid ground you walk on |
| Grey-brown | Platform | Floating platform you can jump onto |
| Green | Checkpoint | Respawn point when you die |
| Gold | Goal | Reach this to complete the level |
| Blue | Grapple | Point you can grapple and swing from |
| Silver | Chain | Pit recovery grapple point |

---

## Part 3: Editing the Level

### Moving Something

1. Click a node in the **Scene** tree (e.g. `Platform`).
2. In the **2D** viewport, drag the node’s gizmo (or move the node).
3. Alternatively, change **Position** in the Inspector (right panel).

### Resizing Floors, Platforms, or the Goal

1. Select the node (e.g. `FloorStart`, `Platform`, or `Goal`).
2. In the Inspector, find the **Size** property.
3. Change the X value (width) and Y value (height).

### Adding New Elements

1. Right-click `Level01Nodes` in the Scene tree.
2. Choose **Add Child Node** (or press Ctrl+A).
3. In the search box, type one of:
   - `LevelFloorSegment`
   - `LevelPlatform`
   - `LevelCheckpoint`
   - `LevelGoal`
   - `LevelGrappleAnchor`
   - `LevelChainLink`
4. Double-click the node type to add it.
5. Move it in the 2D viewport to place it.

### Deleting Something

1. Select the node in the Scene tree.
2. Press **Delete** (or right-click → Delete Node).

### Duplicating Something

1. Select the node.
2. Press **Ctrl+D** to duplicate.
3. Drag the new copy to a new position.

---

## Part 4: Save and Test

1. **Save** the scene: **Scene → Save Scene** (or Ctrl+S).
2. Run the **main game**: open your main game scene and press **F5**, or use your usual play setup.
3. Start Level 1 — it will load from `level_01_nodes.tscn`.
4. Test movement, checkpoints, platforms, grapple, and goal.

---

## Part 5: Suggested Layout Tips

- **Floor segments**: At least one floor near the left so the player can spawn.
- **Gap / pit**: Put a gap between floor segments. Add a **ChainLink** or **GrappleAnchor** above it for recovery.
- **Platforms**: Place them so players can jump across gaps.
- **Checkpoint**: Place near the start and before difficult sections.
- **Goal**: Usually near the right side of the level.

---

## Quick Reference: File Locations

```
main_game/levels/
├── level_01_nodes.tscn    ← Open this to edit Level 1
├── nodes/
│   ├── level_floor_segment.gd
│   ├── level_platform.gd
│   ├── level_checkpoint.gd
│   ├── level_goal.gd
│   ├── level_grapple_anchor.gd
│   └── level_chain_link.gd
└── node_level_loader.gd
```

---

## Troubleshooting

**Nothing visible in the 2D view?**  
Zoom out (mouse wheel). The level can be wide (e.g. 2000+ pixels).

**Game uses the old level?**  
Ensure `level_01_nodes.tscn` exists and is saved. Node-based scenes override TileMap and config.

**Can’t find the level node types when adding?**  
Check that the scripts in `nodes/` load without errors. Fix any missing files or syntax errors.
