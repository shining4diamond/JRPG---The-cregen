extends Node2D

@onready var battle_manager: BattleManager = $BattleManager

func _ready():
	# Connetti ai segnali del BattleManager
	if battle_manager.spawner.has_signal("spawn_entity"):
		battle_manager.spawner.spawn_entity.connect(_spawn_entity)
		print("✅ spawn_entity Connesso")
	else:
		print("❌ spawn_entity Segnale mancante su: ", battle_manager)

func _spawn_entity(entity: Character):
	self.add_child(entity)
