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
signal skill_button_pressed()
signal skill_selected(skill: SkillResource)
signal skill_execute_requested(skill: SkillResource, user: Character, targets: Array[Character])
@warning_ignore("unused_signal")
signal toggle_focus_on_player(party_member: int)
signal request_ai_target()
signal ai_target_chosen(target: Character)
signal combat_attack_requested(attacker: Character, defender: Character)
signal combat_attack_completed()
signal next_turn_requested(skip_timer: bool)
signal show_battle_hud(show: bool)
signal show_select_buttons(show: bool, target: String)
signal show_skill_hud(show: bool)
signal remove_ui_from_enemy(entity: Character)
signal battle_ended(message: String)

# ==============================================
# CONFIGURAZIONE
# ==============================================
@onready var battle_hud: CanvasLayer = get_parent().get_node("Battle_HUD")
@onready var battleend_hud: CanvasLayer = get_parent().get_node("BattleEnd_HUD")
@onready var attack_button: Button = battle_hud.get_node("%Attack_Button")
@onready var skip_button: Button = battle_hud.get_node("%Skip_Button")
@onready var skill_button: Button = battle_hud.get_node("%Skill_Button")
@onready var commands_label: Label = battle_hud.get_node("%Commands_Label")
@onready var restart_button: Button = battleend_hud.get_node("%RestartBattleButton")
@onready var battleend_label: Label = battleend_hud.get_node("%EndBattleLabel")

@export_group("Battle Configuration")
@export var battle_data: BattleData

# ==============================================
# VARIABILI LOCALI
# ==============================================
var selected_character: Character
var selected_skill: SkillResource = null  # Skill temporaneamente selezionata
var skill_being_used: bool = false

# ==============================================
# COMPONENTI
# ==============================================
var spawner: BattleSpawner
var turn_manager: TurnManager
var ui: BattleUI
var ai: BattleAI
var combat: BattleCombat
var skill_executor: BattleSkillExecutor
var target_selection: BattleTargetSelection

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
	skill_executor = BattleSkillExecutor.new(self)
	target_selection = BattleTargetSelection.new(self)

func _connect_signals():
	# Segnali UI
	attack_button.pressed.connect(_on_attack_button_pressed)
	skip_button.pressed.connect(_on_skip_button_pressed)
	skill_button.pressed.connect(_on_skill_button_pressed)
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
	show_skill_hud.connect(_on_show_skill_hud)
	remove_ui_from_enemy.connect(_on_remove_ui_from_enemy)
	battle_ended.connect(_on_battle_ended)
	combat_attack_requested.connect(_on_combat_attack_requested)
	skill_selected.connect(_on_skill_selected)
	skill_execute_requested.connect(_on_skill_execute_requested)
	
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
	target_selection.setup_select_buttons(enemies)
	target_selection.setup_select_buttons(players)
	target_selection.show_select_button(false)
	
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
	skill_being_used = false
	
	var selecter_characters: Array[Character] = []
	selecter_characters.append(selected_char)
	# Se c'è una skill selezionata, usala
	if selected_skill:
		skill_execute_requested.emit(selected_skill, turn_manager.get_current_battler(), selecter_characters)
		selected_skill = null  # Reset
	else:
		# Attacco normale
		combat_attack_requested.emit(turn_manager.get_current_battler(), selected_char)

func _on_combat_attack_requested(attacker: Character, defender: Character):
	await combat.execute_attack(attacker, defender)
	combat_attack_completed.emit()

func _on_combat_attack_completed():
	next_turn_requested.emit(false)

func _on_attack_button_pressed():
	show_select_buttons.emit(true, "ENEMY")
	show_battle_hud.emit(false)
	show_skill_hud.emit(false)
	skill_being_used = false

func _on_skip_button_pressed():
	show_skill_hud.emit(false)
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

func _on_show_select_buttons(show: bool, target: String = "ALL"):
	target_selection.show_select_button(show, target)

func _on_show_skill_hud(show: bool):
	ui.show_skill_hud(show)

func _on_remove_ui_from_enemy(entity: Character):
	ui._remove_ui_from_enemy(entity)

func _on_battle_ended(message: String):
	ui._show_battle_end_hud(message)

func _on_skill_button_pressed():
	# Mostra menu skill
	var current = turn_manager.get_current_battler()
	if current:
		ui.show_skill_menu(current)

func _on_skill_selected(skill: SkillResource):
	var user = turn_manager.get_current_battler()
	if not user:
		return
	
	# Determina tipo di target
	match skill.target_type:
		SkillResource.TargetType.SELF:
			# Usa immediatamente su se stesso
			skill_execute_requested.emit(skill, user, [user])
		
		SkillResource.TargetType.SINGLE_ENEMY:
			# Mostra selezione nemico
			show_battle_hud.emit(false)
			show_select_buttons.emit(true, "ENEMY")
			skill_being_used = true
			# Salva skill selezionata temporaneamente
			selected_skill = skill
		
		SkillResource.TargetType.ALL_ENEMIES:
			# Target tutti i nemici vivi
			var targets = turn_manager.enemy_battlers.filter(
				func(e): return is_instance_valid(e) and not e.state.isDead
			)
			skill_execute_requested.emit(skill, user, targets)
		
		SkillResource.TargetType.SINGLE_ALLY:
			# Mostra selezione nemico
			show_battle_hud.emit(false)
			if skill.skill_type == SkillResource.SkillType.REVIVE:
				show_select_buttons.emit(true, "DEAD_ALLY")
			else:
				show_select_buttons.emit(true, "ALLY")
			skill_being_used = true
			# Salva skill selezionata temporaneamente
			selected_skill = skill
			pass
		
		SkillResource.TargetType.ALL_ALLIES:
			# Target tutti gli alleati vivi
			var targets = turn_manager.player_battlers.filter(
				func(p): return is_instance_valid(p) and not p.state.isDead
			)
			skill_execute_requested.emit(skill, user, targets)

func _on_skill_execute_requested(skill: SkillResource, user: Character, targets: Array[Character]):
	await skill_executor.execute_skill(skill, user, targets)
	combat_attack_completed.emit()



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
		#print(target_selection.dead_enemy_select_buttons)
		#print(target_selection.dead_player_select_buttons)
		#print(target_selection.enemy_select_buttons)
		##print(target_selection.player_select_buttons)
		#print(turn_manager.player_battlers)
		#print(turn_manager.enemy_battlers)
		#print(turn_manager.dead_player_battlers)
		#print(turn_manager.dead_enemy_battlers)
		
		for battler in turn_manager.battlers:
			print(battler.name, " ", battler.stats.current_hp, " ", battler.state.isDead)
		print("==================================")
		for battler in turn_manager.enemy_battlers:
			print(battler.name, " ", battler.stats.current_hp, " ", battler.state.isDead)
		print("==================================")

	if Input.is_action_just_pressed("cancel"):
		show_battle_hud.emit(true)
		show_select_buttons.emit(false)
		if skill_being_used:
			show_skill_hud.emit(true)
		else:
			show_skill_hud.emit(false)

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
