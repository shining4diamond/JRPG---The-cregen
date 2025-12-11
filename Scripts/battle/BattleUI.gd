class_name BattleUI
extends Node

var parent_node : Node2D

func _init(p_parent: Node2D):
	parent_node = p_parent


func show_select_button(show:bool):
	if show:
		for character in parent_node.turn_manager.enemy_battler:
			if not character.state.isDead:
				character.get_node("Sprite2D/Select_Button").show()
	else:
		for character in parent_node.turn_manager.enemy_battler:
			character.get_node("Sprite2D/Select_Button").hide()


func show_battle_hud(show:bool):
	if show:
			parent_node.battle_hud.get_node("%BattleOptions_Container").show()
	else:
			parent_node.battle_hud.get_node("%BattleOptions_Container").hide()


func setup_enemy_buttons(enemies: Array[Character]):
	parent_node.turn_manager.enemy_battler = enemies
	for enemy in enemies:
		var button = enemy.get_node("Sprite2D/Select_Button")
		button.pressed.connect(parent_node._on_select_enemy_button_pressed.bind(enemy))


func _show_battle_end_hud(message: String) -> void:
	parent_node.battleend_hud.show()
	parent_node.battleend_label.text = message
	show_battle_hud(false)
	show_select_button(false)


func _toggle_combat_options_buttons():
	parent_node.attack_button.disabled = false if parent_node.attack_button.disabled else true
	parent_node.skip_button.disabled = false if parent_node.skip_button.disabled else true
