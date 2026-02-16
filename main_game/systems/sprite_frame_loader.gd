class_name SpriteFrameLoader
extends RefCounted

## Loads sprite frames for character animation
## Checks for AI-generated sprites, falls back to placeholders

const SPRITE_PATHS = {
	"player": {
		"idle": "res://assets/sprites/player/player_idle.png",
		"walk_mid": "res://assets/sprites/player/player_walk_mid.png",
		"walk_extended": "res://assets/sprites/player/player_walk_extended.png",
		"attack_windup": "res://assets/sprites/player/player_attack_windup.png",
		"attack_strike": "res://assets/sprites/player/player_attack_strike.png",
	},
	"enemy": {
		"idle": "res://assets/sprites/enemy/enemy_idle.png",
		"walk_mid": "res://assets/sprites/enemy/enemy_walk_mid.png",
		"walk_extended": "res://assets/sprites/enemy/enemy_walk_extended.png",
	}
}

static func load_character_frames(character_type: String) -> Dictionary:
	"""Load sprite frames for a character type (player/enemy).
	Returns Dictionary with keys: idle, walk_mid, walk_extended, attack_windup, attack_strike
	Falls back to placeholders if base frames not found.
	"""
	var frames = {}
	var paths = SPRITE_PATHS.get(character_type, {})

	# Required base frames
	var required_frames = ["idle", "walk_mid", "walk_extended"]
	# Optional attack frames
	var optional_frames = ["attack_windup", "attack_strike"]

	# Try to load required frames
	for frame_name in required_frames:
		var path = paths.get(frame_name, "")
		if not path.is_empty() and ResourceLoader.exists(path):
			var texture = load(path) as Texture2D
			if texture:
				frames[frame_name] = texture
				print("[SpriteFrameLoader] Loaded %s frame: %s" % [character_type, frame_name])
			else:
				print("[SpriteFrameLoader] Failed to load %s: %s" % [character_type, path])
		else:
			print("[SpriteFrameLoader] Frame not found: %s" % path)

	# If we got all required frames, try loading optional ones
	if frames.size() == 3:
		for frame_name in optional_frames:
			var path = paths.get(frame_name, "")
			if not path.is_empty() and ResourceLoader.exists(path):
				var texture = load(path) as Texture2D
				if texture:
					frames[frame_name] = texture
					print("[SpriteFrameLoader] Loaded %s frame: %s" % [character_type, frame_name])
		return frames

	# Otherwise, create placeholders
	print("[SpriteFrameLoader] Using placeholders for %s (frames found: %d/3)" % [character_type, frames.size()])
	return _create_placeholder_frames(character_type)

static func _create_placeholder_frames(character_type: String) -> Dictionary:
	"""Create simple placeholder frames for testing."""
	var base_color = Color(0.6, 0.4, 0.8) if character_type == "player" else Color(0.8, 0.3, 0.3)
	return SpriteAnimator.create_placeholder_frames(base_color)

static func has_custom_frames(character_type: String) -> bool:
	"""Check if custom sprite frames exist for this character."""
	var paths = SPRITE_PATHS.get(character_type, {})
	for frame_name in ["idle", "walk_mid", "walk_extended"]:
		var path = paths.get(frame_name, "")
		if path.is_empty() or not ResourceLoader.exists(path):
			return false
	return true

static func get_frame_status() -> String:
	"""Get a status report of which frames are loaded."""
	var status = []

	for char_type in ["player", "enemy"]:
		var has_frames = has_custom_frames(char_type)
		var icon = "✅" if has_frames else "⚠️"
		status.append("%s %s: %s" % [icon, char_type.capitalize(), "Custom sprites" if has_frames else "Placeholders"])

	return "\n".join(status)
