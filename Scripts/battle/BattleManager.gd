# ==============================================
# BattleManager.gd - REFACTORED WITH SIGNALS
# ==============================================
class_name BattleManager
extends Node

# ==============================================
# SEGNALI CENTRALIZZATI
# ==============================================
signal entities_spawned(players: Array, enemies: Array)
signal select_enemy_pressed(selected_character: Character)
signal attack_button_pressed()
signal skip_button_pressed()
signal restart_button_pressed()
signal toggle_focus_on_player(party_member: int)
signal request_ai_target()
signal ai_target_chosen(target: Character)
signal combat_attack_requested(attacker: Character, defender: Character)
signal combat_attack_completed()
signal next_turn_requested(skip_timer: bool)
signal show_battle_hud(show: bool)
signal show_select_buttons(show: bool)
signal remove_ui_from_enemy(entity: Character)
signal battle_ended(message: String)

# ==============================================
# CONFIGURAZIONE
# ==============================================
@onready var battle_hud: CanvasLayer = get_parent().get_node("Battle_HUD")
@onready var battleend_hud: CanvasLayer = get_parent().get_node("BattleEnd_HUD")
@onready var attack_button: Button = battle_hud.get_node("%Attack_Button")
@onready var skip_button: Button = battle_hud.get_node("%Skip_Button")
@onready var enemy_select_1: Button = battle_hud.get_node("%Enemy_Select_1")
@onready var enemy_select_2: Button = battle_hud.get_node("%Enemy_Select_2")
@onready var enemy_select_3: Button = battle_hud.get_node("%Enemy_Select_3")
@onready var restart_button: Button = battleend_hud.get_node("%RestartBattleButton")
@onready var battleend_label: Label = battleend_hud.get_node("%EndBattleLabel")

@export_group("Battle Configuration")
@export var battle_data: BattleData

# ==============================================
# VARIABILI LOCALI
# ==============================================
var selected_character: Character

# ==============================================
# COMPONENTI
# ==============================================
var spawner: BattleSpawner
var turn_manager: TurnManager
var ui: BattleUI
var ai: BattleAI
var combat: BattleCombat

# Engine
const time_scale: float = 3.0

# ==============================================
# INITIALIZATION
# ==============================================
func _ready() -> void:
	_validate_configuration()
	_initialize_components()
	_connect_signals()
	_start_battle()

func _validate_configuration():
	if not battle_hud or not battleend_hud:
		push_error("BattleManager: Missing HUD references!")
		return
	
	if not attack_button or not skip_button or not battleend_label:
		push_error("BattleManager: Missing UI button references!")
		return
	
	if not battle_data:
		push_warning("BattleManager: No BattleData provided, using default")
		battle_data = BattleData.create_default()

func _initialize_components():
	spawner = BattleSpawner.new(self)
	ui = BattleUI.new(self)
	ai = BattleAI.new(self)
	combat = BattleCombat.new(self)
	turn_manager = TurnManager.new(self)

