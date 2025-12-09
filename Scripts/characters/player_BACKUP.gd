class_name PlayerBACKUP
extends CharacterBody2D

@export var stats:StatsResource
@export var animation_tree:AnimationTree
@onready var sprite_2d:Sprite2D = $Sprite2D
@onready var attacking:Timer = $Attacking
var playback:AnimationNodeStateMachinePlayback
const SPEED = 150
const SPEED_RUNNING = 300
const SPEED_CROUCHING = 100


var input:Vector2
var melee:bool = true
var _isAttackingMelee:bool = false
var _isAttackingMelee2:bool = false
var _isAttackingMeleeRun:bool = false
var _isBeingAttacked:bool = false
var	_isAttacking:bool = false
var _isTurning:bool = false
var _isRunning:bool = false
var _isCrouching:bool = false
var _isDead:bool = false

var last_direction: Vector2 = Vector2.ZERO


var textures = {}


func _ready() -> void:
	playback = animation_tree["parameters/playback"]
	animation_tree.active = true


func _process(_delta: float) -> void:
	load_textures()
	update_animation_parameters()
	setSprite2DTexture()
	


func _physics_process(_delta: float) -> void:
	if _isDead:
		if Input.is_action_just_pressed("revive"):
			_isDead = false
			animation_tree["parameters/conditions/die"] = false
	
	
	if not _isTurning and not _isAttacking and not _isDead:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	velocity = calculate_velocity()
	move_and_slide()


func calculate_velocity() -> Vector2:
	if  _isDead or (_isAttacking and not _isRunning):
		return Vector2.ZERO
	
	var speed = get_current_speed()
	return input * speed

func get_current_speed() -> float:
	if _isRunning and not _isCrouching:
		return SPEED_RUNNING
	elif _isCrouching:
		return SPEED_CROUCHING
	return SPEED


func update_animation_parameters():
	if not _isDead:
		handle_movement_and_crouch()
		handle_attack_simple()
	set_blend_positions()



func handle_movement_and_crouch():
	# Toggle crouch
	if Input.is_action_just_pressed("crouch") and not _isAttacking and not _isRunning and not _isBeingAttacked:
		_isCrouching = not _isCrouching
	
	# Reset tutte le conditions
	reset_movement_conditions()
	
	# Determina lo stato
	var is_moving = input != Vector2.ZERO and not _isAttacking
	
	if not is_moving:
		# Fermo
		if _isCrouching:
			animation_tree["parameters/conditions/crouchIdle"] = true
		else:
			animation_tree["parameters/conditions/idle"] = true
	else:
		# In movimento
		if Input.is_action_pressed("run"):
			# Corsa (disabilita crouch)
			animation_tree["parameters/conditions/run"] = true
			_isRunning = true
			_isCrouching = false
		elif _isCrouching:
			# Movimento abbassato
			animation_tree["parameters/conditions/crouchRun"] = true
			_isRunning = false
		else:
			# Camminata normale
			animation_tree["parameters/conditions/walk"] = true
			_isRunning = false

func handle_attack_simple():
	# Reset conditions all'inizio
	reset_attack_conditions()
	
	# Early return se non devo attaccare
	if (not Input.is_action_just_pressed("attack") and not Input.is_action_just_pressed("takeDamage") and not Input.is_action_just_pressed("Die")) or _isAttacking or _isBeingAttacked:
		return
	
	# Reset flags
	_isAttackingMelee = false
	_isAttackingMelee2 = false
	_isAttackingMeleeRun = false
	_isBeingAttacked = false
	_isCrouching = false
	
	# Logica semplificata
	if Input.is_action_just_pressed("takeDamage"):
		animation_tree["parameters/conditions/takeDamage"] = true
		_isBeingAttacked = true
	elif Input.is_action_just_pressed("Die"):
		animation_tree["parameters/conditions/die"] = true
		reset_movement_conditions()
		_isDead = true
	elif Input.is_action_pressed("run"):
		animation_tree["parameters/conditions/meleeRun"] = true
		_isAttackingMeleeRun = true
	else:
		animation_tree["parameters/conditions/melee"] = true
		if melee:
			_isAttackingMelee = true
			melee = false
		else:
			animation_tree["parameters/conditions/melee2"] = true
			_isAttackingMelee2 = true
			melee = true
	
	_isAttacking = true
	attacking.start()


func reset_movement_conditions():
	var conditions = ["idle", "walk", "run", "crouchIdle", "crouchRun"]
	for cond in conditions:
		set_condition(cond, false)

func reset_attack_conditions():
	var conditions = ["melee", "melee2", "meleeRun", "takeDamage"]
	for cond in conditions:
		set_condition(cond, false)
		
func set_condition(condition: String, value: bool):
	animation_tree["parameters/conditions/" + condition] = value

func set_blend_positions():
	if input != Vector2.ZERO:
		var blend_trees = [
			"Idle", "Walk", "Run", "Melee", "Melee2", "MeleeRun", "CrouchIdle",
			"CrouchRun", "TakeDamage", "Die"
		]
		for tree in blend_trees:
			animation_tree["parameters/" + tree + "/blend_position"] = input

func load_textures():
	var base_path = "res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/"
	textures = {
		"idle": load(base_path + "Idle.png"),
		"walk": load(base_path + "Walk.png"),
		"run": load(base_path + "Run.png"),
		"melee": load(base_path + "Melee.png"),
		"melee2": load(base_path + "Melee2.png"),
		"meleerun": load(base_path + "MeleeRun.png"),
		"crouch_idle": load(base_path + "CrouchIdle.png"),
		"crouch_run": load(base_path + "CrouchRun.png"),
		"take_damage": load(base_path + "TakeDamage.png"),
		"die": load(base_path + "Die.png")
	}


func setSprite2DTexture():
	
	# Set default sprite
	sprite_2d.texture = textures["idle"]
	
	# Set sprite based on state
	if animation_tree["parameters/conditions/walk"] == true: sprite_2d.texture = textures["walk"]
	elif animation_tree["parameters/conditions/run"] == true: sprite_2d.texture = textures["run"]
	elif animation_tree["parameters/conditions/crouchIdle"] == true: sprite_2d.texture = textures["crouch_idle"]
	elif animation_tree["parameters/conditions/crouchRun"] == true: sprite_2d.texture = textures["crouch_run"]
	elif _isAttacking and _isAttackingMeleeRun: sprite_2d.texture = textures["meleerun"]
	elif _isAttacking and _isAttackingMelee: sprite_2d.texture = textures["melee"]
	elif _isAttacking and _isAttackingMelee2: sprite_2d.texture = textures["melee2"]
	elif _isAttacking and _isBeingAttacked: sprite_2d.texture = textures["take_damage"]
	elif _isDead: sprite_2d.texture = textures["die"]


func get_stats():
	return stats

func _on_attacking_timeout() -> void:
	_isAttacking = false
	_isAttackingMelee = false
	_isAttackingMelee2 = false
	_isAttackingMeleeRun = false
	_isBeingAttacked = false
