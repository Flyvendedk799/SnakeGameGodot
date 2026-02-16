class_name SpatialGrid
extends RefCounted
## Spatial partitioning for fast neighbor queries. Reduces O(n²) to O(n) in combat and targeting.
## Rebuild each frame, then query by position + radius.

const CELL_SIZE: float = 96.0  # ~melee range; tune for balance of cells vs entities per cell

var _enemy_cells: Dictionary = {}  # key "ix,iy" -> Array of EnemyEntity
var _ally_cells: Dictionary = {}   # key "ix,iy" -> Array of AllyEntity
var _player_cells: Dictionary = {} # key "ix,iy" -> Array of PlayerEntity

func _cell_key(ix: int, iy: int) -> String:
	return "%d,%d" % [ix, iy]

func _pos_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(int(pos.x / CELL_SIZE), int(pos.y / CELL_SIZE))

func rebuild(game):
	_enemy_cells.clear()
	_ally_cells.clear()
	_player_cells.clear()
	for e in game.enemy_container.get_children():
		if e.state != EnemyEntity.EnemyState.DEAD and e.state != EnemyEntity.EnemyState.DYING:
			var k = _cell_key(_pos_to_cell(e.position).x, _pos_to_cell(e.position).y)
			if not _enemy_cells.has(k):
				_enemy_cells[k] = []
			_enemy_cells[k].append(e)
	for a in game.ally_container.get_children():
		if a.current_hp > 0:
			var k = _cell_key(_pos_to_cell(a.position).x, _pos_to_cell(a.position).y)
			if not _ally_cells.has(k):
				_ally_cells[k] = []
			_ally_cells[k].append(a)
	var players = []
	if not game.player_node.is_dead:
		players.append(game.player_node)
	if game.p2_joined and game.player2_node and not game.player2_node.is_dead:
		players.append(game.player2_node)
	for p in players:
		var k = _cell_key(_pos_to_cell(p.position).x, _pos_to_cell(p.position).y)
		if not _player_cells.has(k):
			_player_cells[k] = []
		_player_cells[k].append(p)

## Returns enemies within radius of pos. Use for melee, projectiles.
func get_enemies_near(pos: Vector2, radius: float) -> Array:
	var result: Array = []
	var c = _pos_to_cell(pos)
	var cr = ceili(radius / CELL_SIZE)
	var radius_sq = radius * radius
	for dx in range(-cr, cr + 1):
		for dy in range(-cr, cr + 1):
			var k = _cell_key(c.x + dx, c.y + dy)
			var list = _enemy_cells.get(k, [])
			for e in list:
				if pos.distance_squared_to(e.position) <= radius_sq:
					result.append(e)
	return result

## Returns allies within radius of pos.
func get_allies_near(pos: Vector2, radius: float) -> Array:
	var result: Array = []
	var c = _pos_to_cell(pos)
	var cr = ceili(radius / CELL_SIZE)
	var radius_sq = radius * radius
	for dx in range(-cr, cr + 1):
		for dy in range(-cr, cr + 1):
			var k = _cell_key(c.x + dx, c.y + dy)
			var list = _ally_cells.get(k, [])
			for a in list:
				if pos.distance_squared_to(a.position) <= radius_sq:
					result.append(a)
	return result

## Returns players within radius of pos.
func get_players_near(pos: Vector2, radius: float) -> Array:
	var result: Array = []
	var c = _pos_to_cell(pos)
	var cr = ceili(radius / CELL_SIZE)
	var radius_sq = radius * radius
	for dx in range(-cr, cr + 1):
		for dy in range(-cr, cr + 1):
			var k = _cell_key(c.x + dx, c.y + dy)
			var list = _player_cells.get(k, [])
			for p in list:
				if pos.distance_squared_to(p.position) <= radius_sq:
					result.append(p)
	return result
