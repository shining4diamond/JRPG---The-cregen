class_name BattleAI
extends Node

enum AIBehavior { RANDOM, WEAKEST, STRONGEST, LOWEST_HP }

@export var behavior: AIBehavior = AIBehavior.RANDOM
var manager: BattleManager

func _init(p_manager: BattleManager):
	manager = p_manager

func choose_target() -> Character:
	var turn_mgr = manager.turn_manager
	if not turn_mgr:
		return null
	
	var alive_players = turn_mgr.player_battlers.filter(
		func(p): return is_instance_valid(p) and not p.state.isDead
	)
	
	if alive_players.is_empty():
		return null
	
	match behavior:
		AIBehavior.RANDOM:
			return alive_players.pick_random()
		AIBehavior.WEAKEST:
			return _get_weakest(alive_players)
		AIBehavior.STRONGEST:
			return _get_strongest(alive_players)
		AIBehavior.LOWEST_HP:
			return _get_lowest_hp(alive_players)
	
	return alive_players.pick_random()

func _get_weakest(targets: Array) -> Character:
	return targets.reduce(func(a, b): 
		return a if a.stats.attack < b.stats.attack else b
	)

func _get_strongest(targets: Array) -> Character:
	return targets.reduce(func(a, b): 
		return a if a.stats.attack > b.stats.attack else b
	)

func _get_lowest_hp(targets: Array) -> Character:
	return targets.reduce(func(a, b): 
		return a if a.stats.current_hp < b.stats.current_hp else b
	)
