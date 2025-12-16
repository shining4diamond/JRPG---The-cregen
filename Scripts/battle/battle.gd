extends Node2D

@onready var battle_manager: BattleManager = $BattleManager

func _ready():
	# Connetti ai segnali del BattleManager
	if battle_manager.spawner.has_signal("spawn_entity"):
		battle_manager.spawner.spawn_entity.connect(_spawn_entity)
		print("✅ spawn_entity Connesso")
	else:
		print("❌ spawn_entity Segnale mancante su: ", battle_manager)

func _spawn_entity(entity: Character, type: String):
	if type == "PLAYER":
		_spawn_player(entity)
	else:
		_spawn_enemy(entity)


func _spawn_player(entity: Character):
	battle_manager = get_node_or_null("BattleManager")
	
	var vbox = battle_manager.get_node_or_null("%Player_VBoxContainer")
	var hbox = battle_manager.get_node_or_null("%Player_HBoxContainer")
	
	if vbox and hbox:
		var new_hbox = hbox.duplicate()
		vbox.add_child(new_hbox)
		new_hbox.add_child(entity)
		entity.add_to_group("player_battlers")
		
func _spawn_enemy(entity: Character):
	battle_manager = get_node_or_null("BattleManager")
	
	var vbox = battle_manager.get_node_or_null("%Enemy_VBoxContainer")
	var hbox = battle_manager.get_node_or_null("%Enemy_HBoxContainer")
	
	if vbox and hbox:
		var new_hbox = hbox.duplicate()
		vbox.add_child(new_hbox)
		new_hbox.add_child(entity)
		entity.add_to_group("enemy_battlers")
