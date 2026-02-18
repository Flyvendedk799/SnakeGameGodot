class_name BehaviorTree
extends RefCounted

## Phase 6.1: Lightweight Behavior Tree for enemy AI
## Architecture: Selector → tries children until one succeeds
##               Sequence → tries children until one fails
##               Leaf → actual action/condition check
##
## Usage:
##   var bt = BehaviorTree.new()
##   bt.root = BehaviorTree.Selector.new([
##       BehaviorTree.Sequence.new([
##           BehaviorTree.Condition.new(func(bb): return bb.target != null),
##           BehaviorTree.Action.new(func(bb, delta): return _attack(bb, delta)),
##       ]),
##       BehaviorTree.Action.new(func(bb, delta): return _wander(bb, delta))
##   ])
##   bt.tick(blackboard, delta)

enum Status { RUNNING, SUCCESS, FAILURE }

var root: Node = null
var blackboard: Dictionary = {}   # Shared state: {target, last_known_pos, health_ratio, ...}

func tick(delta: float) -> Status:
	if root == null:
		return Status.FAILURE
	return root.evaluate(blackboard, delta)

# ---------------------------------------------------------------------------
# Node types
# ---------------------------------------------------------------------------

class BTNode:
	extends RefCounted
	func evaluate(_bb: Dictionary, _delta: float) -> int:
		return BehaviorTree.Status.FAILURE

class Selector extends BTNode:
	"""Tries each child; returns SUCCESS on first success, FAILURE if all fail."""
	var children: Array = []
	func _init(c: Array):
		children = c
	func evaluate(bb: Dictionary, delta: float) -> int:
		for child in children:
			var result = child.evaluate(bb, delta)
			if result != BehaviorTree.Status.FAILURE:
				return result
		return BehaviorTree.Status.FAILURE

class Sequence extends BTNode:
	"""Tries each child; returns FAILURE on first failure, SUCCESS if all succeed."""
	var children: Array = []
	func _init(c: Array):
		children = c
	func evaluate(bb: Dictionary, delta: float) -> int:
		for child in children:
			var result = child.evaluate(bb, delta)
			if result == BehaviorTree.Status.FAILURE:
				return BehaviorTree.Status.FAILURE
		return BehaviorTree.Status.SUCCESS

class Condition extends BTNode:
	"""Returns SUCCESS/FAILURE based on a callable(bb) -> bool."""
	var check_fn: Callable
	func _init(fn: Callable):
		check_fn = fn
	func evaluate(bb: Dictionary, _delta: float) -> int:
		if check_fn.call(bb):
			return BehaviorTree.Status.SUCCESS
		return BehaviorTree.Status.FAILURE

class Action extends BTNode:
	"""Executes callable(bb, delta) -> Status. Returns RUNNING if still executing."""
	var action_fn: Callable
	func _init(fn: Callable):
		action_fn = fn
	func evaluate(bb: Dictionary, delta: float) -> int:
		return action_fn.call(bb, delta)

class Inverter extends BTNode:
	"""Inverts child result (SUCCESS↔FAILURE, RUNNING stays RUNNING)."""
	var child: BTNode
	func _init(c: BTNode):
		child = c
	func evaluate(bb: Dictionary, delta: float) -> int:
		var result = child.evaluate(bb, delta)
		if result == BehaviorTree.Status.SUCCESS:
			return BehaviorTree.Status.FAILURE
		if result == BehaviorTree.Status.FAILURE:
			return BehaviorTree.Status.SUCCESS
		return result

class Cooldown extends BTNode:
	"""Wraps child with a cooldown — prevents re-triggering for 'wait_time' seconds."""
	var child: BTNode
	var wait_time: float
	var _timer: float = 0.0
	var _cooling: bool = false
	func _init(c: BTNode, t: float):
		child = c
		wait_time = t
	func evaluate(bb: Dictionary, delta: float) -> int:
		if _cooling:
			_timer -= delta
			if _timer <= 0.0:
				_cooling = false
			else:
				return BehaviorTree.Status.FAILURE
		var result = child.evaluate(bb, delta)
		if result == BehaviorTree.Status.SUCCESS:
			_cooling = true
			_timer = wait_time
		return result

# ---------------------------------------------------------------------------
# Pre-built trees for enemy variants
# ---------------------------------------------------------------------------

static func make_melee_rusher_tree(enemy: Object) -> BehaviorTree:
	"""Aggressive melee: In range → attack, else move toward target."""
	var bt = BehaviorTree.new()
	bt.root = BehaviorTree.Selector.new([
		# Attack if in range
		BehaviorTree.Sequence.new([
			BehaviorTree.Condition.new(func(bb): return bb.get("target") != null and not bb.target.is_dead and bb.get("in_attack_range", false)),
			BehaviorTree.Action.new(func(bb, delta): return _do_attack(enemy, bb, delta)),
		]),
		# Chase target
		BehaviorTree.Sequence.new([
			BehaviorTree.Condition.new(func(bb): return bb.get("target") != null and not bb.target.is_dead),
			BehaviorTree.Action.new(func(bb, delta): return _do_chase(enemy, bb, delta)),
		]),
		# Wander if no target
		BehaviorTree.Action.new(func(bb, delta): return _do_wander(enemy, bb, delta)),
	])
	return bt

