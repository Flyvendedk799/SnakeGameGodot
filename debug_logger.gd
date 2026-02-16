extends Node
## Writes logs to project folder so you can share/open them easily.
## Log file: SnakeGameGodot/debug_output.log

const LOG_PATH = "user://debug_output.log"
var _file: FileAccess
var _frame_count: int = 0
var _fps_log_timer: float = 0.0

func _ready():
	# Write to project root so it's in your workspace (AI can read it)
	var proj_log = ProjectSettings.globalize_path("res://debug_output.log")
	_file = FileAccess.open(proj_log, FileAccess.READ_WRITE)  # Append: file must exist
	if not _file:
		_file = FileAccess.open(proj_log, FileAccess.WRITE)  # Create new
	if not _file:
		_file = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if not _file:
		_file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if _file:
		_file.seek_end()
	if _file:
		write_log("--- Session started %s ---" % Time.get_datetime_string_from_system())

func _process(delta: float):
	if not _file:
		return
	_fps_log_timer += delta
	_frame_count += 1
	if _fps_log_timer >= 5.0:  # Log FPS every 5 seconds (reduces disk I/O)
		_fps_log_timer = 0.0
		var fps = Engine.get_frames_per_second()
		var pt = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		write_log("FPS: %d  Process: %.1f ms  Frame: %d" % [fps, pt, _frame_count])

func log(msg: String):
	"""Alias for write_log - use DebugLogger.log() from other scripts."""
	write_log(msg)

func write_log(msg: String):
	print(msg)
	if _file:
		_file.seek_end()
		_file.store_line("[%s] %s" % [Time.get_time_string_from_system(), msg])
		_file.flush()

func log_error(msg: String):
	write_log("ERROR: " + msg)
	push_error(msg)

func _exit_tree():
	if _file:
		_file.close()
