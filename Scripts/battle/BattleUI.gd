class_name BattleUI
extends Node

const ENEMY_HP_BAR_SCENE = "res://Scenes/ui/HP_ProgressBar_Enemy.tscn"
const ENEMY_HP_BAR_SCENE_NAME = "HP_ProgressBar_Enemy"

var manager: BattleManager

func _init(p_manager: BattleManager):
	manager = p_manager

func show_select_button(show: bool):
	var turn_mgr = manager.turn_manager
	if not turn_mgr:
		return
	
	for character in turn_mgr.enemy_battlers:
		if is_instance_valid(character) and not character.state.isDead:
			var button = character.get_node_or_null("Sprite2D/Select_Button")
			if button:
				button.visible = show
			
			var enemy_select_button = _get_enemy_select(character.stats.party_member)
			if enemy_select_button:
				enemy_select_button.grab_focus()

func show_battle_hud(show: bool):
	if is_instance_valid(manager.battle_hud):
		var container = manager.battle_hud.get_node_or_null("%BattleOptions_Container")
		if container:
			container.visible = show
		container = manager.battle_hud.get_node_or_null("%EnemyContainer")
		if container:
			container.visible = show

func setup_enemy_buttons(enemies: Array[Character]):
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var button = enemy.get_node_or_null("Sprite2D/Select_Button")
		if button:
			# Usa callable per evitare riferimenti diretti
			button.pressed.connect(
				func(): manager.select_enemy_pressed.emit(enemy)
			)

func _show_battle_end_hud(message: String):
	if is_instance_valid(manager.battleend_hud) and \
	   is_instance_valid(manager.battleend_label):
		manager.battleend_hud.show()
		manager.battleend_label.text = message
		show_battle_hud(false)
		show_select_button(false)

func _toggle_combat_options_buttons():
	if is_instance_valid(manager.attack_button):
		manager.attack_button.disabled = not manager.attack_button.disabled

	if is_instance_valid(manager.skip_button):
		manager.skip_button.disabled = not manager.skip_button.disabled


func _add_ui_to_enemy(entity: Character):
	_add_hp_bar_to_enemy(entity)
	_toggle_select_button_to_enemy(entity)

func _add_hp_bar_to_enemy(entity: Character):
	if not is_instance_valid(entity):
		return

	var ui_scene = load(ENEMY_HP_BAR_SCENE) as PackedScene
	if not ui_scene:
		push_error("Cannot load enemy HP bar scene!")
		return
	
	var hp_bar = ui_scene.instantiate()
	entity.add_child(hp_bar)
	hp_bar.max_value = entity.stats.max_hp
	hp_bar.value = entity.stats.current_hp

func _toggle_select_button_to_enemy(entity: Character, visible: bool = true):
	if not is_instance_valid(entity):
		return
	
	var enemy_select_button = _get_enemy_select(entity.stats.party_member)
	if enemy_select_button:
			enemy_select_button.visible = visible
			enemy_select_button.disabled = false
		

func _get_enemy_select(party_member:int):
	match party_member:
		-1:
			return manager.enemy_select_1
		-2:
			return manager.enemy_select_2
		-3:
			return manager.enemy_select_3
	return null

func _focus_enemy(party_member:int):
	var character = _return_enemy_on_party_member(party_member)
	character.battleAction._on_select_button_mouse_entered()
	
	_get_enemy_select(party_member).grab_focus()
	return character

func _unfocus_enemy(party_member:int):
	var character = _return_enemy_on_party_member(party_member)
	character.battleAction._on_select_button_mouse_exited()

func _return_enemy_on_party_member(party_member:int):
	var turn_mgr = manager.turn_manager
	if not turn_mgr:
		return
	
	for character in turn_mgr.enemy_battlers:
		if character.stats.party_member == party_member:
			return character


func _remove_ui_from_enemy(entity: Character):
	if not is_instance_valid(entity):
		return
	
	if not entity.has_node(ENEMY_HP_BAR_SCENE_NAME):
		return
		
	var hpbar = entity.get_node(ENEMY_HP_BAR_SCENE_NAME)
	entity.remove_child(hpbar)
	hpbar.queue_free()
	
	_toggle_select_button_to_enemy(entity, false)
	
