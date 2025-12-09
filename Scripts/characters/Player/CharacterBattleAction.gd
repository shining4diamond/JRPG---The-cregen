class_name CharacterBattleAction
extends Node

var animation_tree: AnimationTree
var state: CharacterState
var animation: CharacterAnimation
var attack_timer: Timer
var select_button: Button
var selected: Label
var character: Character

func _init(p_anim_tree: AnimationTree, \
p_state: CharacterState, \
p_timer: Timer, \
p_animation: CharacterAnimation, \
p_select_button: Button, \
p_selected: Label, \
p_character: Character):
	animation_tree = p_anim_tree
	state = p_state
	attack_timer = p_timer
	animation = p_animation
	select_button = p_select_button
	selected = p_selected
	character = p_character
	attack_timer.timeout.connect(_on_attack_timeout)
	select_button.mouse_entered.connect(_on_select_button_mouse_entered)
	select_button.mouse_exited.connect(_on_select_button_mouse_exited)


func execute_attack():

	set_condition("melee", true)
	state.isAttackingMelee = true
		
	start_attack()

func execute_take_damage(attacker: Character):
	set_condition("takeDamage", true)
	state.isBeingAttacked = true
	start_attack()
	
	var damage = attacker.stats.attack - character.stats.defense
	if damage > 0:
		character.stats.current_hp -= damage
	if character.stats.current_hp <= 0:
		character.stats.current_hp = 0
		execute_death()

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
	reset_attack_conditions()



func _on_select_button_mouse_entered() -> void:
	selected.show()


func _on_select_button_mouse_exited() -> void:
	selected.hide()
