# Snake Game - Godot Edition

A smooth, cartoony snake game made with Godot 4.x featuring buttery-smooth interpolated movement.

## Installation & Running

### 1. Install Godot 4.x
- Download from: https://godotengine.org/download
- Choose **Godot 4.1** or later
- Extract and run the executable

### 2. Open This Project
1. Launch Godot
2. Click "Open" in the Project Manager
3. Navigate to this folder: `C:\Users\tobia\Desktop\SnakeGameGodot`
4. Click "Open Folder" (or "Open") to import the project

### 3. Run the Game
1. Click the "▶ Play" button in the top right (or press F5)
2. Game will launch in a window

## Controls

- **Arrow Keys**: Move the snake
- **Space/Enter**: Restart after game over
- **ESC**: Quit game

## Features

✨ **Smooth Movement**: Godot's rendering pipeline provides buttery-smooth 60+ FPS movement with proper interpolation

🎨 **Cartoony Graphics**: Vibrant sky blue background with bold-outlined shapes

🟢 **Snake**: Green segments with dark outlines and subtle shading

🔴 **Food**: Vibrant red circles with dark outlines and shiny highlights

🌟 **Glow Effects**: Pulsing orange glow around food

## Performance

This Godot version will feel MUCH smoother than the Pygame version because:
- GPU-accelerated rendering
- Proper frame timing and interpolation
- Godot's optimized 2D engine
- No Python GIL limitations

## Project Structure

```
SnakeGameGodot/
├── project.godot          # Project configuration
├── constants.gd           # Game constants and colors
├── game.gd               # Main game logic
├── scenes/
│   └── main.tscn         # Main game scene
└── README.md             # This file
```

## Customization

To change colors, edit `constants.gd` and modify the `COLORS` dictionary.

To change game speed, edit `INITIAL_SPEED` in `constants.gd` (default: 8).

## Troubleshooting

**Black screen?**
- Make sure the main scene is set correctly in Project Settings > Application > Run > Main Scene
- Should be `res://scenes/main.tscn`

**Input not working?**
- Make sure your keyboard layout is set to US English
- Check that Godot is focused (click in the game window)

**Game is slow?**
- This shouldn't happen! Godot is much faster than Pygame
- Try changing Renderer to "mobile" (should already be set) in Project Settings > Rendering

## Next Steps

You can expand this game with:
- Sound effects (Godot has excellent audio support)
- Particle system (we removed complex particles for simplicity, but Godot's built-in is great)
- Difficulty levels
- High score saving
- Different game modes

Enjoy your smooth snake game! 🐍
