extends Node2D

@onready var character: Character = $Character
@onready var player_hpmp: Label = $Character/PlayerHPMP
@onready var battle_hud: CanvasLayer = $Battle_HUD
@onready var battleend_hud: CanvasLayer = $BattleEnd_HUD

@onready var attack_button: Button = $Battle_HUD.get_node("%Attack_Button")
@onready var skip_button: Button = $Battle_HUD.get_node("%Skip_Button")
@onready var battleend_label: Label = $BattleEnd_HUD.get_node("Panel/VBoxContainer/EndBattleLabel")

# Componenti
var spawner: BattleSpawner
var turn_manager: TurnManager
var ui: BattleUI
var ai: BattleAI
var combat: BattleCombat

# Data
var battle_data: BattleData

# Signals
signal toggle_focus_on_player(party_member: int)

# Engine
const time_scale: float = 1.0



func _ready() -> void:
	# Inizializza componenti
	spawner = BattleSpawner.new(self)
	ui = BattleUI.new(self)
	ai = BattleAI.new(self)
	combat = BattleCombat.new(self)
	turn_manager = TurnManager.new(self,ui,ai,combat)

	
	# Connetti segnali
	_connect_signals()
	
	# Setup battle
	battle_data = BattleData.create_default()
	spawner.spawn_entities(battle_data.entities_config)
	attack_button.pressed.connect(_on_attack_button_pressed)
	skip_button.pressed.connect(_on_skip_button_pressed)
	



func _connect_signals():
	spawner.all_entities_spawned.connect(_on_entities_spawned)

func _on_entities_spawned(players: Array, enemies: Array):
	turn_manager.player_battlers = players
	turn_manager.enemy_battler = enemies
	turn_manager.battlers = turn_manager.player_battlers + turn_manager.enemy_battler
	
	# Setup componenti
	ui.setup_enemy_buttons(turn_manager.enemy_battler)
	turn_manager.sort_battlers_by_speed()
	turn_manager.current_battler = turn_manager.battlers[0]
	
	attack_button.pressed.connect(_on_attack_button_pressed)
	Engine.time_scale = time_scale
	
		# Connetti i segnali subito dopo lo spawn
	$Battle_HUD.connect_signals()
	for player in players:
		$Battle_HUD.initialize_player_ui(player.stats, player.stats.party_member)
	emit_signal("toggle_focus_on_player", turn_manager.current_battler.stats.party_member)



func _on_select_enemy_button_pressed(selected_character: Character):
	ui.show_battle_hud(false)
	await combat.attack(turn_manager.current_battler, selected_character)
	turn_manager._next_turn()

func _on_attack_button_pressed():
	ui.show_select_button(true)
	
func _on_skip_button_pressed():
	turn_manager._next_turn(true)
	



func _on_button_pressed() -> void:
	get_tree().reload_current_scene()





func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug"):
			#print(turn_manager.battlers)
			#print(self.get_node("Battle_HUD").get_node("%Player_Character_1").get_node("HPMP_Player").get_node("%HP_ProgressBar").max_value)
			#print(self.get_node("Battle_HUD").get_node("%Player_Character_1").get_node("HPMP_Player").get_node("%HP_ProgressBar").get_node("%Current_HP_Label").text)
			#print(self.get_node("Battle_HUD").get_node("%Player_Character_1").get_node("HPMP_Player").get_node("%MP_ProgressBar").max_value)
			#print(self.get_node("Battle_HUD").get_node("%Player_Character_1").get_node("HPMP_Player").get_node("%MP_ProgressBar").get_node("%Current_MP_Label").text)
			#print(self.get_node("Battle_HUD").get_node("%Player_Character_2"))
			#print(self.get_node("Battle_HUD").get_node("%Player_Character_3"))
			#print(self.get_node("Player").stats.party_member) #		print(entity.stats.party_member))
			print($Battle_HUD.has_method("connect_signals"))
			$Battle_HUD.connect_signals()
