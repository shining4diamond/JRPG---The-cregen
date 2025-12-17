class_name Character
extends CharacterBody2D

@export var stats:StatsResource
@onready var animation_tree:AnimationTree = $AnimationTree
@onready var sprite_2d:Sprite2D = $Sprite2D
@onready var attacking_timer:Timer = $Attacking
@onready var select_button:Button = $Sprite2D/Select_Button

var input:Vector2
var textures = {}
var textureBasePath = "res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/"

# Componenti modulari
var state: CharacterState
var animation: CharacterAnimation
var movement: CharacterMovement
var combat: CharacterCombat
var battleAction: CharacterBattleAction
var battleMovement: CharacterBattleMovement
var skillSystem: CharacterSkillSystem

func _ready() -> void:
	# Inizializza stato
	state = CharacterState.new()
	# Inizializza componenti
	animation = CharacterAnimation.new(animation_tree, sprite_2d, state, textureBasePath)
	movement = CharacterMovement.new(self, state)
	combat = CharacterCombat.new(animation_tree, state, attacking_timer, animation)
	battleAction = CharacterBattleAction.new(animation_tree, state, attacking_timer, animation, self)
	battleMovement = CharacterBattleMovement.new(self, state)
	skillSystem = CharacterSkillSystem.new(self)

	animation_tree.active = true


func _process(_delta: float) -> void:
	if not state.isDead:
		animation.update_movement_animation()
		if not state.combatMode:
			combat.handle_attack_simple()
			movement.handle_crouch_toggle()
	else:
		animation.set_condition("idle", false)
		animation.set_condition("die", true)
	animation.update_sprite_texture()
	animation.update_blend_positions()
	battleAction._process(_delta)

	#if Input.is_action_just_pressed("debug"):
		#print(self)
		##print(state.combatMode)
		#print(stats)
		#print(stats.current_hp)


func _physics_process(_delta: float) -> void:
	# Gestione revive
	if state.isDead and Input.is_action_just_pressed("revive"):
		revive()
	
	if state.isDead or state.combatMode:
		battleMovement.process_physics(_delta)
		return
	movement.handle_input()
	movement.process_physics(_delta)
	battleMovement.process_physics(_delta)


func revive():
	state.isDead = false
	animation.set_condition("die", false)

func get_stats():
	return stats

# ==============================================
# Skill System
# ==============================================

func use_skill(skill: SkillResource, targets: Array[Character]) -> bool:
	return skillSystem.use_skill(skill, targets)

func get_usable_skills() -> Array[SkillResource]:
	return skillSystem.get_usable_skills()

func get_equipped_skills() -> Array[SkillResource]:
	return skillSystem.equipped_skills


# ==============================================
# SAVE/LOAD
# ==============================================
func on_save_game(saved_data:Array[SavedData]):
	var my_data = SavedCharacterData.new()
	my_data.stats = stats
	my_data.combatMode = state.combatMode
	my_data.isDead = state.isDead
	my_data.position = global_position
	my_data.scene_path = scene_file_path
	my_data.entity_name = self.name
	my_data.textureBasePath = textureBasePath
	
	my_data.character_name = stats.character_name
	my_data.max_hp = stats.max_hp
	my_data.current_hp = stats.current_hp
	my_data.max_mp = stats.max_mp
	my_data.current_mp = stats.current_mp
	my_data.attack = stats.attack
	my_data.defense = stats.defense
	my_data.m_attack = stats.m_attack
	my_data.m_defense = stats.m_defense
	my_data.turn_speed = stats.turn_speed
	my_data.equipped_skills = stats.equipped_skills
	my_data.skill_cooldowns = stats.skill_cooldowns

	saved_data.append(my_data)

func on_before_load_game():
	get_parent().remove_child(self)
	queue_free()

func on_load_game(saved_data:SavedData):
	var my_data:SavedCharacterData = saved_data as SavedCharacterData
	stats = my_data.stats
	state.combatMode = my_data.combatMode
	state.isDead = my_data.isDead
	self.name = my_data.entity_name
	stats.character_name = my_data.character_name
	stats.max_hp = my_data.max_hp
	stats.current_hp = my_data.current_hp
	stats.max_mp = my_data.max_mp
	stats.current_mp = my_data.current_mp
	stats.attack = my_data.attack
	stats.defense = my_data.defense
	stats.m_attack = my_data.m_attack
	stats.m_defense = my_data.m_defense
	stats.turn_speed = my_data.turn_speed
	stats.equipped_skills = my_data.equipped_skills
	stats.skill_cooldowns = my_data.skill_cooldowns

	if not state.combatMode:
		global_position = my_data.position
	textureBasePath = my_data.textureBasePath
	animation.load_textures(textureBasePath)

	if stats.character_type == 0:
		self.add_to_group("player_battlers")
		animation.set_blend_positions(Vector2.RIGHT)
	else:
		self.add_to_group("enemy_battlers")
		animation.set_blend_positions(Vector2.LEFT)
