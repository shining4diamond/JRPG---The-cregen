class_name TurnManager
extends Node

var current_battler: Node2D
var current_turn_index: int
var battlers
var player_battlers = []
var enemy_battler = []

# Componenti
var parent_node: Node2D
var ui: BattleUI
var ai: BattleAI
var combat: BattleCombat

func _init(p_parent: Node2D, p_ui: BattleUI, p_ai: BattleAI, p_combat: BattleCombat):
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

func _next_turn() -> void:
	var last_battler = current_battler
	current_turn_index = (current_turn_index + 1) % battlers.size()
	current_battler = battlers[current_turn_index]
	if _check_for_battle_end() == false:
		if current_battler.state.isDead:
				_next_turn()
				return
		await parent_node.get_tree().create_timer(2.0).timeout
		_update_turn()
		parent_node.emit_signal("toggle_focus_on_player", last_battler.stats.party_member)
		parent_node.emit_signal("toggle_focus_on_player", current_battler.stats.party_member)





func _check_for_battle_end()->bool:
	# --- CHECK ENEMY DEFEAT ---
	var all_enemies_dead := true
	for enemy in enemy_battler:
		if not enemy.state.isDead:
			all_enemies_dead = false
			break

	if all_enemies_dead:
		parent_node.ui._show_battle_end_hud("Victory")
		return true

	# --- CHECK PLAYER DEFEAT ---
	var all_players_dead := true
	for character in player_battlers:
		if not character.state.isDead:
			all_players_dead = false
			break

	if all_players_dead:
		parent_node.ui._show_battle_end_hud("Defeat")
		return true

	return false
