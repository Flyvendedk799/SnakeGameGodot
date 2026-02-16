# Sprite Frame Setup Guide

## How to Add Your AI-Generated Character Frames

Once you have the 3 frames from AI, follow these steps:

### 1. Save Your Sprite Frames

Save the AI-generated images in this folder structure:
```
assets/sprites/player/
  ├── player_idle.png
  ├── player_walk_mid.png
  └── player_walk_extended.png
```

**Image Requirements:**
- Format: PNG with transparency
- Size: Recommended 64x64 or 128x128 pixels (consistent size for all 3)
- Facing: Character facing RIGHT (code will flip for left movement)
- Background: Transparent

### 2. Frame Descriptions for AI Generation

When prompting AI, use these descriptions:

**Frame 1 - Idle Pose:**
```
"Character standing idle pose, side view facing right, arms at sides,
neutral stance, pixel art style, transparent background"
```

**Frame 2 - Walk Mid:**
```
"Same character, mid-walk pose, side view facing right, one leg forward
one leg back, arms swinging naturally, pixel art style, transparent background"
```

**Frame 3 - Walk Extended:**
```
"Same character, extended walk pose, side view facing right, front leg
fully extended, back leg pushing off, arms opposite to legs,
pixel art style, transparent background"
```

### 3. Test the Animation

Once you save the frames, the game will automatically:
- ✅ Load the 3 frames
- ✅ Interpolate between them at 60fps
- ✅ Add squash/stretch on steps
- ✅ Add subtle bob and tilt
- ✅ Apply cel-shading and outline effects

### 4. Frame Fallback System

If frames aren't found, the system will:
1. Try to load custom frames from `assets/sprites/player/`
2. Fall back to the current sprite texture
3. Generate simple placeholder rectangles for testing

## Animation Cycle Breakdown

The system creates a smooth walk cycle from your 3 frames:

```
Walk Cycle (1 second = 6 steps):
0.00s - 0.17s: idle → walk_mid     (step starts)
0.17s - 0.33s: walk_mid → extended (foot extends)
0.33s - 0.50s: extended → walk_mid (foot lands)
0.50s - 0.67s: walk_mid → idle     (other foot rises)
... repeat ...
```

## Advanced: Creating Frame Variations

Once you have the base 3 frames, you can create variations:

**Jump Frame:** Use the "extended" pose (legs stretched)
**Land Frame:** Use the "idle" pose (compressed)
**Run Frames:** Same 3 frames, played faster with more squash/stretch

The `SpriteAnimator` handles all timing and blending automatically!

## Tips for Best Results

1. **Consistent Style:** All 3 frames should match in:
   - Character proportions
   - Line thickness
   - Color palette
   - Shading style

2. **Clear Silhouette:** Character should be recognizable in silhouette

3. **Readable Action:** Poses should clearly show movement even without animation

4. **Center Pivot:** Keep character centered in the frame (code handles positioning)

## Quick Test

To test with placeholder frames before AI generation:
1. Run the game
2. System uses simple colored rectangles as placeholders
3. Verify animation timing and feel
4. Replace with AI-generated sprites when ready

---

**Ready to see it in action?** Just drop your 3 PNG files in `assets/sprites/player/` and restart the game! 🎮
