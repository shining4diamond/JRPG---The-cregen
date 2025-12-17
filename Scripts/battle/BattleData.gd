class_name BattleData
extends Resource

@export var entities_config: Dictionary = {}
const character_15fps = "res://Scenes/characters/character_15fps.tscn"
const character_14fps = "res://Scenes/characters/character_14fps.tscn"

const skills_paths = [
	"res://Scripts/characters/Skills/power_strike.tres",
	"res://Scripts/characters/Skills/group_heal.tres",
	"res://Scripts/characters/Skills/heal.tres",
	"res://Scripts/characters/Skills/fireball.tres",
	"res://Scripts/characters/Skills/sacrifice.tres",
	"res://Scripts/characters/Skills/whirlwind.tres"
]

static func create_default() -> BattleData:
	var data = BattleData.new()
	data.entities_config = {
		"1":{
			"scenePath":character_15fps,
			"textureBasePath":"res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/",
			"statsPath":"res://Scripts/characters/Stats/Player_Characters/knight_stats.tres",
			"skillsPath": skills_paths,
			"type":"PLAYER"
		},
		"2":{
			"scenePath":character_14fps,
			"textureBasePath":"res://Assets/characters/FREE Character HD Survivor W Bike/",
			"statsPath":"res://Scripts/characters/Stats/Enemy_Characters/Early_Game/goblin_stats.tres",
			"skillsPath": skills_paths,
			"type":"ENEMY"
		},
		"3":{
			"scenePath":character_15fps,
			"textureBasePath":"res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/",
			"statsPath":"res://Scripts/characters/Stats/Player_Characters/rogue_stats.tres",
			"skillsPath": skills_paths,
			"type":"PLAYER"
		},
		"4":{
			"scenePath":character_14fps,
			"textureBasePath":"res://Assets/characters/FREE Character HD Survivor W Bike/",
			"statsPath":"res://Scripts/characters/Stats/Enemy_Characters/Dps/wolf_stats.tres",
			"skillsPath": skills_paths,
			"type":"ENEMY"
		},
		"5":{
			"scenePath":character_15fps,
			"textureBasePath":"res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/",
			"statsPath":"res://Scripts/characters/Stats/Player_Characters/ranger_stats.tres",
			"skillsPath": skills_paths,
			"type":"PLAYER"
		},
		"6":{
			"scenePath":character_14fps,
			"textureBasePath":"res://Assets/characters/FREE Character HD Survivor W Bike/",
			"statsPath":"res://Scripts/characters/Stats/Enemy_Characters/Tank/skeleton_stats.tres",
			"skillsPath": skills_paths,
			"type":"ENEMY"
		},
		"7":{
			"scenePath":character_14fps,
			"textureBasePath":"res://Assets/characters/FREE Character HD Survivor W Bike/",
			"statsPath":"res://Scripts/characters/Stats/Enemy_Characters/Tank/skeleton_stats.tres",
			"skillsPath": skills_paths,
			"type":"ENEMY"
		},
		"8":{
			"scenePath":character_14fps,
			"textureBasePath":"res://Assets/characters/FREE Character HD Survivor W Bike/",
			"statsPath":"res://Scripts/characters/Stats/Enemy_Characters/Tank/skeleton_stats.tres",
			"skillsPath": skills_paths,
			"type":"ENEMY"
		},
		"9":{
			"scenePath":character_15fps,
			"textureBasePath":"res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/",
			"statsPath":"res://Scripts/characters/Stats/Player_Characters/ranger_stats.tres",
			"skillsPath": skills_paths,
			"type":"PLAYER"
		},
		"10":{
			"scenePath":character_15fps,
			"textureBasePath":"res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/",
			"statsPath":"res://Scripts/characters/Stats/Player_Characters/ranger_stats.tres",
			"skillsPath": skills_paths,
			"type":"PLAYER"
		}
	}
	return data
