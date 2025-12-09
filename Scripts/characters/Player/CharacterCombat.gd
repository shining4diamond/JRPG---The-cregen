class_name CharacterCombat
extends Node

var animation_tree: AnimationTree
var state: CharacterState
var animation: CharacterAnimation
var attack_timer: Timer

func _init(p_anim_tree: AnimationTree, p_state: CharacterState, p_timer: Timer, p_animation: CharacterAnimation):
	animation_tree = p_anim_tree
	state = p_state
	attack_timer = p_timer
	animation = p_animation
	attack_timer.timeout.connect(_on_attack_timeout)

func handle_attack_simple():
	
	# Reset conditions all'inizio
	reset_attack_conditions()
	
	# Early return se non devo attaccare
	if not can_attack():
		return
	
	# Reset flags
	state.reset_attack_flags()
	state.isCrouching = false
	
	if Input.is_action_just_pressed("takeDamage"):
		execute_take_damage()
	elif Input.is_action_just_pressed("Die"):
		execute_death()
	elif Input.is_action_just_pressed("attack"):
		execute_attack()

func can_attack() -> bool:
	var has_input = Input.is_action_just_pressed("attack") or \
					Input.is_action_just_pressed("takeDamage") or \
					Input.is_action_just_pressed("Die")
	return has_input and not state.isAttacking and not state.isBeingAttacked

func execute_attack():
	if Input.is_action_pressed("run"):
		set_condition("meleeRun", true)
		state.isAttackingMeleeRun = true
	else:
		set_condition("melee", true)
		if state.melee_combo:
			state.isAttackingMelee = true
			state.melee_combo = false
		else:
			set_condition("melee2", true)
			state.isAttackingMelee2 = true
			state.melee_combo = true
	
	start_attack()

func execute_take_damage():
	set_condition("takeDamage", true)
	state.isBeingAttacked = true
	start_attack()

func execute_death():
	set_condition("die", true)
	state.isDead = true

func start_attack():
	state.isAttacking = true
	attack_timer.start()

func reset_attack_conditions():
	var conditions = ["melee", "melee2", "meleeRun", "takeDamage"]
	for cond in conditions:
		set_condition(cond, false)
		
func set_condition(condition: String, value: bool):
	animation_tree["parameters/conditions/" + condition] = value

func get_condition(condition: String) -> bool:
	return animation_tree["parameters/conditions/" + condition]

func _on_attack_timeout():
	state.isAttacking = false
	state.reset_attack_flags()
