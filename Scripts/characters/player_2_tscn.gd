class_name Player
extends CharacterBody2D

@export var animation_tree: AnimationTree
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var attacking: Timer = $Attacking
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

# Preload all animation's textures
var walk_texture = preload("res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/Walk.png")
var idle_texture = preload("res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/Idle.png")
var run_texture = preload("res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/Run.png")
var meleerun_texture = preload("res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/MeleeRun.png")
var melee_texture = preload("res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/Melee.png")
var melee2_texture = preload("res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/Melee2.png")
var crouchidle_texture = preload("res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/CrouchIdle.png")
var crouchrun_texture = preload("res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/CrouchRun.png")
var takedamage_texture = preload("res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/TakeDamage.png")
var die_texture = preload("res://Assets/characters/2D HD Character Knight/Spritesheets/With shadows/Die.png")

func _ready() -> void:
	playback = animation_tree["parameters/playback"]
	animation_tree.active = true


func _process(_delta: float) -> void:
	#if _isDead:
		#return
	update_animation_parameters()
	#check_180turn()
	setSprite2DTexture()



func _physics_process(_delta: float) -> void:
	if _isDead:
		if Input.is_action_just_pressed("revive"):
			_isDead = false
			animation_tree["parameters/conditions/die"] = false
	
	
	if not _isTurning and not _isAttacking and not _isDead:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if (_isAttacking and not _isRunning) or _isDead:
		return
	
	if _isRunning and not _isCrouching:
		velocity = input * SPEED_RUNNING
	elif _isCrouching:
		velocity = input * SPEED_CROUCHING
	else:
		velocity = input * SPEED
	
	move_and_slide()


func update_animation_parameters():
	if not _isDead:
		handle_movement_and_crouch()
		handle_attack_simple()
	set_blend_positions()



func handle_movement_and_crouch():
	# Toggle crouch
	if Input.is_action_just_pressed("crouch"):
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
	animation_tree["parameters/conditions/melee"] = false
	animation_tree["parameters/conditions/melee2"] = false
	animation_tree["parameters/conditions/meleeRun"] = false
	animation_tree["parameters/conditions/takeDamage"] = false
	
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
	animation_tree["parameters/conditions/idle"] = false
	animation_tree["parameters/conditions/walk"] = false
	animation_tree["parameters/conditions/run"] = false
	animation_tree["parameters/conditions/crouchIdle"] = false
	animation_tree["parameters/conditions/crouchRun"] = false

func set_blend_positions():
	if input != Vector2.ZERO:
		animation_tree["parameters/Idle/blend_position"] = input
		animation_tree["parameters/Walk/blend_position"] = input
		animation_tree["parameters/Melee/blend_position"] = input
		animation_tree["parameters/Melee2/blend_position"] = input
		#animation_tree["parameters/180turn/blend_position"] = input
		animation_tree["parameters/Run/blend_position"] = input
		animation_tree["parameters/MeleeRun/blend_position"] = input
		animation_tree["parameters/CrouchIdle/blend_position"] = input
		animation_tree["parameters/CrouchRun/blend_position"] = input
		animation_tree["parameters/TakeDamage/blend_position"] = input
		animation_tree["parameters/Die/blend_position"] = input

func setSprite2DTexture():
	
	# Set default sprite
	sprite_2d.texture = idle_texture	
	
	# Set sprite based on state
	if animation_tree["parameters/conditions/walk"] == true: sprite_2d.texture = walk_texture
	elif animation_tree["parameters/conditions/run"] == true: sprite_2d.texture = run_texture
	elif animation_tree["parameters/conditions/crouchIdle"] == true: sprite_2d.texture = crouchidle_texture
	elif animation_tree["parameters/conditions/crouchRun"] == true: sprite_2d.texture = crouchrun_texture
	elif _isAttacking and _isAttackingMeleeRun: sprite_2d.texture = meleerun_texture
	elif _isAttacking and _isAttackingMelee: sprite_2d.texture = melee_texture
	elif _isAttacking and _isAttackingMelee2: sprite_2d.texture = melee2_texture
	elif _isAttacking and _isBeingAttacked: sprite_2d.texture = takedamage_texture
	elif _isDead: sprite_2d.texture = die_texture



func _on_attacking_timeout() -> void:
	_isAttacking = false
	_isAttackingMelee = false
	_isAttackingMelee2 = false
	_isAttackingMeleeRun = false
	_isBeingAttacked = false

	#_isTurning = false
	#animation_tree["parameters/conditions/180turn"] = false










# To Uncomment -> Select everything and press CTRL + K
#func check_180turn():
	## Memorizza la direzione precedente solo se c'è movimento
	#if input != Vector2.ZERO and not _isAttacking and not _isTurning:
		## Controlla se c'è un cambio di direzione di 180 gradi
		#if last_direction != Vector2.ZERO:
			## Normalizza entrambi i vettori per confrontarli
			#var current_normalized = input.normalized()
			#var last_normalized = last_direction.normalized()
			#
			## Calcola il prodotto scalare (dot product)
			## Se è circa -1, significa che sono opposti (180 gradi)
			#var dot_product = current_normalized.dot(last_normalized)
			#
			#if dot_product < -0.9:  # Circa 180 gradi
				#animation_tree["parameters/conditions/180turn"] = true
				#_isTurning = true
				#attacking.start()
		#
		#last_direction = input
