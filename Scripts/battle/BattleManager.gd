class_name BattleManager
extends Node

# ==============================================
# SEGNALI CENTRALIZZATI
# ==============================================
signal entities_spawned(players: Array, enemies: Array)
signal select_enemy_pressed(selected_character: Character)
@warning_ignore("unused_signal")
signal attack_button_pressed()
@warning_ignore("unused_signal")
signal skip_button_pressed()
@warning_ignore("unused_signal")
signal restart_button_pressed()
@warning_ignore("unused_signal")
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
@onready var restart_button: Button = battleend_hud.get_node("%RestartBattleButton")
@onready var battleend_label: Label = battleend_hud.get_node("%EndBattleLabel")

@export_group("Battle Configuration")
@export var battle_data: BattleData

# ==============================================
# VARIABILI LOCALI
# ==============================================
var selected_character: Character
# Dictionary per mappare party_member -> Button
var enemy_select_buttons: Dictionary = {}

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
		print("BattleManager: No BattleData provided, using default")
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
		battle_hud._update_hp_ui(enemy)
	
	# Start first turn
	turn_manager.start_first_turn()

func _on_select_enemy_pressed(selected_char: Character):
	show_battle_hud.emit(false)
	combat_attack_requested.emit(turn_manager.get_current_battler(), selected_char)

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

# ==============================================
# DYNAMIC ENEMY SELECTION HANDLERS
# ==============================================
func setup_enemy_select_button(party_member: int, button: Button):
	"""Configura dinamicamente un bottone di selezione nemico"""
	# Salva riferimento
	enemy_select_buttons[party_member] = button
	
	# Connetti segnali con closures
	button.focus_entered.connect(func(): _on_enemy_focus(party_member))
	button.focus_exited.connect(func(): _on_enemy_unfocus(party_member))
	button.mouse_entered.connect(func(): _on_enemy_focus(party_member))
	button.pressed.connect(func(): _on_enemy_pressed(party_member))
	
	# Setup focus navigation
	_setup_focus_navigation(button)

func _setup_focus_navigation(button: Button):
	"""Configura la navigazione tra i bottoni"""
	# Left neighbor: sempre il bottone Attack
	button.focus_neighbor_left = attack_button.get_path()
	
	# Right neighbor: sempre Attack (in base al layout della UI)
	attack_button.focus_neighbor_right = button.get_path()
	
	# Vertical navigation tra nemici
	var enemy_indices = enemy_select_buttons.keys()
	enemy_indices.sort()
	
	if enemy_indices.size() > 1:
		var prev_button = enemy_select_buttons[enemy_indices[1]]
		prev_button.focus_neighbor_bottom = button.get_path()
		button.focus_neighbor_top = prev_button.get_path()

func _on_enemy_focus(party_member: int):
	"""Handler per quando un bottone nemico riceve il focus"""
	var character = ui._return_enemy_on_party_member(party_member)
	if character:
		selected_character = character
		character.battleAction._on_select_button_mouse_entered()
		
		# Assicura che il bottone abbia il focus
		if enemy_select_buttons.has(party_member):
			enemy_select_buttons[party_member].grab_focus()

func _on_enemy_unfocus(party_member: int):
	"""Handler per quando un bottone nemico perde il focus"""
	var character = ui._return_enemy_on_party_member(party_member)
	if character:
		character.battleAction._on_select_button_mouse_exited()

func _on_enemy_pressed(party_member: int):
	"""Handler per quando un bottone nemico viene premuto"""
	_on_enemy_unfocus(party_member)
	if selected_character:
		_on_select_enemy_pressed(selected_character)

func get_enemy_select_button(party_member: int) -> Button:
	"""Ottiene il bottone di selezione per un party_member specifico"""
	return enemy_select_buttons.get(party_member, null)

func remove_enemy_select_button(party_member: int):
	"""Rimuove un bottone dalla lista (quando il nemico muore)"""
	if enemy_select_buttons.has(party_member):
		enemy_select_buttons.erase(party_member)
		# Aggiorna la navigazione focus per i bottoni rimanenti
		_update_all_focus_navigation()

func _update_all_focus_navigation():
	"""Aggiorna la navigazione focus per tutti i bottoni rimasti"""
	for party_member in enemy_select_buttons.keys():
		var button = enemy_select_buttons[party_member]
		_setup_focus_navigation(button)

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
		for player in get_parent().get_tree().get_nodes_in_group("player_battlers"):
			print(player.position.x)

# ==============================================
# SAVE/LOAD
# ==============================================
func on_save_game(saved_data: Array[SavedData]):
	var my_data = SavedBattleManagerData.new()
	my_data.scene_path = scene_file_path
	my_data.current_turn_index = turn_manager.get_current_turn_index()
	saved_data.append(my_data)

func on_before_load_game():
	for hpmp_tab in battle_hud.get_node_or_null("%HPMP_Tab_Grid_Container").get_children():
		hpmp_tab.get_parent().remove_child(hpmp_tab)
		hpmp_tab.queue_free()
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
	battle_hud._reset_turn_order_bar(turn_manager.battlers)
