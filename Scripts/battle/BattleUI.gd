class_name BattleUI
extends Node

const ENEMY_HP_BAR_SCENE = "res://Scenes/ui/HP_ProgressBar_Enemy.tscn"

var parent_node : BattleManager

func _init(p_parent: BattleManager):
	parent_node = p_parent


func show_select_button(show: bool):
	
	if not parent_node.turn_manager:
		return
	
	for character in parent_node.turn_manager.enemy_battlers:
		if not character.state.isDead:
			character.get_node("Sprite2D/Select_Button").visible = show


func show_battle_hud(show: bool):
	if parent_node.battle_hud:
		parent_node.battle_hud.get_node("%BattleOptions_Container").visible = show


func setup_enemy_buttons(enemies: Array[Character]):
#	parent_node.turn_manager.enemy_battlers = enemies
	for enemy in enemies:
		var button = enemy.get_node("Sprite2D/Select_Button")
		if button:
			button.pressed.connect(parent_node._on_select_enemy_button_pressed.bind(enemy))


func _show_battle_end_hud(message: String) -> void:
	if parent_node.battleend_hud and parent_node.battleend_label:
		parent_node.battleend_hud.show()
		parent_node.battleend_label.text = message
		show_battle_hud(false)
		show_select_button(false)


func _toggle_combat_options_buttons():
	parent_node.attack_button.disabled = false if parent_node.attack_button.disabled else true
	parent_node.skip_button.disabled = false if parent_node.skip_button.disabled else true


func _add_hp_bar_to_enemy(entity: Character):
	var ui_scene = load(ENEMY_HP_BAR_SCENE) as PackedScene
	var hp_bar = ui_scene.instantiate()
	entity.add_child(hp_bar)
	hp_bar.max_value = entity.stats.max_hp
	hp_bar.value = entity.stats.current_hp
