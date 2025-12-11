class_name BattleAI
extends Node

enum AIBehavior { RANDOM, WEAKEST, STRONGEST, LOWEST_HP }

var behavior: AIBehavior = AIBehavior.RANDOM
var parent_node: Node2D

func _init(p_parent: Node2D):
	parent_node = p_parent

func choose_target() -> Character:
	var alive_players = parent_node.turn_manager.player_battlers.filter(func(p): return not p.state.isDead)
	
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
	var weakest = targets[0]
	for target in targets:
		if target.stats.attack < weakest.stats.attack:
			weakest = target
	return weakest

func _get_strongest(targets: Array) -> Character:
	var strongest = targets[0]
	for target in targets:
		if target.stats.attack > strongest.stats.attack:
			strongest = target
	return strongest

func _get_lowest_hp(targets: Array) -> Character:
	var lowest = targets[0]
	for target in targets:
		if target.stats.current_hp < lowest.stats.current_hp:
			lowest = target
	return lowest
