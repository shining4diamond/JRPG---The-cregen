class_name CharacterBattleMovement
extends Node

const SPEED = 300

var character: CharacterBody2D
var state: CharacterState
var focus_on: bool
var direction: Vector2

func _init(p_Character: CharacterBody2D, p_state: CharacterState):
	character = p_Character
	state = p_state


func toggle_focus_movement():
	focus_on = false if focus_on else true

	
func calculate_velocity() -> Vector2:
	if character.stats.character_type != 0:
		character.animation.set_blend_positions(Vector2.LEFT)
		return Vector2.ZERO
		
	if focus_on:
		direction = Vector2.RIGHT if character.position.x < 560.0 else Vector2.ZERO
		character.animation.set_condition("run",true)
		state.isRunning = true
		state.input_direction = direction
	else:
		direction = Vector2.LEFT if character.position.x > 350.0 else Vector2.ZERO
		character.animation.set_condition("run",true)
		state.isRunning = true
		state.input_direction = direction
	
	if character.position.x <= 350.0:
		character.animation.set_blend_positions(Vector2.RIGHT)
	return direction * SPEED


func process_physics(_delta: float):
	if not state.combatMode:
		return
	character.velocity = calculate_velocity()
	character.move_and_slide()


#350 -> 560
#(560.0, 173.0)
#(560.0, 346.0)
#(560.0, 519.0)
