class_name Character
extends CharacterBody2D

@export var stats:StatsResource
@onready var animation_tree:AnimationTree = $AnimationTree
@onready var sprite_2d:Sprite2D = $Sprite2D
@onready var attacking_timer:Timer = $Attacking
@onready var select_button:Button = $Sprite2D/Select_Button
@onready var selected: Label = $Sprite2D/Selected

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

func _ready() -> void:
	# Inizializza stato
	state = CharacterState.new()
	# Inizializza componenti
	animation = CharacterAnimation.new(animation_tree, sprite_2d, state, textureBasePath)
	movement = CharacterMovement.new(self, state)
	combat = CharacterCombat.new(animation_tree, state, attacking_timer, animation)
	battleAction = CharacterBattleAction.new(animation_tree, state, attacking_timer, animation, select_button, selected, self)
	battleMovement = CharacterBattleMovement.new(self, state)

	animation_tree.active = true


func _process(_delta: float) -> void:
	if not state.isDead:
		animation.update_movement_animation()
		if not state.combatMode:
			combat.handle_attack_simple()
			movement.handle_crouch_toggle()
	else:
		animation.set_condition("idle", false)
	animation.update_sprite_texture()
	animation.update_blend_positions()

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