func _connect_signals():
	# Segnali UI
	attack_button.pressed.connect(_on_attack_button_pressed)
	skip_button.pressed.connect(_on_skip_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	
	# Segnali Manager
	entities_spawned.connect(_on_entities_spawned)
	select_enemy_pressed.connect(_on_select_enemy_pressed)
	combat_attack_completed.connect(_on_combat_attack_completed)
	request_ai_target.connect(_on_request_ai_target)
	ai_target_chosen.connect(_on_ai_target_chosen)
	next_turn_requested.connect(_on_next_turn_requested)
	show_battle_hud.connect(_on_show_battle_hud)
	show_select_buttons.connect(_on_show_select_buttons)
	remove_ui_from_enemy.connect(_on_remove_ui_from_enemy)
	battle_ended.connect(_on_battle_ended)
	combat_attack_requested.connect(_on_combat_attack_requested)
	
	
	# Connetti componenti
	spawner.all_entities_spawned.connect(func(p, e): entities_spawned.emit(p, e))

func _start_battle():
	Engine.time_scale = time_scale
	spawner.spawn_entities(battle_data.entities_config)

# ==============================================
# SIGNAL HANDLERS
# ==============================================
func _on_entities_spawned(players: Array, enemies: Array):
	turn_manager.initialize_battlers(players, enemies)
	ui.setup_enemy_buttons(enemies)
	
	# Setup HUD
	battle_hud.connect_player_signals()
	for player in players:
		battle_hud.initialize_player_ui(player.stats, player.stats.party_member)
	
	battle_hud.connect_enemy_signals()
	for enemy in enemies:
		battle_hud._update_hp_ui(enemy.stats.current_hp, enemy.stats.party_member)
	
	# Start first turn
	turn_manager.start_first_turn()

func _on_select_enemy_pressed(selected_character: Character):
	show_battle_hud.emit(false)
	combat_attack_requested.emit(turn_manager.get_current_battler(), selected_character)

func _on_combat_attack_requested(attacker: Character, defender: Character):
	await combat.execute_attack(attacker, defender)
	combat_attack_completed.emit()

func _on_combat_attack_completed():
	next_turn_requested.emit(false)

func _on_attack_button_pressed():
	show_select_buttons.emit(true)

func _on_skip_button_pressed():
	next_turn_requested.emit(true)
	ui._toggle_combat_options_buttons()
	await get_tree().create_timer(0.25).timeout
	ui._toggle_combat_options_buttons()

func _on_restart_button_pressed():
	restart_battle()

func _on_request_ai_target():
	var target = ai.choose_target()
	ai_target_chosen.emit(target)

func _on_ai_target_chosen(target: Character):
	if target:
		combat_attack_requested.emit(turn_manager.get_current_battler(), target)

func _on_next_turn_requested(skip_timer: bool):
	turn_manager.advance_turn(skip_timer)

func _on_show_battle_hud(show: bool):
	ui.show_battle_hud(show)

func _on_show_select_buttons(show: bool):
	ui.show_select_button(show)
	
func _on_remove_ui_from_enemy(entity: Character):
	ui._remove_ui_from_enemy(entity)

func _on_battle_ended(message: String):
	ui._show_battle_end_hud(message)

func _on_enemy_select_1_focus():
	selected_character = ui._focus_enemy(-1);

func _on_enemy_select_1_unfocus():
	ui._unfocus_enemy(-1);

func _on_enemy_select_2_focus():
	selected_character = ui._focus_enemy(-2);

func _on_enemy_select_2_unfocus():
	ui._unfocus_enemy(-2);

func _on_enemy_select_3_focus():
	selected_character = ui._focus_enemy(-3);

func _on_enemy_select_3_unfocus():
	ui._unfocus_enemy(-3);

func _on_enemy_select_1_pressed():
	_on_enemy_select_1_unfocus()
	_on_select_enemy_pressed(selected_character)

func _on_enemy_select_2_pressed():
	_on_enemy_select_2_unfocus()
	_on_select_enemy_pressed(selected_character)

func _on_enemy_select_3_pressed():
	_on_enemy_select_3_unfocus()
	_on_select_enemy_pressed(selected_character)

func _setup_enemy_select_1_signals():
	enemy_select_1.focus_entered.connect(_on_enemy_select_1_focus)
	enemy_select_1.focus_exited.connect(_on_enemy_select_1_unfocus)
	enemy_select_1.mouse_entered.connect(_on_enemy_select_1_focus)
	enemy_select_1.pressed.connect(_on_enemy_select_1_pressed)

func _setup_enemy_select_2_signals():
	enemy_select_2.focus_entered.connect(_on_enemy_select_2_focus)
	enemy_select_2.focus_exited.connect(_on_enemy_select_2_unfocus)
	enemy_select_2.mouse_entered.connect(_on_enemy_select_2_focus)
	enemy_select_2.pressed.connect(_on_enemy_select_2_pressed)

func _setup_enemy_select_3_signals():
	enemy_select_3.focus_entered.connect(_on_enemy_select_3_focus)
	enemy_select_3.focus_exited.connect(_on_enemy_select_3_unfocus)
	enemy_select_3.mouse_entered.connect(_on_enemy_select_3_focus)
	enemy_select_3.pressed.connect(_on_enemy_select_3_pressed)
	
	

# ==============================================
# PUBLIC API
# ==============================================
func restart_battle():
	get_tree().reload_current_scene()

func get_all_battlers() -> Array:
	return turn_manager.get_all_battlers()

func get_current_battler() -> Character:
	return turn_manager.get_current_battler()

# ==============================================
# DEBUG
# ==============================================
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug"):
		Engine.time_scale = 0.0

# ==============================================
# SAVE/LOAD
# ==============================================
func on_save_game(saved_data: Array[SavedData]):
	var my_data = SavedBattleManagerData.new()
	my_data.scene_path = scene_file_path
	my_data.current_turn_index = turn_manager.get_current_turn_index()
	saved_data.append(my_data)

func on_before_load_game():
	get_parent().remove_child(self)
	queue_free()

func on_load_game(saved_data: SavedData):
	var my_data: SavedBattleManagerData = saved_data as SavedBattleManagerData
	turn_manager.set_current_turn_index(my_data.current_turn_index)

func on_after_load_game():
	var player_battlers: Array[Character] = []
	for player in get_tree().get_nodes_in_group("player_battlers"):
		player_battlers.append(player)
	var enemy_battlers: Array[Character] = []
	for enemy in get_tree().get_nodes_in_group("enemy_battlers"):
		enemy_battlers.append(enemy)
		
		ui._add_ui_to_enemy(enemy)
		if enemy.state.isDead:
			remove_ui_from_enemy.emit(enemy)
	
	
	entities_spawned.emit(player_battlers, enemy_battlers)