static func make_ranged_kiter_tree(enemy: Object) -> BehaviorTree:
	"""Ranged kiter: If too close, flee; if in ranged range, shoot; else approach."""
	var bt = BehaviorTree.new()
	bt.root = BehaviorTree.Selector.new([
		# Flee if player too close
		BehaviorTree.Sequence.new([
			BehaviorTree.Condition.new(func(bb): return bb.get("target") != null and bb.get("too_close", false)),
			BehaviorTree.Action.new(func(bb, delta): return _do_flee(enemy, bb, delta)),
		]),
		# Shoot if in ranged range
		BehaviorTree.Sequence.new([
			BehaviorTree.Condition.new(func(bb): return bb.get("target") != null and bb.get("in_ranged_range", false)),
			BehaviorTree.Cooldown.new(
				BehaviorTree.Action.new(func(bb, delta): return _do_ranged_attack(enemy, bb, delta)),
				enemy.attack_cooldown if enemy.get("attack_cooldown") else 1.2
			),
		]),
		# Approach
		BehaviorTree.Action.new(func(bb, delta): return _do_approach(enemy, bb, delta)),
	])
	return bt

static func make_heavy_tree(enemy: Object) -> BehaviorTree:
	"""Heavy slow enemy: charge when ready, otherwise approach slowly."""
	var bt = BehaviorTree.new()
	bt.root = BehaviorTree.Sequence.new([
		BehaviorTree.Condition.new(func(bb): return bb.get("target") != null and not bb.target.is_dead),
		BehaviorTree.Selector.new([
			# Charge attack with cooldown
			BehaviorTree.Cooldown.new(
				BehaviorTree.Sequence.new([
					BehaviorTree.Condition.new(func(bb): return bb.get("in_attack_range", false)),
					BehaviorTree.Action.new(func(bb, delta): return _do_heavy_attack(enemy, bb, delta)),
				]),
				enemy.attack_cooldown * 2.0 if enemy.get("attack_cooldown") else 2.0
			),
			# Slow approach
			BehaviorTree.Action.new(func(bb, delta): return _do_slow_approach(enemy, bb, delta)),
		])
	])
	return bt

# ---------------------------------------------------------------------------
# Action implementations (static helpers)
# ---------------------------------------------------------------------------

static func _do_attack(enemy: Object, _bb: Dictionary, _delta: float) -> int:
	if enemy.get("attack_timer") != null and enemy.attack_timer <= 0:
		enemy.attack_timer = enemy.attack_cooldown
		return BehaviorTree.Status.SUCCESS
	return BehaviorTree.Status.RUNNING

static func _do_chase(enemy: Object, bb: Dictionary, delta: float) -> int:
	var target = bb.get("target")
	if target == null:
		return BehaviorTree.Status.FAILURE
	var dir = (target.position - enemy.position).normalized()
	enemy.velocity.x = dir.x * enemy.move_speed
	enemy.last_dir = dir
	return BehaviorTree.Status.RUNNING

static func _do_flee(enemy: Object, bb: Dictionary, _delta: float) -> int:
	var target = bb.get("target")
	if target == null:
		return BehaviorTree.Status.FAILURE
	var flee_dir = (enemy.position - target.position).normalized()
	enemy.velocity.x = flee_dir.x * enemy.move_speed * 1.2
	return BehaviorTree.Status.RUNNING

static func _do_ranged_attack(enemy: Object, _bb: Dictionary, _delta: float) -> int:
	# Signal to enemy to fire projectile
	if enemy.has_method("_fire_projectile"):
		enemy._fire_projectile()
	return BehaviorTree.Status.SUCCESS

static func _do_approach(enemy: Object, bb: Dictionary, _delta: float) -> int:
	return _do_chase(enemy, bb, 0.0)

static func _do_slow_approach(enemy: Object, bb: Dictionary, _delta: float) -> int:
	var target = bb.get("target")
	if target == null:
		return BehaviorTree.Status.FAILURE
	var dir = (target.position - enemy.position).normalized()
	enemy.velocity.x = dir.x * enemy.move_speed * 0.6  # Heavy: 60% speed
	enemy.last_dir = dir
	return BehaviorTree.Status.RUNNING

static func _do_heavy_attack(enemy: Object, _bb: Dictionary, _delta: float) -> int:
	enemy.attack_timer = enemy.attack_cooldown * 2.0
	return BehaviorTree.Status.SUCCESS

static func _do_wander(enemy: Object, bb: Dictionary, delta: float) -> int:
	# Simple drift — just stay still or pace slowly
	enemy.velocity.x = lerpf(enemy.velocity.x, 0.0, delta * 4.0)
	return BehaviorTree.Status.RUNNING

# ---------------------------------------------------------------------------
# Blackboard update helper (call from enemy each frame)
# ---------------------------------------------------------------------------

static func update_blackboard(enemy: Object, game: Object) -> Dictionary:
	"""Build a fresh blackboard dict from enemy + game state."""
	var target = enemy.get("chase_target")
	var health_ratio = float(enemy.current_hp) / float(maxf(enemy.max_hp, 1))
	var in_range = false
	var in_ranged = false
	var too_close = false

	if target and is_instance_valid(target) and not target.is_dead:
		var dist = enemy.position.distance_to(target.position)
		var attack_r = enemy.get("entity_size") * 3.0 if enemy.get("entity_size") else 40.0
		var ranged_r = enemy.get("ranged_range") if enemy.get("ranged_range") else 120.0
		in_range = dist < attack_r
		in_ranged = dist < ranged_r and not in_range
		too_close = dist < attack_r * 0.5  # For kiters: flee when player is very close

	return {
		"target": target,
		"last_known_pos": target.position if (target and is_instance_valid(target)) else enemy.position,
		"health_ratio": health_ratio,
		"in_attack_range": in_range,
		"in_ranged_range": in_ranged,
		"too_close": too_close,
	}
