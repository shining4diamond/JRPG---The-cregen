class_name CharacterMovement
extends Node

const SPEED = 150
const SPEED_RUNNING = 300
const SPEED_CROUCHING = 100

var Character: CharacterBody2D
var state: CharacterState

func _init(p_Character: CharacterBody2D, p_state: CharacterState):
	Character = p_Character
	state = p_state

func handle_input():
	if state.isAttacking or state.isDead:
		return
	
	state.input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

func handle_crouch_toggle():
	if Input.is_action_just_pressed("crouch") and \
		not state.isAttacking and \
		not state.isRunning and \
		not state.isBeingAttacked:
		state.isCrouching = not state.isCrouching

func calculate_velocity() -> Vector2:
	if state.isDead or (state.isAttacking and not state.isRunning):
		return Vector2.ZERO
	
	var speed = get_current_speed()
	return state.input_direction * speed

func get_current_speed() -> float:
	if state.isRunning and not state.isCrouching:
		return SPEED_RUNNING
	elif state.isCrouching:
		return SPEED_CROUCHING
	return SPEED

func process_physics(_delta: float):
	Character.velocity = calculate_velocity()
	Character.move_and_slide()
