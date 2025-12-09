class_name BattleManager
extends Node2D

@onready var character: Character = $Character
@onready var player_hpmp: Label = $Character/PlayerHPMP
@onready var battle_hud: CanvasLayer = $Battle_HUD
@onready var battleend_hud: CanvasLayer = $BattleEnd_HUD

@onready var attack_button: Button = $Battle_HUD.get_node("MarginContainer/GridContainer/VBoxContainer/Attack_Button")
@onready var skip_button: Button = $Battle_HUD.get_node("MarginContainer/GridContainer/VBoxContainer/Skip_Button")
@onready var battleend_label: Label = $BattleEnd_HUD.get_node("Panel/VBoxContainer/EndBattleLabel")


var partyCount = 1
var enemyCount = 1
var character_15fps = "res://Scenes/characters/character_15fps.tscn"
var character_14fps = "res://Scenes/characters/character_14fps.tscn"
var hpmp_ui_scenePath = "res://Scenes/battle/HPMP_UI.tscn"

var entities_to_spawn = {
	"1":{
		"scenePath":character_15fps,
		"textureBasePath":"res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/",
		"position":Vector2(350, 173),
		"statsPath":"res://Scripts/characters/Stats/knight_stats.tres",
		"type":"PLAYER"
	},
	"2":{
		"scenePath":character_14fps,
		"textureBasePath":"res://Assets/characters/FREE Character HD Survivor W Bike/",
		"position":Vector2(930, 173),
		"statsPath":"res://Scripts/characters/Stats/survivor_stats.tres",
		"type":"ENEMY"
	},
	"3":{
		"scenePath":character_15fps,
		"textureBasePath":"res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/",
		"position":Vector2(350, 346),
		"statsPath":"res://Scripts/characters/Stats/knight_stats2.tres",
		"type":"PLAYER"
	},
	"4":{
		"scenePath":character_14fps,
		"textureBasePath":"res://Assets/characters/FREE Character HD Survivor W Bike/",
		"position":Vector2(930, 346),
		"statsPath":"res://Scripts/characters/Stats/survivor_stats2.tres",
		"type":"ENEMY"
	},
	"5":{
		"scenePath":character_15fps,
		"textureBasePath":"res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/",
		"position":Vector2(350, 519),
		"statsPath":"res://Scripts/characters/Stats/knight_stats3.tres",
		"type":"PLAYER"
	},
	"6":{
		"scenePath":character_14fps,
		"textureBasePath":"res://Assets/characters/FREE Character HD Survivor W Bike/",
		"position":Vector2(930, 519),
		"statsPath":"res://Scripts/characters/Stats/survivor_stats3.tres",
		"type":"ENEMY"
	}
}

var battlers = []
var player_battlers = []
var enemy_battler = []

var current_turn : Node2D
var current_turn_index : int = 0

func _ready() -> void:
	player_hpmp.stats = character.stats
	
	for entity in entities_to_spawn:
		var scene = load(entities_to_spawn[entity]["scenePath"]) as PackedScene
		var restored_node = scene.instantiate()
		restored_node.textureBasePath = entities_to_spawn[entity]["textureBasePath"]
		self.add_child(restored_node)
		restored_node.global_position = entities_to_spawn[entity]["position"]
		restored_node.state.combatMode = true
		restored_node.stats = load(entities_to_spawn[entity]["statsPath"])
		
		if entities_to_spawn[entity]["type"] == "PLAYER":
			restored_node.stats.character_type = StatsResource.CharacterType.PLAYER
			player_battlers.append(restored_node)
			restored_node.animation.set_blend_positions(Vector2(930, 288))
		else:
			restored_node.stats.character_type = StatsResource.CharacterType.ENEMY
			enemy_battler.append(restored_node)
			restored_node.animation.set_blend_positions(Vector2(350, 288))
		battlers.append(restored_node)
		
		restored_node.get_node("Sprite2D/Select_Button").pressed.connect(
			_on_select_enemy_button_pressed.bind(restored_node)
		)

		scene = load(hpmp_ui_scenePath) as PackedScene
		var ui_node = scene.instantiate()
		restored_node.add_child(ui_node)
		ui_node.get_child(0).stats = restored_node.stats
	
	battlers.sort_custom(_sort_turn_order_ascending)
	current_turn = battlers[0]
	attack_button.pressed.connect(_on_attack_button_pressed)
	Engine.time_scale = 3.0

func _sort_turn_order_ascending(battler_1, battler_2) -> bool:
	if battler_1.stats.turn_speed < battler_2.stats.turn_speed:
		return true
	return false

func _update_turn() -> void:
	if current_turn.stats.character_type == StatsResource.CharacterType.PLAYER:
		show_battle_hud(true)
	else:
		show_battle_hud(false)
		_attacck_random_player_character()
	
func _next_turn() -> void:
	
	current_turn_index = (current_turn_index + 1) % battlers.size()
	current_turn = battlers[current_turn_index]
	if _check_for_battle_end() == false:
		if current_turn.state.isDead:
				_next_turn()
				return
		await get_tree().create_timer(2.0).timeout
		_update_turn()

func show_select_button(show:bool):
	if show:
		for character in enemy_battler:
			if not character.state.isDead:
				character.get_node("Sprite2D/Select_Button").show()
	else:
		for character in enemy_battler:
			character.get_node("Sprite2D/Select_Button").hide()

func show_battle_hud(show:bool):
	if show:
			battle_hud.show()
	else:
			battle_hud.hide()

func _on_select_enemy_button_pressed(selected_character: Character):
	show_battle_hud(false)
	await attack(current_turn, selected_character)
	_next_turn()

func _on_attack_button_pressed():
	show_select_button(true)
	
func attack(attacking: Character, defender: Character):
	show_select_button(false)
	attacking.battleAction.execute_attack()
	await get_tree().create_timer(0.5).timeout
	defender.battleAction.execute_take_damage(attacking)






func _check_for_battle_end()->bool:
	# --- CHECK ENEMY DEFEAT ---
	var all_enemies_dead := true
	for enemy in enemy_battler:
		if not enemy.state.isDead:
			all_enemies_dead = false
			break

	if all_enemies_dead:
		_show_battle_end_hud("Victory")
		return true

	# --- CHECK PLAYER DEFEAT ---
	var all_players_dead := true
	for character in player_battlers:
		if not character.state.isDead:
			all_players_dead = false
			break

	if all_players_dead:
		_show_battle_end_hud("Defeat")
		return true

	return false

func _show_battle_end_hud(message: String) -> void:
	battleend_hud.show()
	battleend_label.text = message
	show_battle_hud(false)
	show_select_button(false)

# AI Nemici
func _attacck_random_player_character() -> void:
	attack(current_turn, player_battlers.pick_random())
	_next_turn()


func _on_button_pressed() -> void:
	get_tree().reload_current_scene()
