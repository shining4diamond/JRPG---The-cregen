class_name BattleData
extends Resource

@export var entities_config: Dictionary = {}
const character_15fps = "res://Scenes/characters/character_15fps.tscn"
const character_14fps = "res://Scenes/characters/character_14fps.tscn"

const skills_paths = [
	"res://Scripts/characters/Skills/Offensive/power_strike.tres",
	"res://Scripts/characters/Skills/Offensive/fireball.tres",
	"res://Scripts/characters/Skills/Offensive/sacrifice.tres",
	"res://Scripts/characters/Skills/Offensive/whirlwind.tres",
	"res://Scripts/characters/Skills/Offensive/blizzard.tres",
	"res://Scripts/characters/Skills/Healing/group_heal.tres",
	"res://Scripts/characters/Skills/Healing/heal.tres",
	"res://Scripts/characters/Skills/Healing/revive.tres",
	"res://Scripts/characters/Skills/Healing/regenerate.tres",
	"res://Scripts/characters/Skills/Healing/mass_regenerate.tres",
	"res://Scripts/characters/Skills/Buff/battle_cry.tres",
	"res://Scripts/characters/Skills/Buff/berserk_rage.tres",
	"res://Scripts/characters/Skills/Buff/war_banner.tres",
	"res://Scripts/characters/Skills/Debuff/armor_break.tres",
	"res://Scripts/characters/Skills/Debuff/weakness_curse.tres"
]

const demon_knight = {
	"scenePath":character_14fps,
	"textureBasePath":"res://Assets/characters/FREE Character HD Survivor W Bike/",
	"statsPath":"res://Scripts/characters/Stats/Enemy_Characters/Bosses/demon_knight_stats.tres",
	"skillsPath": skills_paths,
	"type":"ENEMY"
}

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
		"2":demon_knight,
		"3":{
			"scenePath":character_15fps,
			"textureBasePath":"res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/",
			"statsPath":"res://Scripts/characters/Stats/Player_Characters/rogue_stats.tres",
			"skillsPath": skills_paths,
			"type":"PLAYER"
		},
		"4":demon_knight,
		"5":{
			"scenePath":character_15fps,
			"textureBasePath":"res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/",
			"statsPath":"res://Scripts/characters/Stats/Player_Characters/ranger_stats.tres",
			"skillsPath": skills_paths,
			"type":"PLAYER"
		},
		"6":demon_knight,
		"7":demon_knight,
		"8":demon_knight,
		"9":{
			"scenePath":character_15fps,
			"textureBasePath":"res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/",
			"statsPath":"res://Scripts/characters/Stats/Player_Characters/cleric_stats.tres",
			"skillsPath": skills_paths,
			"type":"PLAYER"
		},
		"10":{
			"scenePath":character_15fps,
			"textureBasePath":"res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/",
			"statsPath":"res://Scripts/characters/Stats/Player_Characters/mage_stats.tres",
			"skillsPath": skills_paths,
			"type":"PLAYER"
		}
	}
	return data
