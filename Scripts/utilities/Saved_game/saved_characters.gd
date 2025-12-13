class_name SavedCharacterData
extends SavedData

@export var stats:StatsResource
@export var entity_name:String
@export var textureBasePath:String


# Stati booleani
@export var combatMode: bool = false
@export var isDead: bool = false


# STATS
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
