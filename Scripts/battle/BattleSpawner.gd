class_name BattleSpawner
extends Node

signal spawn_entity(entity: Character)
signal entity_spawned(entity: Character)
signal all_entities_spawned(players: Array, enemies: Array)

var manager: BattleManager
var player_battlers: Array[Character] = []
var enemy_battlers: Array[Character] = []

func _init(p_manager: BattleManager):
	manager = p_manager

func spawn_entities(entities_config: Dictionary):
	if entities_config.size() == 0:
		print("No entities to spawn")
		return
	
	player_battlers.clear()
	enemy_battlers.clear()
	
	for key in entities_config:
		var config = entities_config[key]
		var entity = await _spawn_single_entity(config)
		
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
		push_error("Cannot load scene: " + config.scenePath)
		return null
	
	var entity = scene.instantiate() as Character
	
	await manager.get_parent().get_tree().create_timer(0.1).timeout
	spawn_entity.emit(entity)
	
	entity.global_position = config.position
	entity.state.combatMode = true
	entity.stats = load(config.statsPath)
	entity.textureBasePath = config.textureBasePath
	entity.animation.load_textures(config.textureBasePath)
	
	# Set character type
	if config.type == "PLAYER":
		entity.stats.character_type = StatsResource.CharacterType.PLAYER
		entity.animation.set_blend_positions(Vector2(930, 288))
		entity.stats.party_member = player_battlers.size() + 1
		entity.name = "Player" + str(entity.stats.party_member)
	else:
		entity.stats.character_type = StatsResource.CharacterType.ENEMY
		entity.animation.set_blend_positions(Vector2(350, 288))
		entity.stats.party_member = (player_battlers.size()) * (-1)
		entity.name = "Enemy" + str(enemy_battlers.size() + 1)
		
		# Add UI usando il manager
		if is_instance_valid(manager.ui):
			manager.ui._add_hp_bar_to_enemy(entity)
	
	return entity
