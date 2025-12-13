class_name TurnManager
extends Node

var current_battler: Node2D
var current_turn_index: int
var battlers
var player_battlers = []
var enemy_battlers = []

# Componenti
var parent_node: BattleManager
var ui: BattleUI
var ai: BattleAI
var combat: BattleCombat

func _init(p_parent: BattleManager, p_ui: BattleUI, p_ai: BattleAI, p_combat: BattleCombat):
	parent_node = p_parent
	ui = p_ui
	ai = p_ai
	combat = p_combat


func sort_battlers_by_speed():
	battlers.sort_custom(func(a, b): return a.stats.turn_speed > b.stats.turn_speed)


func _update_turn() -> void:
	if is_player_turn():
		ui.show_battle_hud(true)
	else:
		ui.show_battle_hud(false)
		var target = ai.choose_target()
		if target:
			await combat.attack(current_battler, target)
		_next_turn()

func is_player_turn() -> bool:
	return current_battler.stats.character_type == StatsResource.CharacterType.PLAYER

func _next_turn(skipTimer:bool = false) -> void:
	var last_battler = current_battler
	current_turn_index = (current_turn_index + 1) % battlers.size()
	current_battler = battlers[current_turn_index]

	if _check_for_battle_end() == true:
		return

	if current_battler.state.isDead:
		_next_turn()
		return

	if not skipTimer:
		await parent_node.get_tree().create_timer(1.0).timeout
	_update_turn()

	move_character(last_battler)
	parent_node.emit_signal("toggle_focus_on_player", last_battler.stats.party_member)
	move_character(current_battler)
	parent_node.emit_signal("toggle_focus_on_player", current_battler.stats.party_member)



func move_character(battler: Node2D):
	if battler.stats.character_type == 0:
		battler.battleMovement.toggle_focus_movement()


func _check_for_battle_end() -> bool:
	var all_enemies_dead = enemy_battlers.all(func(e): return e.state.isDead)
	if all_enemies_dead:
		ui._show_battle_end_hud("Victory")
		return true
	
	var all_players_dead = player_battlers.all(func(p): return p.state.isDead)
	if all_players_dead:
		ui._show_battle_end_hud("Defeat")
		return true
	
	return false
