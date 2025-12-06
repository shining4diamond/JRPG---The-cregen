class_name Player
extends CharacterBody2D

@export var animation_tree: AnimationTree
@onready var attacking: Timer = $Attacking
var playback:AnimationNodeStateMachinePlayback
const SPEED = 130
var input:Vector2
var melee:bool = true
var _isAttacking:bool = false

enum Directions {UP, DOWN, LEFT, RIGHT}
var direction:Directions
var reverse:bool = true

func _ready() -> void:
	playback = animation_tree["parameters/playback"]
	animation_tree.active = true

func _process(delta: float) -> void:
	update_animation_parameters()


func _physics_process(delta: float) -> void:
	input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if _isAttacking:
		return
	
	velocity = input * SPEED
	move_and_slide()



func update_animation_parameters():
	if input == Vector2.ZERO or _isAttacking:
		animation_tree["parameters/conditions/idle"] = true
		animation_tree["parameters/conditions/walk"] = false
	else:
		animation_tree["parameters/conditions/idle"] = false
		animation_tree["parameters/conditions/walk"] = true
	
		#check_180turn()
		
	
	# Gestione attacco
	if(Input.is_action_just_pressed("attack") and melee and not _isAttacking):
		animation_tree["parameters/conditions/melee"] = true
		melee = false
		_isAttacking = true
		attacking.start()
	elif(Input.is_action_just_pressed("attack") and not melee and not _isAttacking):
		animation_tree["parameters/conditions/melee"] = true
		animation_tree["parameters/conditions/melee2"] = true
		melee = true
		_isAttacking = true
		attacking.start()
	else:
		animation_tree["parameters/conditions/melee"] = false
		animation_tree["parameters/conditions/melee2"] = false

	
	
	if input != Vector2.ZERO:
		animation_tree["parameters/Idle/blend_position"] = input
		animation_tree["parameters/Walk/blend_position"] = input
		animation_tree["parameters/Melee/blend_position"] = input
		animation_tree["parameters/Melee2/blend_position"] = input
		animation_tree["parameters/180turn/blend_position"] = input


func check_180turn():
	if Input.is_action_just_released("move_right"): direction = Directions.LEFT
	if Input.is_action_just_released("move_left"): direction = Directions.RIGHT
	if Input.is_action_just_released("move_up"): direction = Directions.DOWN
	if Input.is_action_just_released("move_down"): direction = Directions.UP
	
	
	if reverse:
		if Input.is_action_just_pressed("move_left") and direction == Directions.LEFT:
			animation_tree["parameters/conditions/180turn"] = true
			print(direction)
			_isAttacking = true
			attacking.start()
		elif Input.is_action_just_pressed("move_right") and direction == Directions.RIGHT:
			animation_tree["parameters/conditions/180turn"] = true
			print(direction)
			_isAttacking = true
			attacking.start()
		elif Input.is_action_just_pressed("move_up") and direction == Directions.UP:
			animation_tree["parameters/conditions/180turn"] = true
			print(direction)
			_isAttacking = true
			attacking.start()
		elif Input.is_action_just_pressed("move_down") and direction == Directions.DOWN:
			animation_tree["parameters/conditions/180turn"] = true
			print(direction)
			_isAttacking = true
			attacking.start()
		else:
			animation_tree["parameters/conditions/180turn"] = false



func _on_attacking_timeout() -> void:
	_isAttacking = false
