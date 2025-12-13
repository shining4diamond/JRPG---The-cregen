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
