class_name WaveDirector
extends Node

var game = null
var current_wave: int = 0
var spawn_queue: Array = []
var spawn_timer: float = 0.0
var spawn_interval: float = 1.0
var enemies_spawned: int = 0
var enemies_to_spawn: int = 0
var wave_active: bool = false

func setup(game_ref):
	game = game_ref

func start_wave(wave_number: int):
	current_wave = wave_number
	var wave_info = WaveData.get_wave(wave_number)
	spawn_queue = []
	for entry in wave_info.enemies:
		spawn_queue.append({"type": entry.type, "count": entry.count})
	spawn_interval = wave_info.spawn_delay
	spawn_timer = 0.0
	enemies_spawned = 0
	enemies_to_spawn = 0
	for entry in spawn_queue:
		enemies_to_spawn += entry.count
	wave_active = true

func update(delta: float):
	if not wave_active:
		return
	if spawn_queue.is_empty():
		return
	spawn_timer -= delta
	if spawn_timer <= 0:
		_spawn_next_enemy()
		spawn_timer = spawn_interval

func _spawn_next_enemy():
	if spawn_queue.is_empty():
		return
	var entry = spawn_queue[0]
	var enemy = EnemyEntity.new()
	var stats = EnemyData.get_stats(entry.type)
	enemy.initialize(entry.type, stats)
	enemy.position = game.map.get_random_spawn_point()
	game.enemy_container.add_child(enemy)
	enemies_spawned += 1
	entry.count -= 1
	if entry.count <= 0:
		spawn_queue.pop_front()

func is_wave_complete() -> bool:
	return wave_active and spawn_queue.is_empty() and game.enemy_container.get_child_count() == 0

func stop():
	wave_active = false
	spawn_queue.clear()
