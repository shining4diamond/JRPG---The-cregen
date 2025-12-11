class_name BattleSpawner
extends Node

signal entity_spawned(entity: Character)
signal all_entities_spawned(players: Array, enemies: Array)

const ENEMY_HP_BAR_SCENE = "res://Scenes/ui/HP_ProgressBar_Enemy.tscn"

var parent_node: Node2D
var player_battlers: Array[Character] = []
var enemy_battlers: Array[Character] = []

func _init(p_parent: Node2D):
	parent_node = p_parent

func spawn_entities(entities_config: Dictionary):
	player_battlers.clear()
	enemy_battlers.clear()
	
	for key in entities_config:
		var config = entities_config[key]
		var entity = _spawn_single_entity(config)
		
		if entity:
			if config.type == "PLAYER":
				player_battlers.append(entity)
			else:
				enemy_battlers.append(entity)
			
			entity_spawned.emit(entity)
	
	all_entities_spawned.emit(player_battlers, enemy_battlers)

func _spawn_single_entity(config: Dictionary) -> Character:
	var scene = load(config.scenePath) as PackedScene
	if not scene:
		push_error("Impossibile caricare scena: " + config.scenePath)
		return null
	
	var entity = scene.instantiate() as Character
	
	# Setup entity
	entity.textureBasePath = config.textureBasePath
	parent_node.add_child(entity)
	entity.global_position = config.position
	entity.state.combatMode = true
	entity.stats = load(config.statsPath)
	
	# Set character type
	if config.type == "PLAYER":
		entity.stats.character_type = StatsResource.CharacterType.PLAYER
		entity.animation.set_blend_positions(Vector2(930, 288))
		entity.stats.party_member = player_battlers.size()+1		
		entity.name = "Player" + str(entity.stats.party_member)
	else:
		entity.stats.character_type = StatsResource.CharacterType.ENEMY
		entity.animation.set_blend_positions(Vector2(350, 288))
		entity.stats.party_member = (player_battlers.size()) * (-1)
		entity.name = "Enemy" + str(enemy_battlers.size()+1)
		# Add UI
		_add_ui_to_entity(entity)

	
	
	
	return entity

func _add_ui_to_entity(entity: Character):
	var ui_scene = load(ENEMY_HP_BAR_SCENE) as PackedScene
	var hp_bar = ui_scene.instantiate()
	entity.add_child(hp_bar)
	hp_bar.max_value = entity.stats.max_hp
	hp_bar.value = entity.stats.current_hp
