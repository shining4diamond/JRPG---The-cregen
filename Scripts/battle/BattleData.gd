class_name BattleData
extends Resource

@export var entities_config: Dictionary = {}
const character_15fps = "res://Scenes/characters/character_15fps.tscn"
const character_14fps = "res://Scenes/characters/character_14fps.tscn"

static func create_default() -> BattleData:
	var data = BattleData.new()
	data.entities_config = {
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
	return data
