# ==============================================
# BattleManager.gd
# ==============================================
class_name BattleManager
extends Node

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
# COMPONENTI
# ==============================================
var spawner: BattleSpawner
var turn_manager: TurnManager
var ui: BattleUI
var ai: BattleAI
var combat: BattleCombat


# ==============================================
# SEGNALI
# ==============================================
signal toggle_focus_on_player(party_member: int)

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
	"""Verifica che tutte le referenze necessarie siano presenti"""
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
	"""Inizializza tutti i componenti del sistema di battaglia"""
	spawner = BattleSpawner.new(self)
	ui = BattleUI.new(self)
	ai = BattleAI.new(self)
	combat = BattleCombat.new(self)
	turn_manager = TurnManager.new(self, ui, ai, combat)

func _connect_signals():
	"""Connette tutti i segnali necessari"""
	spawner.all_entities_spawned.connect(_on_entities_spawned)
	attack_button.pressed.connect(_on_attack_button_pressed)
	skip_button.pressed.connect(_on_skip_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)

func _start_battle():
	"""Inizia la battaglia"""
	Engine.time_scale = time_scale
	spawner.spawn_entities(battle_data.entities_config)



func _on_entities_spawned(players: Array, enemies: Array):
	turn_manager.player_battlers = players
	turn_manager.enemy_battlers = enemies
	turn_manager.battlers = turn_manager.player_battlers + turn_manager.enemy_battlers
	
	# Setup componenti
	ui.setup_enemy_buttons(turn_manager.enemy_battlers)
	turn_manager.sort_battlers_by_speed()


	
	# Connetti i segnali subito dopo lo spawn
	battle_hud.connect_player_signals()
	for player in players:
		battle_hud.initialize_player_ui(player.stats, player.stats.party_member)
	
	battle_hud.connect_enemy_signals()
	for enemy in enemies:
		battle_hud._update_hp_ui(enemy.stats.current_hp, enemy.stats.party_member)
		
	if turn_manager.battlers.size() > 0:
		turn_manager.current_battler = turn_manager.battlers[turn_manager.current_turn_index]
		turn_manager.current_battler.battleMovement.toggle_focus_movement()
		emit_signal("toggle_focus_on_player", turn_manager.current_battler.stats.party_member)



func _on_select_enemy_button_pressed(selected_character: Character):
	ui.show_battle_hud(false)
	await combat.attack(turn_manager.current_battler, selected_character)
	turn_manager._next_turn()

func _on_attack_button_pressed():
	ui.show_select_button(true)
	
func _on_skip_button_pressed():
	turn_manager._next_turn(true)
	ui._toggle_combat_options_buttons()
	await get_tree().create_timer(0.25).timeout
	ui._toggle_combat_options_buttons()




func _on_restart_button_pressed() -> void:
	restart_battle()

# ==============================================
# PUBLIC API - Metodi per controllare la battaglia dall'esterno
# ==============================================
func restart_battle():
	"""Riavvia la battaglia"""
	get_tree().reload_current_scene()

func get_all_battlers() -> Array:
	"""Ritorna tutti i combattenti"""
	return turn_manager.battlers if turn_manager else []

func get_current_battler() -> Character:
	"""Ritorna il combattente corrente"""
	return turn_manager.current_battler if turn_manager else null


# ==============================================
# DEBUG ACTION - 0
# ==============================================
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug"):
		#print(turn_manager.player_battlers)
		#print(turn_manager.enemy_battlers)
		#print(turn_manager.battlers)
		
		Engine.time_scale = 0.0

			#print(self.get_node("Battle_HUD").get_node("%Player_Character_1").get_node("HPMP_Player").get_node("%HP_ProgressBar").max_value)
			#print(self.get_node("Battle_HUD").get_node("%Player_Character_1").get_node("HPMP_Player").get_node("%HP_ProgressBar").get_node("%Current_HP_Label").text)
			#print(self.get_node("Battle_HUD").get_node("%Player_Character_1").get_node("HPMP_Player").get_node("%MP_ProgressBar").max_value)
			#print(self.get_node("Battle_HUD").get_node("%Player_Character_1").get_node("HPMP_Player").get_node("%MP_ProgressBar").get_node("%Current_MP_Label").text)
			#print(self.get_node("Battle_HUD").get_node("%Player_Character_2"))
			#print(self.get_node("Battle_HUD").get_node("%Player_Character_3"))
			#print(self.get_node("Player").stats.party_member) #		print(entity.stats.party_member))
		pass






func on_save_game(saved_data:Array[SavedData]):
	var my_data = SavedBattleManagerData.new()
	my_data.scene_path = scene_file_path
	my_data.current_turn_index = turn_manager.current_turn_index
	saved_data.append(my_data)

func on_before_load_game():
	get_parent().remove_child(self)
	queue_free()

func on_load_game(saved_data:SavedData):
	var my_data:SavedBattleManagerData = saved_data as SavedBattleManagerData
	turn_manager.current_turn_index = my_data.current_turn_index
	
func on_after_load_game():
	var player_battlers: Array[Character] = []
	for player in get_tree().get_nodes_in_group("player_battlers"):
		player_battlers.append(player)
	
	var enemy_battlers: Array[Character] = []
	for enemy in get_tree().get_nodes_in_group("enemy_battlers"):
		enemy_battlers.append(enemy)
		ui._add_hp_bar_to_enemy(enemy)
	
	turn_manager.player_battlers.clear()
	turn_manager.enemy_battlers.clear()
	_on_entities_spawned(player_battlers, enemy_battlers)
