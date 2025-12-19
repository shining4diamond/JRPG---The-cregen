#=======================================================
#Rapporti Consigliati
#Turn Speed:
#
#Tank: 30-45
#Balanced: 45-60
#DPS: 60-80
#
#HP vs Defense:
#
#Alto HP + Bassa Defense = Glass cannon
#Medio HP + Alta Defense = Tank
#Alto HP + Alta Defense = Boss
#
#Attack vs MP:
#
#Alto Attack + Basso MP = Physical fighter
#Basso Attack + Alto MP = Caster
#Medio Attack + Medio MP = Hybrid
#
#Progressione di Difficoltà
#
#Easy: Nemici con stats 50-70% del party
#Normal: Nemici con stats 80-100% del party
#Hard: Nemici con stats 110-130% del party
#Boss: Stats 150-200% del party, ma 1 vs Many
#=======================================================


extends Resource
class_name StatsResource

enum CharacterType{
	PLAYER,
	ENEMY
}
@export var character_type:CharacterType

enum PartyMember{
	NONE,
	ONE,
	TWO,
	THREE
}
@export var party_member:PartyMember = PartyMember.NONE
@export var character_name:String

@export var max_hp:int
@export var current_hp:int

@export var max_mp:int
@export var current_mp:int

@export var attack:int
@export var defense:int

@export var m_attack:int
@export var m_defense:int

@export var turn_speed:int


@export var equipped_skills: Array[SkillResource] = []
@export var skill_cooldowns: Dictionary = {}
